import 'dart:convert';

import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../ai/open_router_client.dart';
import '../ai/open_router_config.dart';
import '../widgets/stac_validator.dart';
import '../widgets/widget_catalog_endpoint.dart';
import 'a2ui_stream_normalizer.dart';
import 'gen_ui_dev_mock.dart';
import 'gen_ui_prompt_service.dart';

class GenUiStreamEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const defaultModel = 'deepseek/deepseek-v4-flash:free';

  Stream<String> chatStream(Session session, GenUiChatRequest request) async* {
    try {
      yield* _chatStreamImpl(session, request);
    } catch (error, stackTrace) {
      if (session.serverpod.runMode == ServerpodRunMode.development) {
        session.log(
          'chatStream failed ($error); streaming dev calculator mock.',
          level: LogLevel.warning,
        );
        session.log('$stackTrace', level: LogLevel.debug);
        yield* _streamDevMock();
        return;
      }
      if (error is GenUiStreamException) {
        rethrow;
      }
      session.log('chatStream failed: $error', level: LogLevel.error);
      throw GenUiStreamException(message: 'GenUI stream failed: $error');
    }
  }

  Stream<String> _chatStreamImpl(
    Session session,
    GenUiChatRequest request,
  ) async* {
    final authUserId = _requireAuthUserId(session);

    final catalogEndpoint = WidgetCatalogEndpoint();
    final widgets = await catalogEndpoint.listMyWidgets(session);
    final systemPrompt = GenUiPromptService.buildSystemPrompt(widgets);

    final apiKey = OpenRouterConfig.resolveApiKey(session);
    if (apiKey == null) {
      if (session.serverpod.runMode == ServerpodRunMode.development) {
        session.log(
          'OpenRouter API key missing; streaming dev calculator mock.',
          level: LogLevel.warning,
        );
        yield* _streamDevMock();
        return;
      }
      session.log(OpenRouterConfig.missingKeyMessage(), level: LogLevel.error);
      throw GenUiStreamException(message: OpenRouterConfig.missingKeyMessage());
    }

    final model = request.model ?? defaultModel;
    final buffer = StringBuffer();
    final normalizer = A2uiStreamNormalizer();

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...GenUiPromptService.fewShotMessages(),
      ...request.messages.map(
        (m) => {'role': m.role, 'content': m.content},
      ),
    ];

    final client = OpenRouterClient(
      apiKey: apiKey,
      siteUrl: 'https://liqd.dev',
      appName: 'Liqd',
    );

    try {
      await for (final chunk in client.streamChat(
        model: model,
        messages: messages,
      )) {
        buffer.write(chunk);
        for (final normalized in normalizer.process(chunk)) {
          yield normalized;
        }
      }
      for (final normalized in normalizer.flush()) {
        yield normalized;
      }

      await _processNewWidgetBlocks(session, authUserId, buffer.toString());
    } on OpenRouterException catch (error) {
      if (session.serverpod.runMode == ServerpodRunMode.development) {
        session.log(
          'OpenRouter failed (${error.statusCode}); streaming dev calculator mock.',
          level: LogLevel.warning,
        );
        yield* _streamDevMock();
        return;
      }
      session.log('OpenRouter error: $error', level: LogLevel.error);
      throw GenUiStreamException(
        message:
            'OpenRouter request failed (${error.statusCode}): '
            '${_truncate(error.body, 300)}',
      );
    } finally {
      client.close();
    }
  }

  Stream<String> _streamDevMock() async* {
    final normalizer = A2uiStreamNormalizer();
    await for (final chunk in GenUiDevMock.streamCalculator()) {
      for (final normalized in normalizer.process(chunk)) {
        yield normalized;
      }
    }
    for (final normalized in normalizer.flush()) {
      yield normalized;
    }
  }

  Future<UserWidget?> generateWidget(
    Session session, {
    required String name,
    required String description,
    Map<String, dynamic>? dataSchema,
    required Map<String, dynamic> stacJson,
  }) async {
    final catalogEndpoint = WidgetCatalogEndpoint();
    return catalogEndpoint.createWidget(
      session,
      name: name,
      description: description,
      dataSchema: dataSchema,
      stacJson: stacJson,
    );
  }

  Future<void> _processNewWidgetBlocks(
    Session session,
    UuidValue authUserId,
    String fullResponse,
  ) async {
    final pattern = RegExp(
      r'```new-widget\s*\n([\s\S]*?)\n```',
      multiLine: true,
    );

    for (final match in pattern.allMatches(fullResponse)) {
      try {
        final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        final name = json['name'] as String?;
        final description = json['description'] as String?;
        final stacJson = json['stacJson'] as Map<String, dynamic>?;

        if (name == null || description == null || stacJson == null) {
          continue;
        }

        final validation = StacValidator.validate(stacJson);
        if (!validation.valid) {
          session.log(
            'Skipping invalid new-widget block: ${validation.errors}',
          );
          continue;
        }

        final existing = await UserWidget.db.findFirstRow(
          session,
          where: (t) => t.authUserId.equals(authUserId) & t.name.equals(name),
        );
        if (existing != null) {
          continue;
        }

        await UserWidget.db.insertRow(
          session,
          UserWidget(
            authUserId: authUserId,
            name: name,
            description: description,
            dataSchema: json['dataSchema'] as Map<String, dynamic>?,
            stacJson: stacJson,
          ),
        );
        session.log('Saved new widget "$name" for user $authUserId');
      } on FormatException catch (e) {
        session.log('Failed to parse new-widget block: $e');
      }
    }
  }

  UuidValue _requireAuthUserId(Session session) {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw GenUiStreamException(
        message: 'Authentication required. Sign in and try again.',
      );
    }
    return UuidValue.fromString(userIdentifier);
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }
}
