import 'dart:convert';

import '../generated/protocol.dart';
import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:serverpod/serverpod.dart';

import '../ai/open_router_client.dart';
import '../ai/open_router_config.dart';
import '../widgets/stac_validator.dart';
import '../widgets/widget_catalog_endpoint.dart';
import 'gen_ui_dev_logger.dart';
import 'gen_ui_dev_mock.dart';

class GenUiStreamEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const defaultModel = 'deepseek/deepseek-v4-flash:free';
  static const _maxValidationRetries = 2;

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
    final manifest = _requireCatalogManifest(request);
    final existingSurfaceIds = GenUiChatAssembler.parseExistingSurfaceIds(
      request.existingSurfacesJson,
    );
    final isEdit = existingSurfaceIds.isNotEmpty;

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
    final existingSurfacesMessage =
        GenUiChatAssembler.buildExistingSurfacesMessage(
          request.existingSurfacesJson,
        );

    var messages = GenUiChatAssembler.buildChatMessages(
      manifest: manifest,
      isEdit: isEdit,
      existingSurfacesMessage: existingSurfacesMessage,
      userMessages: request.messages
          .map((message) => {'role': message.role, 'content': message.content})
          .toList(),
    );

    final client = OpenRouterClient(
      apiKey: apiKey,
      siteUrl: 'https://liqd.dev',
      appName: 'Liqd',
    );

    try {
      var attempt = 0;
      var validatedMessageCount = 0;
      final responseBuffer = StringBuffer();

      while (attempt <= _maxValidationRetries) {
        final extractor = A2uiExtractor();
        final validator = A2uiValidator(manifest)
          ..seedExistingSurfaces(existingSurfaceIds);
        final validationErrors = <String>[];
        validatedMessageCount = 0;
        responseBuffer.clear();

        await for (final chunk in client.streamChat(
          model: model,
          messages: messages,
        )) {
          responseBuffer.write(chunk);
          for (final rawJson in extractor.process(chunk)) {
            final result = await validateA2uiJson(validator, rawJson);
            if (result.skipped) {
              continue;
            }
            if (result.isValid && result.message != null) {
              validatedMessageCount++;
              yield '${NdjsonAdapter.toNdjsonLine(result.message!)}\n';
            } else {
              validationErrors.addAll(result.errors);
            }
          }
        }

        for (final rawJson in extractor.flush()) {
          final result = await validateA2uiJson(validator, rawJson);
          if (result.skipped) {
            continue;
          }
          if (result.isValid && result.message != null) {
            validatedMessageCount++;
            yield '${NdjsonAdapter.toNdjsonLine(result.message!)}\n';
          } else {
            validationErrors.addAll(result.errors);
          }
        }

        final fullResponse = responseBuffer.toString();
        final hasA2ui = GenUiChatAssembler.responseContainsA2ui(fullResponse);

        if (validatedMessageCount > 0) {
          _logModelResponse(
            session,
            fullResponse: fullResponse,
            isEdit: isEdit,
            model: model,
            validatedMessageCount: validatedMessageCount,
            validationErrors: validationErrors,
          );
          await _processNewWidgetBlocks(session, authUserId, fullResponse);
          return;
        }

        if (attempt == _maxValidationRetries) {
          _logModelResponse(
            session,
            fullResponse: fullResponse,
            isEdit: isEdit,
            model: model,
            validatedMessageCount: validatedMessageCount,
            validationErrors: validationErrors,
          );
          if (validatedMessageCount == 0 && !hasA2ui) {
            session.log(
              'Model response has no valid A2UI messages.',
              level: LogLevel.warning,
            );
          }
          return;
        }

        final retryPrompt = validationErrors.isNotEmpty
            ? GenUiChatAssembler.validationRetryMessage(validationErrors)
            : GenUiChatAssembler.a2uiCorrectionMessage();

        session.log(
          'GenUI validation failed (attempt ${attempt + 1}); retrying.',
          level: LogLevel.info,
        );

        messages = [
          ...messages,
          {'role': 'assistant', 'content': fullResponse},
          {'role': 'user', 'content': retryPrompt},
        ];
        attempt++;
      }
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
    await for (final line in GenUiDevMock.streamCalculatorNdjson()) {
      yield line;
    }
  }

  CatalogManifest _requireCatalogManifest(GenUiChatRequest request) {
    final raw = request.catalogManifestJson;
    if (raw == null || raw.trim().isEmpty) {
      throw GenUiStreamException(
        message: 'catalogManifestJson is required for GenUI requests.',
      );
    }

    try {
      return CatalogManifest.fromJsonString(raw);
    } on FormatException catch (error) {
      throw GenUiStreamException(
        message: 'Invalid catalogManifestJson: $error',
      );
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

  void _logModelResponse(
    Session session, {
    required String fullResponse,
    required bool isEdit,
    required String model,
    required int validatedMessageCount,
    List<String> validationErrors = const [],
  }) {
    if (session.serverpod.runMode != ServerpodRunMode.development) {
      return;
    }

    session.log(
      'GenUI model response model=$model isEdit=$isEdit '
      '(${fullResponse.length} chars, validatedMessages=$validatedMessageCount, '
      'validationErrors=${validationErrors.length})',
      level: LogLevel.info,
    );
    GenUiDevLogger.logLongText(
      session,
      fullResponse,
      header: 'Model response body:',
    );

    if (validationErrors.isNotEmpty) {
      GenUiDevLogger.logLongText(
        session,
        validationErrors.join('\n'),
        header: 'Validation errors:',
      );
    }
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
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
