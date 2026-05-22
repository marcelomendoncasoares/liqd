import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

/// Client-side functions that mutate the surface [DataModel] without an LLM.
abstract final class LocalStateFunctions {
  static const systemPromptFragment = '''
**Local interactivity (required):** Button actions MUST use `functionCall`, NOT
`event`. Events are sent to the server; functionCall runs locally on ephemeral
state bound via `sendDataModel: true`.

Available local functions (use `"returnType": "void"` on functionCall):
- `setPath` — `{ "path": "/key", "value": <any> }` sets a data model value.
- `incrementPath` — `{ "path": "/count", "by": 1 }` adds to a number (by optional, default 1).
- `appendToPath` — `{ "path": "/display", "value": "7" }` appends to a string or pushes to an array.
- `togglePath` — `{ "path": "/todos/0/done" }` flips a boolean.
- `pushToPath` — `{ "path": "/todos", "value": { ... } }` pushes an object onto an array.
- `removeFromPath` — `{ "path": "/todos" }` removes the current list item when called
  from a template row (context like `/todos/0`), or pass `"index": 0` for a fixed slot.
- `evaluateMathPath` — `{ "path": "/display" }` evaluates a basic +−*/ expression string and writes the result.

Example counter button:
```json
"action": {"functionCall": {"call": "incrementPath", "args": {"path": "/count"}, "returnType": "void"}}
```

Example todo add button (with `/newTodo` TextField bound via two-way binding):
```json
"action": {"functionCall": {"call": "pushToPath", "args": {"path": "/todos", "value": {"text": {"path": "/newTodo"}, "done": false}}, "returnType": "void"}}
```

Example todo delete button inside a template row at context `/todos/0`:
```json
"action": {"functionCall": {"call": "removeFromPath", "args": {"path": "/todos"}, "returnType": "void"}}
```

Dynamic list rendering — bind children to a data path with a template component id:
```json
"children": {"path": "/todos", "componentId": "todoItem"}
```
''';

  static List<ClientFunction> get all => const [
    SetPathFunction(),
    IncrementPathFunction(),
    AppendToPathFunction(),
    TogglePathFunction(),
    PushToPathFunction(),
    RemoveFromPathFunction(),
    EvaluateMathPathFunction(),
  ];
}

DataPath _pathArg(Object? raw) {
  if (raw is! String || raw.isEmpty) {
    throw ArgumentError('path must be a non-empty string');
  }
  return DataPath(raw.startsWith('/') ? raw : '/$raw');
}

Object? _readAt(ExecutionContext context, DataPath path) {
  return context.getValue<Object?>(path);
}

Object? _resolveBoundValue(Object? value, ExecutionContext context) {
  if (value is Map) {
    if (value.containsKey('path')) {
      return context.getValue<Object?>(_pathArg(value['path']));
    }
    return value.map<String, Object?>(
      (key, nested) => MapEntry(key, _resolveBoundValue(nested, context)),
    );
  }
  if (value is List) {
    return value.map((item) => _resolveBoundValue(item, context)).toList();
  }
  return value;
}

/// Sets a value at an absolute data model [path].
final class SetPathFunction extends SynchronousClientFunction {
  const SetPathFunction();

  @override
  String get name => 'setPath';

  @override
  String get description =>
      'Sets a value at an absolute path in the surface data model.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.empty;

  @override
  Schema get argumentSchema => S.object(
    properties: {
      'path': S.string(description: 'Absolute path, e.g. /count'),
      'value': S.any(description: 'Value to write'),
    },
    required: ['path', 'value'],
  );

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    context.update(_pathArg(args['path']), args['value']);
    return null;
  }
}

/// Increments a numeric value at [path].
final class IncrementPathFunction extends SynchronousClientFunction {
  const IncrementPathFunction();

  @override
  String get name => 'incrementPath';

  @override
  String get description =>
      'Increments a number at the given path by [by] (default 1).';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.empty;

  @override
  Schema get argumentSchema => S.object(
    properties: {
      'path': S.string(),
      'by': S.number(description: 'Optional increment amount, default 1'),
    },
    required: ['path'],
  );

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final path = _pathArg(args['path']);
    final by = (args['by'] as num?) ?? 1;
    final current = _readAt(context, path);
    final next = switch (current) {
      num value => value + by,
      null => by,
      _ => by,
    };
    context.update(path, next);
    return null;
  }
}

/// Appends to a string or pushes onto an array at [path].
final class AppendToPathFunction extends SynchronousClientFunction {
  const AppendToPathFunction();

  @override
  String get name => 'appendToPath';

  @override
  String get description =>
      'Appends to a string at path, or pushes a value onto an array at path.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.empty;

  @override
  Schema get argumentSchema => S.object(
    properties: {
      'path': S.string(),
      'value': S.any(),
    },
    required: ['path', 'value'],
  );

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final path = _pathArg(args['path']);
    final value = args['value'];
    final current = _readAt(context, path);

    if (current is List) {
      context.update(path, [...current, value]);
      return null;
    }

    final currentText = current?.toString() ?? '';
    final piece = value?.toString() ?? '';
    context.update(path, _appendText(currentText, piece));
    return null;
  }

  static String _appendText(String current, String piece) {
    if (piece == '.') {
      final segment = current.split(RegExp(r'[+\-*/]')).last;
      if (segment.contains('.')) {
        return current;
      }
      if (RegExp(r'[+\-*/]$').hasMatch(current)) {
        return '${current}0.';
      }
      return current == '0' ? '0.' : '$current.';
    }

    if (piece.length == 1 &&
        RegExp(r'^\d$').hasMatch(piece) &&
        current == '0') {
      return piece;
    }

    if (piece.length == 1 && RegExp(r'^[+\-*/]$').hasMatch(piece)) {
      if (current.isEmpty || current == '0') {
        return current;
      }
      final trimmed = RegExp(r'[+\-*/]$').hasMatch(current)
          ? current.substring(0, current.length - 1)
          : current;
      return '$trimmed$piece';
    }

    return current + piece;
  }
}

/// Toggles a boolean at [path].
final class TogglePathFunction extends SynchronousClientFunction {
  const TogglePathFunction();

  @override
  String get name => 'togglePath';

  @override
  String get description => 'Toggles a boolean value at the given path.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.empty;

  @override
  Schema get argumentSchema =>
      S.object(properties: {'path': S.string()}, required: ['path']);

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final path = _pathArg(args['path']);
    final current = _readAt(context, path);
    context.update(path, current != true);
    return null;
  }
}

/// Pushes a value onto an array at [path], creating the array if needed.
final class PushToPathFunction extends SynchronousClientFunction {
  const PushToPathFunction();

  @override
  String get name => 'pushToPath';

  @override
  String get description => 'Pushes a value onto an array at the given path.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.empty;

  @override
  Schema get argumentSchema => S.object(
    properties: {
      'path': S.string(),
      'value': S.any(),
    },
    required: ['path', 'value'],
  );

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final path = _pathArg(args['path']);
    final value = _resolveBoundValue(args['value'], context);
    final current = _readAt(context, path);
    final list = switch (current) {
      List<Object?> values => List<Object?>.from(values),
      null => <Object?>[],
      _ => <Object?>[current],
    };
    list.add(value);
    context.update(path, list);
    return null;
  }
}

/// Removes an element from an array at [path].
///
/// When [index] is omitted, infers the index from [ExecutionContext.path]
/// (e.g. context `/todos/2` with array path `/todos` removes index 2).
final class RemoveFromPathFunction extends SynchronousClientFunction {
  const RemoveFromPathFunction();

  @override
  String get name => 'removeFromPath';

  @override
  String get description =>
      'Removes an element from an array. Uses the current template context '
      'index when index is omitted.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.empty;

  @override
  Schema get argumentSchema => S.object(
    properties: {
      'path': S.string(description: 'Array path, e.g. /todos'),
      'index': S.integer(
        description: 'Optional index. Omit inside list templates.',
      ),
    },
    required: ['path'],
  );

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final arrayPath = _pathArg(args['path']);
    final index = _resolveRemoveIndex(args['index'], arrayPath, context);
    if (index == null) {
      return null;
    }

    final current = _readAt(context, arrayPath);
    if (current is! List) {
      return null;
    }
    if (index < 0 || index >= current.length) {
      return null;
    }

    final list = List<Object?>.from(current)..removeAt(index);
    context.update(arrayPath, list);
    return null;
  }

  static int? _resolveRemoveIndex(
    Object? rawIndex,
    DataPath arrayPath,
    ExecutionContext context,
  ) {
    if (rawIndex is num) {
      return rawIndex.toInt();
    }

    final contextPath = context.path.toString();
    final arrayPathString = arrayPath.toString();
    if (contextPath.startsWith('$arrayPathString/')) {
      final suffix = contextPath.substring(arrayPathString.length + 1);
      final segment = suffix.split('/').first;
      return int.tryParse(segment);
    }

    return null;
  }
}

/// Evaluates a basic arithmetic expression stored as a string at [path].
final class EvaluateMathPathFunction extends SynchronousClientFunction {
  const EvaluateMathPathFunction();

  @override
  String get name => 'evaluateMathPath';

  @override
  String get description =>
      'Evaluates +, -, *, / arithmetic on the string at path and writes the result.';

  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.empty;

  @override
  Schema get argumentSchema =>
      S.object(properties: {'path': S.string()}, required: ['path']);

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final path = _pathArg(args['path']);
    var expression = _readAt(context, path)?.toString() ?? '';
    expression = expression.replaceAll(RegExp(r'[+\-*/]+$'), '');
    if (expression.isEmpty) {
      return null;
    }

    final result = _evaluateExpression(expression);
    if (result == null) {
      context.update(path, 'Error');
      return null;
    }
    final formatted = result is int || result == result.roundToDouble()
        ? result.round().toString()
        : result.toString();
    context.update(path, formatted);
    return null;
  }

  static num? _evaluateExpression(String expression) {
    final sanitized = expression.replaceAll(' ', '');
    if (sanitized.isEmpty || !RegExp(r'^[\d.+\-*/]+$').hasMatch(sanitized)) {
      return null;
    }

    final tokens = <Object>[];
    final buffer = StringBuffer();
    for (var i = 0; i < sanitized.length; i++) {
      final char = sanitized[i];
      if (RegExp(r'[\d.]').hasMatch(char)) {
        buffer.write(char);
        continue;
      }
      if (buffer.isNotEmpty) {
        final number = num.tryParse(buffer.toString());
        if (number == null) {
          return null;
        }
        tokens.add(number);
        buffer.clear();
      }
      if (RegExp(r'^[+\-*/]$').hasMatch(char)) {
        tokens.add(char);
      } else {
        return null;
      }
    }
    if (buffer.isNotEmpty) {
      final number = num.tryParse(buffer.toString());
      if (number == null) {
        return null;
      }
      tokens.add(number);
    }
    if (tokens.isEmpty || tokens.first is! num) {
      return null;
    }

    var result = tokens.first as num;
    for (var i = 1; i < tokens.length; i += 2) {
      if (i + 1 >= tokens.length) {
        return null;
      }
      final op = tokens[i] as String;
      final next = tokens[i + 1] as num;
      final computed = switch (op) {
        '+' => result + next,
        '-' => result - next,
        '*' => result * next,
        '/' => next == 0 ? null : result / next,
        _ => null,
      };
      if (computed == null) {
        return null;
      }
      result = computed;
    }
    return result;
  }
}
