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
