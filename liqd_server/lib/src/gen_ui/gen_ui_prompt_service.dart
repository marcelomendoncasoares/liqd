import '../generated/protocol.dart';

/// Catalog identifier shared with the Flutter client.
const userCatalogId = 'com.liqd.user_catalog';

/// GenUI basic catalog for native interactive components (Text, Button, …).
const basicCatalogId = 'https://a2ui.org/specification/v0_9/basic_catalog.json';

/// Builds system prompts for GenUI conversations with catalog context.
abstract final class GenUiPromptService {
  static List<Map<String, String>> fewShotMessages() {
    return [
      {
        'role': 'user',
        'content': 'Build a simple counter with a +1 button.',
      },
      {
        'role': 'assistant',
        'content':
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
''',
      },
    ];
  }

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
You are Liqd, an AI that builds interactive Flutter apps using the A2UI v0.9 protocol.

CRITICAL: Output ONLY valid A2UI JSON blocks in markdown fences. No prose.

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
}
