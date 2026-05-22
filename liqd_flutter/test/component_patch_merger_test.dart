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
  });
}
