import 'dart:convert';

import '../generated/protocol.dart';

/// Catalog identifier shared with the Flutter client.
const userCatalogId = 'com.liqd.user_catalog';

/// GenUI basic catalog for native interactive components (Text, Button, …).
const basicCatalogId = 'https://a2ui.org/specification/v0_9/basic_catalog.json';

/// Builds system prompts for GenUI conversations with catalog context.
abstract final class GenUiPromptService {
  static List<Map<String, String>> fewShotMessages({bool includeEdit = false}) {
    final messages = [
      {
        'role': 'user',
        'content': 'Build a simple counter with a +1 button.',
      },
      {
        'role': 'assistant',
        'content': _counterFewShot,
      },
      {
        'role': 'user',
        'content': 'Build a calculator with number buttons and a display.',
      },
      {
        'role': 'assistant',
        'content': _calculatorFewShot,
      },
    ];

    if (includeEdit) {
      messages.addAll([
        {
          'role': 'user',
          'content': 'Add a clear button to the calculator.',
        },
        {
          'role': 'assistant',
          'content': _calculatorEditFewShot,
        },
      ]);
    }

    return messages;
  }

  static const _counterFewShot =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"counter","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"counter","path":"/count","value":0}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"counter","components":[{"id":"root","component":"Column","justify":"center","align":"center","children":["display","incrementBtn"]},{"id":"display","component":"Text","text":{"path":"/count"},"variant":"h1"},{"id":"incrementBtn","component":"Button","child":"incrementLabel","action":{"event":{"name":"increment"}}},{"id":"incrementLabel","component":"Text","text":"+1"}]}}
```
''';

  static const _calculatorFewShot =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"calculator","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"calculator","path":"/display","value":"0"}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calculator","components":[{"id":"root","component":"Column","align":"stretch","children":["display","row1","row2"]},{"id":"display","component":"Text","text":{"path":"/display"},"variant":"h2"},{"id":"row1","component":"Row","children":["btn7","btn8","btn9"]},{"id":"btn7","component":"Button","child":"btn7Label","action":{"event":{"name":"digit","context":{"digit":"7"}}}},{"id":"btn7Label","component":"Text","text":"7"},{"id":"btn8","component":"Button","child":"btn8Label","action":{"event":{"name":"digit","context":{"digit":"8"}}}},{"id":"btn8Label","component":"Text","text":"8"},{"id":"btn9","component":"Button","child":"btn9Label","action":{"event":{"name":"digit","context":{"digit":"9"}}}},{"id":"btn9Label","component":"Text","text":"9"},{"id":"row2","component":"Row","children":["btn4","btn5","btn6"]},{"id":"btn4","component":"Button","child":"btn4Label","action":{"event":{"name":"digit","context":{"digit":"4"}}}},{"id":"btn4Label","component":"Text","text":"4"},{"id":"btn5","component":"Button","child":"btn5Label","action":{"event":{"name":"digit","context":{"digit":"5"}}}},{"id":"btn5Label","component":"Text","text":"5"},{"id":"btn6","component":"Button","child":"btn6Label","action":{"event":{"name":"digit","context":{"digit":"6"}}}},{"id":"btn6Label","component":"Text","text":"6"}]}}
```
''';

  static const _calculatorEditFewShot = '''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calculator","components":[{"id":"rowClear","component":"Row","children":["btnClear"]},{"id":"btnClear","component":"Button","child":"btnClearLabel","action":{"event":{"name":"clear"}}},{"id":"btnClearLabel","component":"Text","text":"C"}]}}
```
''';

  static String buildSystemPrompt(
    List<UserWidget> widgets, {
    bool isEdit = false,
  }) {
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
You are Liqd, an AI that builds interactive Flutter apps using the A2UI v0.9 protocol.

CRITICAL: Output ONLY valid A2UI JSON blocks in markdown fences. No prose.
${isEdit ? _editModeInstructions : ''}
## Interactive apps (preferred): native GenUI catalog

Use catalogId "$basicCatalogId" with sendDataModel: true.

Emit blocks in order:
1. createSurface — surfaceId, catalogId, sendDataModel: true
2. updateDataModel — initial state (e.g. path "/count", value 0)
3. updateComponents — flat components array; one must have id "root"

Native component names (case-sensitive): Column, Row, Text, Button, TextField, CheckBox, Card, List.

Rules:
- Text "text" may be a literal string OR a binding like {"path":"/count"}.
- Every Button MUST include "action": {"event":{"name":"<actionName>"}}.
- Every Button MUST set "child" to a component id AND include a matching Text
  component in the same updateComponents array (e.g. btn7 + btn7Label).
- Every id listed in Column/Row "children" or Button "child" MUST appear as
  its own component entry in the same updateComponents array.
- Column/Row "children" is an array of component id strings.
- Do NOT put Stac JSON (type: column, elevatedButton) inside native components.

Counter pattern:
```json
{"version":"v0.9","createSurface":{"surfaceId":"counter","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"counter","path":"/count","value":0}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"counter","components":[{"id":"root","component":"Column","children":["display","incrementBtn"]},{"id":"display","component":"Text","text":{"path":"/count"},"variant":"h1"},{"id":"incrementBtn","component":"Button","child":"incrementLabel","action":{"event":{"name":"increment"}}},{"id":"incrementLabel","component":"Text","text":"+1"}]}}
```

## Layout-only / custom Stac widgets

For ScaffoldScreen and user catalog widgets use catalogId "$userCatalogId".
Embed Stac JSON only inside component data fields (body, children).

Stac interactivity (reactive UI):
- Initialize state with a setValue widget wrapping the body:
  {"type":"setValue","values":[{"key":"count","value":0}],"child":{...}}
- Display dynamic values with registry bindings: {"type":"text","data":"{{count}}"}
- Every elevatedButton MUST include onPressed with a setValue action:
  {"type":"setValue","values":[{"key":"count","value":"count+1"}]}
- Use registry key names in expressions (e.g. count+1) for increments.

User catalog widgets:
${catalogEntries.map((e) => '- ${e['name']}: ${e['description']}').join('\n')}
''';
  }

  static const _editModeInstructions = '''
## Editing an existing app (follow-up requests)

The user already has a live app. You MUST incrementally modify it:
- Reuse the SAME surfaceId from the current app state message.
- Do NOT emit createSurface unless the user explicitly asks for a new screen.
- Prefer updateComponents for changed/new components and updateDataModel for state.
- Only include components you add or change; unchanged components can be omitted.
- Never rebuild the entire app from scratch unless the user asks to start over.

''';

  /// Formats existing surface JSON for injection as an assistant context message.
  static String? buildExistingSurfacesMessage(String? existingSurfacesJson) {
    if (existingSurfacesJson == null || existingSurfacesJson.trim().isEmpty) {
      return null;
    }

    return '''
Current app state (preserve surfaceId and incrementally edit):
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
}
