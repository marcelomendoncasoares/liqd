import '../generated/protocol.dart';

/// Validates Stac JSON widget definitions before persistence.
abstract final class StacValidator {
  static const _allowedTypes = {
    'scaffold',
    'appBar',
    'text',
    'column',
    'row',
    'center',
    'padding',
    'sizedBox',
    'elevatedButton',
    'textButton',
    'filledButton',
    'outlinedButton',
    'textField',
    'icon',
    'iconButton',
    'card',
    'listTile',
    'divider',
    'spacer',
    'expanded',
    'flexible',
    'container',
    'align',
    'singleChildScrollView',
    'listView',
    'gridView',
    'image',
    'checkbox',
    'switch',
    'slider',
    'circularProgressIndicator',
    'linearProgressIndicator',
  };

  static WidgetValidationResult validate(Map<String, dynamic> stacJson) {
    final errors = <String>[];

    if (!stacJson.containsKey('type')) {
      errors.add('Missing required "type" field.');
      return WidgetValidationResult(valid: false, errors: errors);
    }

    final type = stacJson['type'];
    if (type is! String || type.isEmpty) {
      errors.add('"type" must be a non-empty string.');
    } else if (!_allowedTypes.contains(type)) {
      errors.add('Unsupported Stac widget type: $type');
    }

    _validateNode(stacJson, errors, path: 'root');

    return WidgetValidationResult(
      valid: errors.isEmpty,
      errors: errors.isEmpty ? null : errors,
      stacJson: errors.isEmpty ? stacJson : null,
    );
  }

  static void _validateNode(
    dynamic node,
    List<String> errors, {
    required String path,
  }) {
    if (node is! Map) {
      return;
    }

    final map = node.cast<String, dynamic>();
    final type = map['type'];
    if (type is String && type.isNotEmpty && !_allowedTypes.contains(type)) {
      errors.add('Unsupported Stac widget type at $path: $type');
    }

    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map) {
        _validateNode(value, errors, path: '$path.${entry.key}');
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          _validateNode(value[i], errors, path: '$path.${entry.key}[$i]');
        }
      }
    }
  }
}
