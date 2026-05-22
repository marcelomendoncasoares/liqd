import 'gen_ui_prompt_service.dart';

/// Canned A2UI stream for local development when OpenRouter is not configured.
abstract final class GenUiDevMock {
  static const counterResponse =
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

  static const calculatorResponse =
      '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"calculator","catalogId":"$basicCatalogId","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"calculator","path":"/display","value":"0"}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calculator","components":[{"id":"root","component":"Column","align":"stretch","children":["display","row1","row2","row3","row4"]},{"id":"display","component":"Text","text":{"path":"/display"},"variant":"h2"},{"id":"row1","component":"Row","children":["btn7","btn8","btn9"]},{"id":"btn7","component":"Button","child":"btn7Label","action":{"event":{"name":"digit","context":{"digit":"7"}}}},{"id":"btn7Label","component":"Text","text":"7"},{"id":"btn8","component":"Button","child":"btn8Label","action":{"event":{"name":"digit","context":{"digit":"8"}}}},{"id":"btn8Label","component":"Text","text":"8"},{"id":"btn9","component":"Button","child":"btn9Label","action":{"event":{"name":"digit","context":{"digit":"9"}}}},{"id":"btn9Label","component":"Text","text":"9"},{"id":"row2","component":"Row","children":["btn4","btn5","btn6"]},{"id":"btn4","component":"Button","child":"btn4Label","action":{"event":{"name":"digit","context":{"digit":"4"}}}},{"id":"btn4Label","component":"Text","text":"4"},{"id":"btn5","component":"Button","child":"btn5Label","action":{"event":{"name":"digit","context":{"digit":"5"}}}},{"id":"btn5Label","component":"Text","text":"5"},{"id":"btn6","component":"Button","child":"btn6Label","action":{"event":{"name":"digit","context":{"digit":"6"}}}},{"id":"btn6Label","component":"Text","text":"6"},{"id":"row3","component":"Row","children":["btn1","btn2","btn3"]},{"id":"btn1","component":"Button","child":"btn1Label","action":{"event":{"name":"digit","context":{"digit":"1"}}}},{"id":"btn1Label","component":"Text","text":"1"},{"id":"btn2","component":"Button","child":"btn2Label","action":{"event":{"name":"digit","context":{"digit":"2"}}}},{"id":"btn2Label","component":"Text","text":"2"},{"id":"btn3","component":"Button","child":"btn3Label","action":{"event":{"name":"digit","context":{"digit":"3"}}}},{"id":"btn3Label","component":"Text","text":"3"},{"id":"row4","component":"Row","children":["btn0"]},{"id":"btn0","component":"Button","child":"btn0Label","action":{"event":{"name":"digit","context":{"digit":"0"}}}},{"id":"btn0Label","component":"Text","text":"0"}]}}
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
