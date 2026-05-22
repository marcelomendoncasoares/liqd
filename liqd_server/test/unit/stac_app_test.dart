import 'package:liqd_server/src/stac_app/stac_dev_mock.dart';
import 'package:liqd_server/src/stac_app/stac_extractor.dart';
import 'package:liqd_server/src/widgets/stac_validator.dart';
import 'package:test/test.dart';

void main() {
  group('StacDevMock', () {
    test('calculator validates', () {
      final result = StacValidator.validate(StacDevMock.calculator());
      expect(result.valid, isTrue, reason: result.errors?.join(', '));
    });

    test('counter validates', () {
      final result = StacValidator.validate(StacDevMock.counter());
      expect(result.valid, isTrue, reason: result.errors?.join(', '));
    });
  });

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
