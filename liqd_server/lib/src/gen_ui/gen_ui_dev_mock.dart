import 'gen_ui_prompt_service.dart';

/// Canned A2UI stream for local development when OpenRouter is not configured.
abstract final class GenUiDevMock {
  static const counterResponse =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/count","value":0}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","justify":"center","align":"center","children":["display","incrementBtn"]},{"id":"display","component":"Text","text":{"path":"/count"},"variant":"h1"},{"id":"incrementBtn","component":"Button","child":"incrementLabel","action":{"functionCall":{"call":"incrementPath","args":{"path":"/count"},"returnType":"void"}}},{"id":"incrementLabel","component":"Text","text":"+1"}]}}
```
''';

  /// Compact numeric keypad demo using local functionCall actions.
  static const calculatorResponse =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/display","value":"0"}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","align":"stretch","children":["display","row1","row2"]},{"id":"display","component":"Text","text":{"path":"/display"},"variant":"h2"},{"id":"row1","component":"Row","children":["btn7","btn8","btn9"]},{"id":"btn7","component":"Button","child":"btn7Label","action":{"functionCall":{"call":"appendToPath","args":{"path":"/display","value":"7"},"returnType":"void"}}},{"id":"btn7Label","component":"Text","text":"7"},{"id":"btn8","component":"Button","child":"btn8Label","action":{"functionCall":{"call":"appendToPath","args":{"path":"/display","value":"8"},"returnType":"void"}}},{"id":"btn8Label","component":"Text","text":"8"},{"id":"btn9","component":"Button","child":"btn9Label","action":{"functionCall":{"call":"appendToPath","args":{"path":"/display","value":"9"},"returnType":"void"}}},{"id":"btn9Label","component":"Text","text":"9"},{"id":"row2","component":"Row","children":["btnClear","btnEquals"]},{"id":"btnClear","component":"Button","child":"btnClearLabel","action":{"functionCall":{"call":"setPath","args":{"path":"/display","value":"0"},"returnType":"void"}}},{"id":"btnClearLabel","component":"Text","text":"C"},{"id":"btnEquals","component":"Button","child":"btnEqualsLabel","action":{"functionCall":{"call":"evaluateMathPath","args":{"path":"/display"},"returnType":"void"}}},{"id":"btnEqualsLabel","component":"Text","text":"="}]}}
```
''';

  static Stream<String> streamCounter() async* {
    for (final line in counterResponse.split('\n')) {
      yield '$line\n';
    }
  }

  static Stream<String> streamCalculator() async* {
    for (final line in calculatorResponse.split('\n')) {
      yield '$line\n';
    }
  }
}
