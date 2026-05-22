import 'gen_ui_prompt_service.dart';

/// Canned A2UI stream for local development when OpenRouter is not configured.
abstract final class GenUiDevMock {
  static const counterResponse = '''
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

  static Stream<String> streamCounter() async* {
    for (final line in counterResponse.split('\n')) {
      yield '$line\n';
    }
  }

  /// @deprecated Use [streamCounter].
  static Stream<String> streamCalculator() => streamCounter();
}
