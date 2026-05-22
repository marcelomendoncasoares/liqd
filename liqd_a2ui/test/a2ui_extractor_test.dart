import 'package:liqd_a2ui/liqd_a2ui.dart';
import 'package:test/test.dart';

void main() {
  group('A2uiExtractor', () {
    test('extracts fenced JSON across chunks', () {
      final extractor = A2uiExtractor();
      final first = extractor.process('Here is the UI:\n```json\n{"version"');
      expect(first, isEmpty);

      final second = extractor.process(
        ':"v0.9","createSurface":{"surfaceId":"main"',
      );
      expect(second, isEmpty);

      final third = extractor.process(
        ',"catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json"}}}\n```',
      );
      expect(third, hasLength(1));
      expect(third.single, contains('createSurface'));
    });

    test('extracts raw balanced JSON', () {
      final extractor = A2uiExtractor();
      final output = extractor.process(
        '{"version":"v0.9","updateDataModel":{"surfaceId":"main","path":"/count","value":0}}',
      );
      expect(output, hasLength(1));
      expect(output.single, contains('updateDataModel'));
    });

    test('flush emits nothing when buffer is incomplete JSON', () {
      final extractor = A2uiExtractor();
      extractor.process('{"version":"v0.9"');
      expect(extractor.flush(), isEmpty);
    });
  });
}
