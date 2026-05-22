import 'package:liqd_server/src/gen_ui/component_normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentNormalizer', () {
    test('adds Text child when Button uses label instead of child', () {
      final normalized = ComponentNormalizer.normalizeJsonList([
        {
          'id': 'addBtn',
          'component': 'Button',
          'label': 'Add',
          'action': {
            'functionCall': {
              'call': 'incrementPath',
              'args': {'path': '/count'},
              'returnType': 'void',
            },
          },
        },
      ]);

      expect(normalized, hasLength(2));
      expect(normalized[0]['child'], 'addBtnLabel');
      expect(normalized[0]['label'], isNull);
      expect(normalized[1], {
        'id': 'addBtnLabel',
        'component': 'Text',
        'text': 'Add',
      });
    });

    test('leaves Button unchanged when child is already set', () {
      final normalized = ComponentNormalizer.normalizeJsonList([
        {
          'id': 'addBtn',
          'component': 'Button',
          'child': 'addLabel',
          'action': {'functionCall': {}},
        },
        {
          'id': 'addLabel',
          'component': 'Text',
          'text': 'Add',
        },
      ]);

      expect(normalized, hasLength(2));
      expect(normalized[0]['child'], 'addLabel');
    });
  });
}
