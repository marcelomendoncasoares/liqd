import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:liqd_flutter/features/chat/local_action_handler.dart';
import 'package:liqd_flutter/features/chat/local_calculator_action_delegate.dart';

void main() {
  group('LocalActionHandler.appendDigit,', () {
    test('then replaces a leading zero.', () {
      expect(LocalActionHandler.appendDigit('0', '7'), '7');
    });

    test('then appends to a non-zero display.', () {
      expect(LocalActionHandler.appendDigit('12', '3'), '123');
    });
  });

  group(
    'Given a calculator surface with display "0", '
    'when a digit action is handled locally,',
    () {
      late SurfaceController controller;
      const surfaceId = 'calculator';

      setUp(() => controller = _calculatorController());
      tearDown(() => controller.dispose());

      test('then the display updates for a standard digit action.', () {
        final handled = LocalActionHandler.tryHandle(
          controller: controller,
          message: _actionMessage(
            name: 'digit',
            surfaceId: surfaceId,
            context: {'digit': '7'},
          ),
        );

        expect(handled, isTrue);
        expect(_displayValue(controller, surfaceId), '7');
      });

      test('then the display updates for a btn7 component id.', () {
        final handled = LocalActionHandler.tryHandle(
          controller: controller,
          message: _actionMessage(
            name: 'appendDigit',
            surfaceId: surfaceId,
            sourceComponentId: 'btn7',
          ),
        );

        expect(handled, isTrue);
        expect(_displayValue(controller, surfaceId), '7');
      });
    },
  );

  group(
    'Given a calculator surface wired through LocalCalculatorActionDelegate, '
    'when the user taps a number button,',
    () {
      testWidgets('then the display updates on screen.', (tester) async {
        final controller = SurfaceController(
          catalogs: [BasicCatalogItems.asCatalog()],
        );
        const surfaceId = 'calculator';
        _seedCalculator(controller, surfaceId: surfaceId);

        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Surface(
                surfaceContext: controller.contextFor(surfaceId),
                actionDelegate: LocalCalculatorActionDelegate(
                  controller: controller,
                ),
              ),
            ),
          ),
        );

        expect(find.text('0'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(ElevatedButton),
            matching: find.text('7'),
          ),
        );
        await tester.pump();

        expect(_displayValue(controller, surfaceId), '7');
        expect(find.text('0'), findsNothing);
      });
    },
  );

  group(
    'Given a calculator surface with display "12+3", '
    'when an equals action is handled locally,',
    () {
      late SurfaceController controller;
      const surfaceId = 'calculator';

      setUp(() {
        controller = _calculatorController(initialDisplay: '12+3');
      });
      tearDown(() => controller.dispose());

      test('then the display shows the evaluated result.', () {
        final handled = LocalActionHandler.tryHandle(
          controller: controller,
          message: _actionMessage(
            name: 'equals',
            surfaceId: surfaceId,
            sourceComponentId: 'btnEquals',
          ),
        );

        expect(handled, isTrue);
        expect(_displayValue(controller, surfaceId), '15');
      });
    },
  );
}

SurfaceController _calculatorController({String initialDisplay = '0'}) {
  final controller = SurfaceController(
    catalogs: [BasicCatalogItems.asCatalog()],
  );
  _seedCalculator(controller, initialDisplay: initialDisplay);
  return controller;
}

void _seedCalculator(
  SurfaceController controller, {
  String surfaceId = 'calculator',
  String initialDisplay = '0',
}) {
  controller.handleMessage(
    CreateSurface(
      surfaceId: surfaceId,
      catalogId: basicCatalogId,
      sendDataModel: true,
    ),
  );
  controller.handleMessage(
    UpdateDataModel(
      surfaceId: surfaceId,
      path: DataPath('/display'),
      value: initialDisplay,
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
            'align': 'stretch',
            'children': ['display', 'row1'],
          },
        ),
        const Component(
          id: 'display',
          type: 'Text',
          properties: {
            'text': {'path': '/display'},
            'variant': 'h2',
          },
        ),
        const Component(
          id: 'row1',
          type: 'Row',
          properties: {
            'children': ['btn7', 'btnClear', 'btnEquals'],
          },
        ),
        const Component(
          id: 'btn7',
          type: 'Button',
          properties: {
            'child': 'label7',
            'action': {
              'event': {
                'name': 'appendDigit',
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
        const Component(
          id: 'btnEquals',
          type: 'Button',
          properties: {
            'child': 'labelEquals',
            'action': {
              'event': {'name': 'equals'},
            },
          },
        ),
        const Component(
          id: 'labelEquals',
          type: 'Text',
          properties: {'text': '='},
        ),
      ],
    ),
  );
}

String _displayValue(SurfaceController controller, String surfaceId) {
  return controller.store
      .getDataModel(surfaceId)
      .getValue<String>(DataPath('/display'))!;
}

ChatMessage _actionMessage({
  required String name,
  required String surfaceId,
  String? sourceComponentId,
  Map<String, dynamic>? context,
}) {
  return ChatMessage.user(
    '',
    parts: [
      UiInteractionPart.create(
        jsonEncode({
          'version': 'v0.9',
          'action': {
            'name': name,
            'surfaceId': surfaceId,
            'sourceComponentId': sourceComponentId ?? 'btn',
            'context': ?context,
          },
        }),
      ),
    ],
  );
}
