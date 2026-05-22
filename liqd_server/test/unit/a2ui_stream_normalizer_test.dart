import 'package:liqd_server/src/gen_ui/a2ui_stream_normalizer.dart';
import 'package:liqd_server/src/gen_ui/gen_ui_prompt_service.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiStreamNormalizer', () {
    test('injects createSurface with user catalog for Stac widgets', () {
      final normalizer = A2uiStreamNormalizer();
      final chunks = normalizer.process('''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calc","components":[{"id":"root","component":"ScaffoldScreen","title":"Calc","body":{"type":"column","children":[]}}]}}
```
''');

      expect(chunks.length, 2);
      expect(chunks.first, contains('createSurface'));
      expect(chunks.first, contains('calc'));
      expect(chunks.first, contains(userCatalogId));
      expect(chunks.last, contains('updateComponents'));
    });

    test('injects createSurface with basic catalog for native widgets', () {
      final normalizer = A2uiStreamNormalizer();
      final chunks = normalizer.process('''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"counter","components":[{"id":"root","component":"Column","children":["btn"]},{"id":"btn","component":"Button","child":"lbl","action":{"event":{"name":"increment"}}},{"id":"lbl","component":"Text","text":"+1"}]}}
```
''');

      expect(chunks.length, 2);
      expect(chunks.first, contains('createSurface'));
      expect(chunks.first, contains(basicCatalogId));
      expect(chunks.first, contains('sendDataModel'));
    });

    test('skips createSurface injection for existing client surfaces', () {
      final normalizer = A2uiStreamNormalizer(
        existingSurfaceIds: {'calculator'},
      );
      final chunks = normalizer.process('''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calculator","components":[{"id":"btnClear","component":"Button","child":"lbl","action":{"event":{"name":"clear"}}},{"id":"lbl","component":"Text","text":"C"}]}}
```
''');

      expect(chunks.length, 1);
      expect(chunks.single, isNot(contains('createSurface')));
      expect(chunks.single, contains('updateComponents'));
    });
  });
}
