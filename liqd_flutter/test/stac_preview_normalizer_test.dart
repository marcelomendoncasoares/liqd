import 'package:liqd_flutter/features/catalog/stac_preview_normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeStacForPreview', () {
    test('unwraps scaffold body', () {
      final normalized = normalizeStacForPreview({
        'type': 'scaffold',
        'body': {
          'type': 'column',
          'children': [
            {'type': 'text', 'data': 'Hi'},
          ],
        },
      });

      expect(normalized['type'], 'column');
    });

    test('unwraps scaffold inside setValue child', () {
      final normalized = normalizeStacForPreview({
        'type': 'setValue',
        'values': [
          {'key': 'count', 'value': 0},
        ],
        'child': {
          'type': 'scaffold',
          'body': {
            'type': 'text',
            'data': '{{count}}',
          },
        },
      });

      expect(normalized['type'], 'setValue');
      expect(normalized['child']['type'], 'text');
    });
  });
}
