import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:liqd_flutter/features/chat/component_patch_merger.dart';

void main() {
  group('ComponentPatchMerger', () {
    test('merges root children when patch only adds new ids', () {
      final existing = SurfaceDefinition(
        surfaceId: 'main',
        catalogId: basicCatalogId,
        components: {
          'root': Component(
            id: 'root',
            type: 'Column',
            properties: {
              'children': ['inputRow'],
            },
          ),
          'inputRow': Component(
            id: 'inputRow',
            type: 'Row',
            properties: {
              'children': ['field'],
            },
          ),
        },
      );

      final merged = ComponentPatchMerger.merge(
        existing: existing,
        incoming: const [
          Component(
            id: 'root',
            type: 'Column',
            properties: {
              'children': ['clearBtn'],
            },
          ),
          Component(
            id: 'clearBtn',
            type: 'Button',
            properties: {
              'child': 'clearLabel',
              'action': {
                'functionCall': {
                  'call': 'setPath',
                  'args': {'path': '/newTodo', 'value': ''},
                  'returnType': 'void',
                },
              },
            },
          ),
        ],
      );

      final root = merged.firstWhere((component) => component.id == 'root');
      expect(root.properties['children'], ['inputRow', 'clearBtn']);
    });

    test('replaces children when patch lists all existing plus new ids', () {
      final existing = SurfaceDefinition(
        surfaceId: 'main',
        catalogId: basicCatalogId,
        components: {
          'root': Component(
            id: 'root',
            type: 'Column',
            properties: {
              'children': ['inputRow'],
            },
          ),
        },
      );

      final merged = ComponentPatchMerger.merge(
        existing: existing,
        incoming: const [
          Component(
            id: 'root',
            type: 'Column',
            properties: {
              'children': ['inputRow', 'clearBtn'],
            },
          ),
        ],
      );

      expect(
        merged.single.properties['children'],
        ['inputRow', 'clearBtn'],
      );
    });
    test('does not overwrite child with null during merge', () {
      final merged = ComponentPatchMerger.merge(
        existing: SurfaceDefinition(
          surfaceId: 'main',
          components: {
            'addBtn': const Component(
              id: 'addBtn',
              type: 'Button',
              properties: {
                'child': 'addLabel',
                'action': {'functionCall': {}},
              },
            ),
          },
        ),
        incoming: [
          const Component(
            id: 'addBtn',
            type: 'Button',
            properties: {
              'child': null,
              'action': {
                'functionCall': {
                  'call': 'setPath',
                  'args': {'path': '/count', 'value': 0},
                  'returnType': 'void',
                },
              },
            },
          ),
        ],
      );

      expect(merged.single.properties['child'], 'addLabel');
    });
  });
}
