import 'package:liqd_server/src/stac_app/stac_extractor.dart';
import 'package:test/test.dart';

void main() {
  group('StacExtractor', () {
    test('extracts fenced Stac JSON', () {
      final extracted = StacExtractor.extract(
        '```json\n{"type":"column","children":[]}\n```',
      );
      expect(extracted, isNotNull);
      expect(extracted!['type'], 'column');
    });
  });
}
