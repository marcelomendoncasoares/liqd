import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:liqd_flutter/features/catalog/local_state_functions.dart';

void main() {
  group('LocalStateFunctions', () {
    late SurfaceController controller;
    const surfaceId = 'main';

    setUp(() {
      controller = SurfaceController(
        catalogs: [
          BasicCatalogItems.asCatalog().copyWith(
            newFunctions: LocalStateFunctions.all,
          ),
        ],
      );
      controller.handleMessage(
        CreateSurface(
          surfaceId: surfaceId,
          catalogId: basicCatalogId,
          sendDataModel: true,
        ),
      );
    });

    tearDown(() => controller.dispose());

    DataModel model() => controller.store.getDataModel(surfaceId);

    ExecutionContext context([String path = '/']) {
      return DataContext(model(), DataPath(path));
    }

    test('incrementPath adds to a counter', () {
      model().update(DataPath('/count'), 2);

      const IncrementPathFunction().executeSync(
        {'path': '/count'},
        context(),
      );

      expect(model().getValue<num>(DataPath('/count')), 3);
    });

    test('appendToPath appends digits to a display string', () {
      model().update(DataPath('/display'), '12');

      const AppendToPathFunction().executeSync(
        {'path': '/display', 'value': '3'},
        context(),
      );

      expect(model().getValue<String>(DataPath('/display')), '123');
    });

    test('pushToPath adds a todo item', () {
      model().update(DataPath('/todos'), <Object?>[]);
      model().update(DataPath('/newTodo'), 'Buy milk');

      const PushToPathFunction().executeSync(
        {
          'path': '/todos',
          'value': {'text': 'Buy milk', 'done': false},
        },
        context(),
      );

      final todos = model().getValue<List<Object?>>(DataPath('/todos'));
      expect(todos, hasLength(1));
      expect(todos!.first, {'text': 'Buy milk', 'done': false});
    });

    test('evaluateMathPath evaluates an expression at path', () {
      model().update(DataPath('/display'), '12+3');

      const EvaluateMathPathFunction().executeSync(
        {'path': '/display'},
        context(),
      );

      expect(model().getValue<String>(DataPath('/display')), '15');
    });

    test('togglePath flips a boolean', () {
      model().update(DataPath('/todos/0/done'), false);

      const TogglePathFunction().executeSync(
        {'path': '/todos/0/done'},
        context(),
      );

      expect(model().getValue<bool>(DataPath('/todos/0/done')), isTrue);
    });

    test('removeFromPath removes item using template context index', () {
      model().update(DataPath('/todos'), [
        {'text': 'One'},
        {'text': 'Two'},
      ]);

      const RemoveFromPathFunction().executeSync(
        {'path': '/todos'},
        context('/todos/1'),
      );

      final todos = model().getValue<List<Object?>>(DataPath('/todos'));
      expect(todos, hasLength(1));
      expect(todos!.first, {'text': 'One'});
    });

    test('removeFromPath removes item at explicit index', () {
      model().update(DataPath('/todos'), [
        {'text': 'One'},
        {'text': 'Two'},
      ]);

      const RemoveFromPathFunction().executeSync(
        {'path': '/todos', 'index': 0},
        context(),
      );

      final todos = model().getValue<List<Object?>>(DataPath('/todos'));
      expect(todos, hasLength(1));
      expect(todos!.first, {'text': 'Two'});
    });
    test('pushToPath resolves nested path bindings in value', () {
      model().update(DataPath('/todos'), <Object?>[]);
      model().update(DataPath('/todoInput'), 'Buy milk');

      const PushToPathFunction().executeSync(
        {
          'path': '/todos',
          'value': {
            'task': {'path': '/todoInput'},
            'done': false,
          },
        },
        context(),
      );

      final todos = model().getValue<List<Object?>>(DataPath('/todos'));
      expect(todos!.first, {'task': 'Buy milk', 'done': false});
    });
  });
}
