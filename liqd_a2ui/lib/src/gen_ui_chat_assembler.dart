import 'dart:convert';

import 'catalog_manifest.dart';

/// Assembles OpenRouter chat messages for GenUI requests.
abstract final class GenUiChatAssembler {
  static const counterFewShotAssistant = '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/count","value":0}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","justify":"center","align":"center","children":["display","incrementBtn"]},{"id":"display","component":"Text","text":{"path":"/count"},"variant":"h1"},{"id":"incrementBtn","component":"Button","child":"incrementLabel","action":{"functionCall":{"call":"incrementPath","args":{"path":"/count"},"returnType":"void"}}},{"id":"incrementLabel","component":"Text","text":"+1"}]}}
```
''';

  static List<Map<String, String>> fewShotMessages() => [
    {'role': 'user', 'content': 'Build a simple counter with a +1 button.'},
    {'role': 'assistant', 'content': counterFewShotAssistant},
  ];

  static String buildSystemPrompt(
    CatalogManifest manifest, {
    bool isEdit = false,
  }) {
    final buffer = StringBuffer(manifest.systemPrompt.trim());
    buffer.writeln();
    buffer.writeln();
    buffer.writeln(_outputFormatInstructions);
    if (isEdit) {
      buffer.writeln();
      buffer.writeln(_editModeInstructions);
    }
    return buffer.toString();
  }

  static const _outputFormatInstructions = '''
CRITICAL: Output ONLY valid A2UI JSON blocks in markdown fences. No prose.
Emit blocks in order for new apps:
1. createSurface — surfaceId, catalogId, sendDataModel: true
2. updateDataModel — initial ephemeral state
3. updateComponents — full flat components array with id "root"
''';

  static const _editModeInstructions = '''
## Editing an existing app

The user already has a live app. Reuse the SAME surfaceId from the current app state.
Do NOT emit createSurface.
Output updateComponents with the COMPLETE components array for that surfaceId.
Every component id referenced by root, children, or Button child must appear in the array.
Only updateDataModel when state values change.
Reply with A2UI ```json blocks only. No explanatory text.
''';

  static String? buildExistingSurfacesMessage(String? existingSurfacesJson) {
    if (existingSurfacesJson == null || existingSurfacesJson.trim().isEmpty) {
      return null;
    }

    return '''
Current app state (preserve surfaceId; send the full component tree on edits):
```json
$existingSurfacesJson
```
''';
  }

  static Set<String> parseExistingSurfaceIds(String? existingSurfacesJson) {
    if (existingSurfacesJson == null || existingSurfacesJson.trim().isEmpty) {
      return const {};
    }

    try {
      final decoded = jsonDecode(existingSurfacesJson) as Map<String, dynamic>;
      final surfaces = decoded['surfaces'];
      if (surfaces is Map) {
        return surfaces.keys.map((key) => key.toString()).toSet();
      }
    } on FormatException {
      return const {};
    }

    return const {};
  }

  static String augmentUserMessageForEdit(String content) {
    return '$content\n\n'
        'Apply this to the existing app shown above. '
        'Reply with A2UI ```json blocks only (full updateComponents tree and/or '
        'updateDataModel). No explanatory text.';
  }

  static String validationRetryMessage(List<String> errors) {
    final numbered = errors
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');
    return 'Your previous output had validation errors:\n$numbered\n\n'
        'Fix ONLY these errors. Output corrected A2UI ```json blocks. No prose.';
  }

  static String a2uiCorrectionMessage() {
    return 'Your previous reply was plain text. The app preview only updates '
        'from A2UI JSON. Output ONLY ```json blocks with updateComponents '
        'and/or updateDataModel for the existing surfaceId. No prose.';
  }

  static bool responseContainsA2ui(String response) {
    final lower = response.toLowerCase();
    return lower.contains('updatecomponents') ||
        lower.contains('createsurface') ||
        lower.contains('updatedatamodel') ||
        lower.contains('deletesurface');
  }

  static List<Map<String, dynamic>> buildChatMessages({
    required CatalogManifest manifest,
    required bool isEdit,
    required String? existingSurfacesMessage,
    required List<Map<String, String>> userMessages,
  }) {
    return [
      {
        'role': 'system',
        'content': buildSystemPrompt(manifest, isEdit: isEdit),
      },
      ...fewShotMessages(),
      if (existingSurfacesMessage != null)
        {'role': 'assistant', 'content': existingSurfacesMessage},
      for (var i = 0; i < userMessages.length; i++)
        {
          'role': userMessages[i]['role'],
          'content':
              isEdit &&
                  userMessages[i]['role'] == 'user' &&
                  i == userMessages.length - 1
              ? augmentUserMessageForEdit(userMessages[i]['content']!)
              : userMessages[i]['content'],
        },
    ];
  }
}
