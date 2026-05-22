import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:liqd_flutter/features/chat/component_normalizer.dart';

void main() {
  group('ComponentNormalizer', () {
    test('adds Text child when Button uses label instead of child', () {
      final normalized = ComponentNormalizer.normalize([
        const Component(
          id: 'addBtn',
          type: 'Button',
          properties: {
            'label': 'Add',
            'action': {
              'functionCall': {
                'call': 'incrementPath',
                'args': {'path': '/count'},
                'returnType': 'void',
              },
            },
          },
        ),
      ]);

      expect(normalized, hasLength(2));
      expect(normalized[0].properties['child'], 'addBtnLabel');
      expect(normalized[0].properties.containsKey('label'), isFalse);
      expect(normalized[1].id, 'addBtnLabel');
      expect(normalized[1].type, 'Text');
      expect(normalized[1].properties['text'], 'Add');
    });
    test('adds label and value defaults for CheckBox', () {
      final normalized = ComponentNormalizer.normalize([
        const Component(
          id: 'checkbox',
          type: 'CheckBox',
          properties: {
            'value': {'path': 'done'},
          },
        ),
      ]);

      expect(normalized.single.properties['label'], 'Done');
    });

    test('rewrites mistaken absolute template text paths', () {
      final normalized = ComponentNormalizer.normalize([
        const Component(
          id: 'taskText',
          type: 'Text',
          properties: {
            'text': {'path': '/text'},
          },
        ),
      ]);

      expect(normalized.single.properties['text'], {'path': 'text'});
    });
  });
}
