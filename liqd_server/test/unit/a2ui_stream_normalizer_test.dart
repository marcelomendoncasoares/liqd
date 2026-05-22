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

    test('injects createSurface with user catalog for layout widgets', () {
      final normalizer = A2uiStreamNormalizer();
      final chunks = normalizer.process('''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"layout","components":[{"id":"root","component":"VerticalLayout","children":[]}]}}
```
''');

      expect(chunks.first, contains(userCatalogId));
    });

    test('injects createSurface with user catalog for custom widget names', () {
      final normalizer = A2uiStreamNormalizer(
        userWidgetNames: {'MetricCard'},
      );
      final chunks = normalizer.process('''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"dash","components":[{"id":"root","component":"MetricCard","title":"Revenue"}]}}
```
''');

      expect(chunks.first, contains(userCatalogId));
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

    test('strips createSurface for surfaces that already exist', () {
      final normalizer = A2uiStreamNormalizer(
        existingSurfaceIds: {'main'},
      );
      final chunks = normalizer.process('''
```json
{"version":"v0.9","createSurface":{"surfaceId":"main","catalogId":"$basicCatalogId"},"updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":["btn"]}]}}
```
''');

      expect(chunks.single, isNot(contains('createSurface')));
      expect(chunks.single, contains('updateComponents'));
    });

    test('merges children when patching an existing surface', () {
      final normalizer = A2uiStreamNormalizer(
        existingSurfaceIds: {'main'},
        existingSurfaces: {
          'main': {
            'surfaceId': 'main',
            'components': [
              {
                'id': 'root',
                'component': 'Column',
                'children': ['inputRow'],
              },
            ],
          },
        },
      );
      final chunks = normalizer.process('''
```json
{"version":"v0.9","updateComponents":{"surfaceId":"main","components":[{"id":"root","component":"Column","children":["clearBtn"]},{"id":"clearBtn","component":"Button","child":"clearLabel"}]}}
```
''');

      expect(chunks.single, contains('"children":["inputRow","clearBtn"]'));
    });
  });
}
