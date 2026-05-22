/// Repairs common LLM component mistakes before GenUI validation/rendering.
abstract final class ComponentNormalizer {
  static List<Map<String, dynamic>> normalizeJsonList(
    List<dynamic> components,
  ) {
    final normalized = <Map<String, dynamic>>[];
    final extras = <Map<String, dynamic>>[];

    for (final item in components) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final type = item['component'] as String?;
      if (type == 'Button') {
        normalized.addAll(_normalizeButtonJson(item, extras));
      } else if (type == 'Card') {
        normalized.addAll(_normalizeCardJson(item, extras));
      } else if (type == 'CheckBox') {
        normalized.add(_normalizeCheckBoxJson(item));
      } else if (type == 'Text') {
        normalized.add(_normalizeTextJson(item));
      } else {
        normalized.add(item);
      }
    }

    return [...normalized, ...extras];
  }

  static List<Map<String, dynamic>> _normalizeButtonJson(
    Map<String, dynamic> component,
    List<Map<String, dynamic>> extras,
  ) {
    final child = component['child'];
    if (child is String && child.isNotEmpty) {
      return [component];
    }

    final label = _extractInlineLabel(component);
    if (label == null) {
      return [component];
    }

    final id = component['id'] as String? ?? 'button';
    final labelId = '${id}Label';
    extras.add({
      'id': labelId,
      'component': 'Text',
      'text': label,
    });

    final repaired = Map<String, dynamic>.from(component)
      ..remove('label')
      ..remove('text')
      ..['child'] = labelId;
    return [repaired];
  }

  static List<Map<String, dynamic>> _normalizeCardJson(
    Map<String, dynamic> component,
    List<Map<String, dynamic>> extras,
  ) {
    final child = component['child'];
    if (child is String && child.isNotEmpty) {
      return [component];
    }

    final children = component['children'];
    if (children is List && children.isNotEmpty) {
      final first = children.first;
      if (first is String) {
        final repaired = Map<String, dynamic>.from(component)
          ..remove('children')
          ..['child'] = first;
        return [repaired];
      }
    }

    final label = _extractInlineLabel(component);
    if (label == null) {
      return [component];
    }

    final id = component['id'] as String? ?? 'card';
    final labelId = '${id}Child';
    extras.add({
      'id': labelId,
      'component': 'Text',
      'text': label,
    });

    final repaired = Map<String, dynamic>.from(component)
      ..remove('label')
      ..remove('text')
      ..remove('children')
      ..['child'] = labelId;
    return [repaired];
  }

  static Map<String, dynamic> _normalizeCheckBoxJson(
    Map<String, dynamic> component,
  ) {
    final repaired = Map<String, dynamic>.from(component);
    final label = repaired['label'];
    if (label == null || (label is String && label.isEmpty)) {
      repaired['label'] = 'Done';
    }
    if (repaired['value'] == null) {
      repaired['value'] = {'path': 'done'};
    }
    return repaired;
  }

  static Map<String, dynamic> _normalizeTextJson(
    Map<String, dynamic> component,
  ) {
    final repaired = Map<String, dynamic>.from(component);
    final text = repaired['text'];
    if (text == null) {
      repaired['text'] = {'path': 'text'};
      return repaired;
    }
    if (text is Map && text['path'] is String) {
      repaired['text'] = _maybeRelativePath(text['path'] as String);
    }
    return repaired;
  }

  /// Rewrites mistaken template paths like `/text` to relative `text`.
  static Object _maybeRelativePath(String path) {
    if (!path.startsWith('/') || path == '/') {
      return {'path': path};
    }
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length == 1) {
      return {'path': segments.first};
    }
    return {'path': path};
  }

  static String? _extractInlineLabel(Map<String, dynamic> component) {
    for (final key in ['label', 'text', 'title']) {
      final value = component[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
