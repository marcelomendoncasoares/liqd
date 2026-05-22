import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:liqd_flutter/features/chat/component_tree_merger.dart';

void main() {
  group('ComponentTreeMerger', () {
    test('links orphan buttons into the last row', () {
      final controller = SurfaceController(
        catalogs: [BasicCatalogItems.asCatalog()],
      );
      addTearDown(controller.dispose);

      const surfaceId = 'calculator';
      controller.handleMessage(
        CreateSurface(
          surfaceId: surfaceId,
          catalogId: basicCatalogId,
          sendDataModel: true,
        ),
      );
      controller.handleMessage(
        UpdateComponents(
          surfaceId: surfaceId,
          components: [
            const Component(
              id: 'root',
              type: 'Column',
              properties: {
                'children': ['display', 'row1'],
              },
            ),
            const Component(
              id: 'display',
              type: 'Text',
              properties: {
                'text': {'path': '/display'},
              },
            ),
            const Component(
              id: 'row1',
              type: 'Row',
              properties: {
                'children': ['btn7'],
              },
            ),
            const Component(
              id: 'btn7',
              type: 'Button',
              properties: {
                'child': 'label7',
                'action': {
                  'event': {
                    'name': 'digit',
                    'context': {'digit': '7'},
                  },
                },
              },
            ),
            const Component(
              id: 'label7',
              type: 'Text',
              properties: {'text': '7'},
            ),
          ],
        ),
      );

      controller.handleMessage(
        UpdateComponents(
          surfaceId: surfaceId,
          components: [
            const Component(
              id: 'btnClear',
              type: 'Button',
              properties: {
                'child': 'labelClear',
                'action': {
                  'event': {'name': 'clear'},
                },
              },
            ),
            const Component(
              id: 'labelClear',
              type: 'Text',
              properties: {'text': 'C'},
            ),
          ],
        ),
      );

      expect(
        ComponentTreeMerger.linkOrphans(controller, surfaceId),
        isTrue,
      );

      final row = controller.registry
          .getSurface(surfaceId)!
          .components['row1']!;
      expect(row.properties['children'], ['btn7', 'btnClear', 'labelClear']);
    });
  });
}
