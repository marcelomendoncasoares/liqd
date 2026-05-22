import 'package:liqd_server/src/gen_ui/a2ui_stream_normalizer.dart';
import 'package:liqd_server/src/gen_ui/gen_ui_prompt_service.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiStreamNormalizer', () {
    test('injects createSurface before updateComponents', () {
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
  });
}
