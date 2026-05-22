import 'package:liqd_server/src/widgets/stac_validator.dart';
import 'package:test/test.dart';

void main() {
  group('StacValidator', () {
    test('accepts valid text widget', () {
      final result = StacValidator.validate({
        'type': 'text',
        'data': 'Hello',
      });
      expect(result.valid, isTrue);
    });

    test('rejects missing type', () {
      final result = StacValidator.validate({'data': 'Hello'});
      expect(result.valid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('rejects unsupported type', () {
      final result = StacValidator.validate({
        'type': 'unknownWidget',
        'data': 'Hello',
      });
      expect(result.valid, isFalse);
    });

    test('accepts checkBox and setValue types', () {
      expect(
        StacValidator.validate({'type': 'checkBox', 'value': true}).valid,
        isTrue,
      );
      expect(
        StacValidator.validate({
          'type': 'setValue',
          'values': [
            {'key': 'count', 'value': 0},
          ],
          'child': {'type': 'text', 'data': '{{count}}'},
        }).valid,
        isTrue,
      );
    });
  });
}
