import 'dart:convert';

import '../generated/protocol.dart';
import '../ai/open_router_client.dart';
import '../ai/open_router_config.dart';
import '../widgets/stac_validator.dart';
import 'package:serverpod/serverpod.dart';

import 'stac_extractor.dart';
import 'stac_prompt.dart';

class StacAppEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const defaultModel = 'deepseek/deepseek-v4-flash:free';
  static const _maxValidationRetries = 2;

  Future<StacGenerateResponse> generateApp(
    Session session,
    StacGenerateRequest request,
  ) async {
    try {
      return await _generateAppImpl(session, request);
    } on StacGenerateException {
      rethrow;
    } catch (error, stackTrace) {
      session.log('generateApp failed: $error', level: LogLevel.error);
      session.log('$stackTrace', level: LogLevel.debug);
      throw StacGenerateException(message: 'Stac generation failed: $error');
    }
  }

  Future<StacGenerateResponse> _generateAppImpl(
    Session session,
    StacGenerateRequest request,
  ) async {
    final authUserId = _requireAuthUserId(session);
    final isEdit =
        request.existingStacJson != null &&
        request.existingStacJson!.trim().isNotEmpty;

    final apiKey = OpenRouterConfig.resolveApiKey(session);
    if (apiKey == null) {
      session.log(OpenRouterConfig.missingKeyMessage(), level: LogLevel.error);
      throw StacGenerateException(
        message: OpenRouterConfig.missingKeyMessage(),
      );
    }

    final model = request.model ?? defaultModel;
    final existingStacMessage = StacPrompt.buildExistingStacMessage(
      request.existingStacJson,
    );

    var messages = StacPrompt.buildChatMessages(
      isEdit: isEdit,
      existingStacMessage: existingStacMessage,
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

      while (attempt <= _maxValidationRetries) {
        final fullResponse = await client.chat(
          model: model,
          messages: messages,
        );

        final stacJson = StacExtractor.extract(fullResponse);
        if (stacJson == null) {
          if (attempt == _maxValidationRetries) {
            await _processNewWidgetBlocks(session, authUserId, fullResponse);
            return StacGenerateResponse(
              rawResponse: fullResponse,
              validationErrors: const ['No valid Stac JSON found in response.'],
            );
          }

          messages = [
            ...messages,
            {'role': 'assistant', 'content': fullResponse},
            {'role': 'user', 'content': StacPrompt.stacCorrectionMessage()},
          ];
          attempt++;
          continue;
        }

        final validation = StacValidator.validate(stacJson);
        if (!validation.valid) {
          final errors = validation.errors ?? const ['Invalid Stac JSON.'];
          if (attempt == _maxValidationRetries) {
            await _processNewWidgetBlocks(session, authUserId, fullResponse);
            return StacGenerateResponse(
              rawResponse: fullResponse,
              validationErrors: errors,
            );
          }

          messages = [
            ...messages,
            {'role': 'assistant', 'content': fullResponse},
            {
              'role': 'user',
              'content': StacPrompt.validationRetryMessage(errors),
            },
          ];
          attempt++;
          continue;
        }

        await _processNewWidgetBlocks(session, authUserId, fullResponse);
        return StacGenerateResponse(
          stacJson: stacJson,
          rawResponse: fullResponse,
        );
      }

      return StacGenerateResponse(
        rawResponse: '',
        validationErrors: const ['Generation failed after retries.'],
      );
    } on OpenRouterException catch (error) {
      session.log('OpenRouter error: $error', level: LogLevel.error);
      throw StacGenerateException(
        message:
            'OpenRouter request failed (${error.statusCode}): '
            '${_truncate(error.body, 300)}',
      );
    } finally {
      client.close();
    }
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
      } on FormatException catch (error) {
        session.log('Failed to parse new-widget block: $error');
      }
    }
  }

  UuidValue _requireAuthUserId(Session session) {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw StacGenerateException(
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
