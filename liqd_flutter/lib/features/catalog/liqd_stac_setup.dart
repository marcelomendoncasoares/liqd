import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stac/stac.dart';

import 'reactive_stac_host.dart';
import 'stac_preview_normalizer.dart';

/// Registers Liqd-specific Stac extensions (reactive setValue actions/widgets).
abstract final class LiqdStacSetup {
  static void register() {
    StacRegistry.instance
      ..register(const LiqdReactiveSetValueParser(), true)
      ..registerAction(const LiqdNotifySetValueActionParser(), true);
  }
}

/// Initializes registry values once and rebuilds when values change.
class LiqdReactiveSetValueParser extends StacParser<StacSetValue> {
  const LiqdReactiveSetValueParser();

  @override
  String get type => WidgetType.setValue.name;

  @override
  StacSetValue getModel(Map<String, dynamic> json) =>
      StacSetValue.fromJson(json);

  @override
  Widget parse(BuildContext context, StacSetValue model) {
    return _LiqdReactiveSetValueWidget(model: model);
  }
}

class _LiqdReactiveSetValueWidget extends StatefulWidget {
  const _LiqdReactiveSetValueWidget({required this.model});

  final StacSetValue model;

  @override
  State<_LiqdReactiveSetValueWidget> createState() =>
      _LiqdReactiveSetValueWidgetState();
}

class _LiqdReactiveSetValueWidgetState
    extends State<_LiqdReactiveSetValueWidget> {
  final StacRegistry _registry = StacRegistry.instance;

  @override
  void initState() {
    super.initState();
    for (final value in widget.model.values) {
      final key = value['key'] as String;
      if (_registry.getValue(key) == null) {
        _registry.setValue(key, value['value']);
      }
    }
  }

  void markRegistryChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.model.child;
    if (child == null) {
      return const SizedBox.shrink();
    }

    final resolvedJson = _resolveChildJson(child.toJson());
    final normalized = normalizeStacForPreview(resolvedJson);
    return Stac.fromJson(normalized, context) ?? const SizedBox.shrink();
  }

  Map<String, dynamic> _resolveChildJson(Map<String, dynamic> childJson) {
    return _resolveVariables(childJson, _registry) as Map<String, dynamic>;
  }
}

/// Writes to [StacRegistry], evaluates simple expressions, and triggers rebuild.
class LiqdNotifySetValueActionParser
    extends StacActionParser<StacSetValueAction> {
  const LiqdNotifySetValueActionParser();

  @override
  String get actionType => ActionType.setValue.name;

  @override
  StacSetValueAction getModel(Map<String, dynamic> json) =>
      StacSetValueAction.fromJson(json);

  @override
  FutureOr<dynamic> onCall(
    BuildContext context,
    StacSetValueAction model,
  ) async {
    final registry = StacRegistry.instance;
    for (final value in model.values ?? []) {
      final key = value['key'] as String;
      registry.setValue(key, _resolveSetValue(value['value'], registry));
    }
    final setValueState = context
        .findAncestorStateOfType<_LiqdReactiveSetValueWidgetState>();
    if (setValueState != null) {
      setValueState.markRegistryChanged();
    } else {
      ReactiveStacHost.notifyRegistryChanged(context);
    }
    return model.action?.parse(context);
  }
}

dynamic _resolveSetValue(dynamic value, StacRegistry registry) {
  if (value is! String) {
    return value;
  }

  final resolved = _resolveVariables(value, registry);
  if (resolved is! String) {
    return resolved;
  }

  if (!RegExp(r'[+\-*/%]').hasMatch(resolved)) {
    return resolved;
  }

  final withRegistry = resolved.replaceAllMapped(
    RegExp(r'(?<![.\w])(\w+)(?![.\w])'),
    (match) {
      final name = match.group(1)!;
      if (name == 'true' || name == 'false' || name == 'null') {
        return name;
      }
      final registryValue = registry.getValue(name);
      return registryValue?.toString() ?? name;
    },
  );

  return _evaluateMath(withRegistry) ?? withRegistry;
}

dynamic _resolveVariables(dynamic json, StacRegistry registry) {
  if (json is String) {
    return json.replaceAllMapped(RegExp(r'{{(.*?)}}'), (match) {
      final variableName = match.group(1)?.trim();
      if (variableName == null || variableName.isEmpty) {
        return match.group(0) ?? '';
      }
      final value = registry.getValue(variableName);
      return value?.toString() ?? match.group(0) ?? '';
    });
  }
  if (json is Map<String, dynamic>) {
    return json.map(
      (key, value) => MapEntry(key, _resolveVariables(value, registry)),
    );
  }
  if (json is List) {
    return json.map((item) => _resolveVariables(item, registry)).toList();
  }
  return json;
}

num? _evaluateMath(String expression) {
  try {
    if (expression.contains('+')) {
      final parts = expression.split('+');
      return parts.fold<num>(0, (sum, part) {
        final value = num.tryParse(part.trim());
        return value != null ? sum + value : sum;
      });
    }
    return num.tryParse(expression.trim());
  } on Object {
    return null;
  }
}
