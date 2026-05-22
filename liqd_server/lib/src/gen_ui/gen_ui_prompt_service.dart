import '../generated/protocol.dart';

/// Catalog identifier shared with the Flutter client.
const userCatalogId = 'com.liqd.user_catalog';

/// Builds system prompts for GenUI conversations with catalog context.
abstract final class GenUiPromptService {
  static List<Map<String, String>> fewShotMessages() {
    return [
      {
        'role': 'user',
        'content': 'Build a simple hello screen with a title.',
      },
      {
        'role': 'assistant',
        'content':
            '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"hello","catalogId":"$userCatalogId"}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"hello","components":[{"id":"root","component":"ScaffoldScreen","title":"Hello","body":{"type":"column","children":[{"type":"text","data":"Hello world!","style":{"fontSize":24}}]}}]}}
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

CRITICAL: Output ONLY valid A2UI JSON blocks. Do not explain in prose. Do not use catalog widget names as Stac "type" values — Stac types are lowercase: text, column, row, scaffold, elevatedButton, textField.

For every app request emit EXACTLY these two JSON blocks in order:

Block 1 — create surface:
{"version":"v0.9","createSurface":{"surfaceId":"<id>","catalogId":"$userCatalogId"}}

Block 2 — define UI (one root component with id "root"):
{"version":"v0.9","updateComponents":{"surfaceId":"<id>","components":[{"id":"root","component":"ScaffoldScreen","title":"...","body":{"type":"column","children":[...]}}]}}

Inside "body" use Stac JSON (type: column/row/text/elevatedButton). The "component" field uses catalog names (ScaffoldScreen, TextBlock, etc.) only in the components array.

Catalog widgets:
${catalogEntries.map((e) => '- ${e['name']}: ${e['description']}').join('\n')}

Calculator example (copy this pattern):
```json
{"version":"v0.9","createSurface":{"surfaceId":"calculator","catalogId":"$userCatalogId"}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calculator","components":[{"id":"root","component":"ScaffoldScreen","title":"Calculator","body":{"type":"column","children":[{"type":"text","data":"0","style":{"fontSize":32}},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"7"}},{"type":"elevatedButton","child":{"type":"text","data":"8"}},{"type":"elevatedButton","child":{"type":"text","data":"9"}}]},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"4"}},{"type":"elevatedButton","child":{"type":"text","data":"5"}},{"type":"elevatedButton","child":{"type":"text","data":"6"}}]},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"1"}},{"type":"elevatedButton","child":{"type":"text","data":"2"}},{"type":"elevatedButton","child":{"type":"text","data":"3"}}]},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"+"}},{"type":"elevatedButton","child":{"type":"text","data":"0"}},{"type":"elevatedButton","child":{"type":"text","data":"="}}]}]}}]}}
```
''';
  }
}
