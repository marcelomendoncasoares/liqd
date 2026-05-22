import 'dart:convert';

import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../ai/open_router_client.dart';
import '../ai/open_router_config.dart';
import '../widgets/stac_validator.dart';
import '../widgets/widget_catalog_endpoint.dart';
import 'a2ui_stream_normalizer.dart';
import 'gen_ui_dev_logger.dart';
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
    final existingSurfaceIds = GenUiPromptService.parseExistingSurfaceIds(
      request.existingSurfacesJson,
    );
    final existingSurfaces = _parseExistingSurfaces(
      request.existingSurfacesJson,
    );
    final isEdit = existingSurfaceIds.isNotEmpty;
    final systemPrompt = GenUiPromptService.buildSystemPrompt(
      widgets,
      isEdit: isEdit,
    );

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

    // UI error feedback loops back from the client; don't burn OpenRouter quota.
    if (_isClientErrorFeedback(request)) {
      session.log(
        'Skipping OpenRouter for client error feedback message.',
        level: LogLevel.info,
      );
      if (session.serverpod.runMode == ServerpodRunMode.development) {
        yield* _streamDevMock();
      }
      return;
    }

    final model = request.model ?? defaultModel;
    final buffer = StringBuffer();
    final normalizer = A2uiStreamNormalizer(
      existingSurfaceIds: existingSurfaceIds,
      existingSurfaces: existingSurfaces,
      userWidgetNames: widgets.map((widget) => widget.name),
    );

    final existingSurfacesMessage =
        GenUiPromptService.buildExistingSurfacesMessage(
          request.existingSurfacesJson,
        );

    var messages = GenUiPromptService.buildChatMessages(
      request: request,
      isEdit: isEdit,
      existingSurfacesMessage: existingSurfacesMessage,
      systemPrompt: systemPrompt,
    );

    final client = OpenRouterClient(
      apiKey: apiKey,
      siteUrl: 'https://liqd.dev',
      appName: 'Liqd',
    );

    try {
      if (isEdit) {
        var fullResponse = await _collectOpenRouterResponse(
          client: client,
          model: model,
          messages: messages,
        );

        if (!GenUiPromptService.responseContainsA2ui(fullResponse)) {
          session.log(
            'Follow-up response lacked A2UI; retrying with correction prompt.',
            level: LogLevel.info,
          );
          messages = [
            ...messages,
            {'role': 'assistant', 'content': fullResponse},
            {
              'role': 'user',
              'content': GenUiPromptService.a2uiCorrectionMessage(),
            },
          ];
          fullResponse = await _collectOpenRouterResponse(
            client: client,
            model: model,
            messages: messages,
          );
        }

        buffer.write(fullResponse);
        for (final normalized in normalizer.process(fullResponse)) {
          yield normalized;
        }
        for (final normalized in normalizer.flush()) {
          yield normalized;
        }
      } else {
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
      }

      final fullResponse = buffer.toString();
      _logModelResponse(
        session,
        fullResponse: fullResponse,
        isEdit: isEdit,
        model: model,
      );
      await _processNewWidgetBlocks(session, authUserId, fullResponse);
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

  Future<String> _collectOpenRouterResponse({
    required OpenRouterClient client,
    required String model,
    required List<Map<String, dynamic>> messages,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in client.streamChat(
      model: model,
      messages: messages,
    )) {
      buffer.write(chunk);
    }
    return buffer.toString();
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

  void _logModelResponse(
    Session session, {
    required String fullResponse,
    required bool isEdit,
    required String model,
  }) {
    if (session.serverpod.runMode != ServerpodRunMode.development) {
      return;
    }

    final containsA2ui = GenUiPromptService.responseContainsA2ui(fullResponse);
    session.log(
      'GenUI model response model=$model isEdit=$isEdit '
      '(${fullResponse.length} chars, containsA2ui=$containsA2ui)',
      level: LogLevel.info,
    );
    GenUiDevLogger.logLongText(
      session,
      fullResponse,
      header: 'Model response body:',
    );

    if (!containsA2ui) {
      session.log(
        'Model response has no A2UI messages — preview will not change.',
        level: LogLevel.warning,
      );
    }
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }

  Map<String, Map<String, dynamic>> _parseExistingSurfaces(
    String? existingSurfacesJson,
  ) {
    if (existingSurfacesJson == null || existingSurfacesJson.trim().isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(existingSurfacesJson) as Map<String, dynamic>;
      final surfaces = decoded['surfaces'];
      if (surfaces is! Map) {
        return const {};
      }
      return surfaces.map(
        (key, value) => MapEntry(
          key.toString(),
          Map<String, dynamic>.from(value as Map),
        ),
      );
    } on FormatException {
      return const {};
    }
  }

  bool _isClientErrorFeedback(GenUiChatRequest request) {
    if (request.messages.isEmpty) {
      return false;
    }
    final last = request.messages.last;
    if (last.role != 'user') {
      return false;
    }
    final content = last.content.trim();
    if (!content.startsWith('{')) {
      return false;
    }
    try {
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return decoded.containsKey('error');
    } on FormatException {
      return false;
    }
  }
}
