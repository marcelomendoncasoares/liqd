import 'package:genui/genui.dart';

/// Repairs common LLM component mistakes before GenUI validation/rendering.
abstract final class ComponentNormalizer {
  static List<Component> normalize(List<Component> components) {
    final normalized = <Component>[];
    final extras = <Component>[];

    for (final component in components) {
      switch (component.type) {
        case 'Button':
          normalized.add(_normalizeButton(component, extras));
        case 'Card':
          normalized.add(_normalizeCard(component, extras));
        case 'CheckBox':
          normalized.add(_normalizeCheckBox(component));
        case 'Text':
          normalized.add(_normalizeText(component));
        default:
          normalized.add(component);
      }
    }

    return [...normalized, ...extras];
  }

  static Component _normalizeButton(
    Component component,
    List<Component> extras,
  ) {
    final child = component.properties['child'];
    if (child is String && child.isNotEmpty) {
      return component;
    }

    final label = _extractInlineLabel(component.properties);
    if (label == null) {
      return component;
    }

    final labelId = '${component.id}Label';
    extras.add(
      Component(
        id: labelId,
        type: 'Text',
        properties: {'text': label},
      ),
    );

    final props = Map<String, Object?>.from(component.properties)
      ..remove('label')
      ..remove('text')
      ..['child'] = labelId;
    return Component(
      id: component.id,
      type: component.type,
      properties: props,
    );
  }

  static Component _normalizeCard(Component component, List<Component> extras) {
    final child = component.properties['child'];
    if (child is String && child.isNotEmpty) {
      return component;
    }

    final children = component.properties['children'];
    if (children is List && children.isNotEmpty) {
      final first = children.first;
      if (first is String) {
        final props = Map<String, Object?>.from(component.properties)
          ..remove('children')
          ..['child'] = first;
        return Component(
          id: component.id,
          type: component.type,
          properties: props,
        );
      }
    }

    final label = _extractInlineLabel(component.properties);
    if (label == null) {
      return component;
    }

    final labelId = '${component.id}Child';
    extras.add(
      Component(
        id: labelId,
        type: 'Text',
        properties: {'text': label},
      ),
    );

    final props = Map<String, Object?>.from(component.properties)
      ..remove('label')
      ..remove('text')
      ..remove('children')
      ..['child'] = labelId;
    return Component(
      id: component.id,
      type: component.type,
      properties: props,
    );
  }

  static Component _normalizeCheckBox(Component component) {
    final props = Map<String, Object?>.from(component.properties);
    final label = props['label'];
    if (label == null || (label is String && label.isEmpty)) {
      props['label'] = 'Done';
    }
    props.putIfAbsent('value', () => {'path': 'done'});
    return Component(
      id: component.id,
      type: component.type,
      properties: props,
    );
  }

  static Component _normalizeText(Component component) {
    final props = Map<String, Object?>.from(component.properties);
    final text = props['text'];
    if (text == null) {
      props['text'] = {'path': 'text'};
      return Component(
        id: component.id,
        type: component.type,
        properties: props,
      );
    }
    if (text is Map && text['path'] is String) {
      props['text'] = _maybeRelativePath(text['path'] as String);
    }
    return Component(
      id: component.id,
      type: component.type,
      properties: props,
    );
  }

  static Map<String, String> _maybeRelativePath(String path) {
    if (!path.startsWith('/') || path == '/') {
      return {'path': path};
    }
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.length == 1) {
      return {'path': segments.first};
    }
    return {'path': path};
  }

  static String? _extractInlineLabel(Map<String, Object?> properties) {
    for (final key in ['label', 'text', 'title']) {
      final value = properties[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}
