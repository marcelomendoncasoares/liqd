import 'gen_ui_prompt_service.dart';

/// Canned A2UI stream for local development when OpenRouter is not configured.
abstract final class GenUiDevMock {
  static const calculatorResponse =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"calculator","catalogId":"$userCatalogId"}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calculator","components":[{"id":"root","component":"ScaffoldScreen","title":"Calculator","body":{"type":"column","children":[{"type":"text","data":"0","style":{"fontSize":32}},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"7"}},{"type":"elevatedButton","child":{"type":"text","data":"8"}},{"type":"elevatedButton","child":{"type":"text","data":"9"}}]},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"4"}},{"type":"elevatedButton","child":{"type":"text","data":"5"}},{"type":"elevatedButton","child":{"type":"text","data":"6"}}]},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"1"}},{"type":"elevatedButton","child":{"type":"text","data":"2"}},{"type":"elevatedButton","child":{"type":"text","data":"3"}}]},{"type":"row","children":[{"type":"elevatedButton","child":{"type":"text","data":"+"}},{"type":"elevatedButton","child":{"type":"text","data":"0"}},{"type":"elevatedButton","child":{"type":"text","data":"="}}]}]}}]}}
```
''';

  static Stream<String> streamCalculator() async* {
    for (final line in calculatorResponse.split('\n')) {
      yield '$line\n';
    }
  }
}
