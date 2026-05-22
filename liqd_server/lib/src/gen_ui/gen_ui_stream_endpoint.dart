import 'dart:convert';

import '../generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../ai/open_router_client.dart';
import '../ai/open_router_config.dart';
import '../widgets/stac_validator.dart';
import '../widgets/widget_catalog_endpoint.dart';

/// Builds system prompts for GenUI conversations with catalog context.
abstract final class GenUiPromptService {
  static String buildSystemPrompt(List<UserWidget> widgets) {
    final catalogEntries = widgets
        .map(
          (w) => {
            'name': w.name,
            'description': w.description,
            if (w.dataSchema != null) 'dataSchema': w.dataSchema,
          },
        )
        .toList();

    return '''
You are Liqd, an AI assistant that helps users build interactive apps through generative UI.

You MUST use the available widget catalog to compose UI surfaces. When the user asks you to build something, respond with GenUI-compatible A2UI JSON messages that reference catalog widgets by name with appropriate data parameters.

Available widget catalog:
${catalogEntries.map((e) => '- ${e['name']}: ${e['description']}').join('\n')}

Rules:
1. Prefer existing catalog widgets whenever they fit the user's request.
2. Compose complex layouts by nesting widgets (e.g., ScaffoldScreen containing VerticalLayout with TextBlock and PrimaryButton children).
3. When no catalog widget fits, emit a fenced JSON block with language tag "new-widget" containing: {"name": "...", "description": "...", "dataSchema": {...}, "stacJson": {...}}. The stacJson must use valid Stac widget types (text, column, row, scaffold, elevatedButton, textField, etc.).
4. Mix plain text explanations with UI generation as appropriate.
5. Keep widget names PascalCase and unique.
''';
  }
}

class GenUiStreamEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  static const defaultModel = 'deepseek/deepseek-v4-flash:free';

  Stream<String> chatStream(Session session, GenUiChatRequest request) async* {
    final authUserId = _requireAuthUserId(session);

    final catalogEndpoint = WidgetCatalogEndpoint();
    final widgets = await catalogEndpoint.listMyWidgets(session);
    final systemPrompt = GenUiPromptService.buildSystemPrompt(widgets);

    final apiKey = OpenRouterConfig.resolveApiKey(session);
    if (apiKey == null) {
      session.log(OpenRouterConfig.missingKeyMessage(), level: LogLevel.error);
      throw GenUiStreamException(message: OpenRouterConfig.missingKeyMessage());
    }

    final client = OpenRouterClient(
      apiKey: apiKey,
      siteUrl: 'https://liqd.dev',
      appName: 'Liqd',
    );

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ...request.messages.map(
        (m) => {'role': m.role, 'content': m.content},
      ),
    ];

    final model = request.model ?? defaultModel;
    final buffer = StringBuffer();

    try {
      await for (final chunk in client.streamChat(
        model: model,
        messages: messages,
      )) {
        buffer.write(chunk);
        yield chunk;
      }

      await _processNewWidgetBlocks(session, authUserId, buffer.toString());
    } on OpenRouterException catch (error) {
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
      throw ArgumentError('Authentication required.');
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
