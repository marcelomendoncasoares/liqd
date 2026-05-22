import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:test/test.dart';

import 'test_manifest.dart';

void main() {
  test(
    'extractor emits createSurface only once for adjacent fenced blocks',
    () {
      const response = '''
```json
{"version":"v0.9","createSurface":{"surfaceId":"calc","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}}
```
```json
{"version":"v0.9","updateDataModel":{"surfaceId":"calc","path":"/display","value":""}}
```
```json
{"version":"v0.9","updateComponents":{"surfaceId":"calc","components":[{"id":"root","component":"Column","children":["display"]},{"id":"display","component":"Text","text":{"path":"/display"}}]}}
```
''';

      final extractor = A2uiExtractor();
      final blocks = extractor.process(response);
      blocks.addAll(extractor.flush());

      expect(blocks, hasLength(3));
      expect(
        blocks.where((block) => block.contains('createSurface')),
        hasLength(1),
      );
    },
  );

  test('full calculator sequence validates and yields createSurface first', () async {
    final manifest = TestManifest.basic();
    final validator = A2uiValidator(manifest);
    const blocks = [
      '{"version":"v0.9","createSurface":{"surfaceId":"calc","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}}',
      '{"version":"v0.9","updateDataModel":{"surfaceId":"calc","path":"/display","value":""}}',
      '{"version":"v0.9","updateComponents":{"surfaceId":"calc","components":[{"id":"root","component":"Column","children":["display"]},{"id":"display","component":"Text","text":{"path":"/display"}}]}}',
    ];

    final yielded = <Map<String, dynamic>>[];
    for (final block in blocks) {
      final result = await validateA2uiJson(validator, block);
      expect(result.skipped, isFalse, reason: result.errors.toString());
      expect(result.isValid, isTrue, reason: result.errors.toString());
      yielded.add(result.message!);
    }

    expect(yielded.first.containsKey('createSurface'), isTrue);
  });
}
