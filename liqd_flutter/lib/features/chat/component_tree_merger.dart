import 'package:genui/genui.dart';

/// Links components that exist in the registry but are unreachable from [root].
abstract final class ComponentTreeMerger {
  /// Returns true when orphans were linked into the component tree.
  static bool linkOrphans(SurfaceController controller, String surfaceId) {
    final definition = controller.registry.getSurface(surfaceId);
    if (definition == null || !definition.components.containsKey('root')) {
      return false;
    }

    final reachable = _collectReachable(definition, 'root');
    final orphans = definition.components.keys
        .where((id) => id != 'root' && !reachable.contains(id))
        .toList();
    if (orphans.isEmpty) {
      return false;
    }

    final root = definition.components['root']!;
    final rootChildren = _childIds(root);
    final updates = <Component>[];
    var changed = false;

    final layoutOrphans = <String>[];
    final buttonOrphans = <String>[];

    for (final id in orphans) {
      final type = definition.components[id]!.type;
      if (type == 'Row' || type == 'Column') {
        layoutOrphans.add(id);
      } else if (type == 'Button') {
        buttonOrphans.add(id);
      }
    }

    for (final id in layoutOrphans) {
      if (!rootChildren.contains(id)) {
        rootChildren.add(id);
        changed = true;
      }
    }

    if (buttonOrphans.isNotEmpty) {
      final targetRowId = _lastRowId(definition, rootChildren);
      if (targetRowId != null) {
        final row = definition.components[targetRowId]!;
        final rowChildren = _childIds(row);
        for (final buttonId in buttonOrphans) {
          if (!rowChildren.contains(buttonId)) {
            rowChildren.add(buttonId);
            changed = true;
          }
          final labelId = definition.components[buttonId]!.properties['child'];
          if (labelId is String &&
              definition.components.containsKey(labelId) &&
              !rowChildren.contains(labelId) &&
              !reachable.contains(labelId)) {
            rowChildren.add(labelId);
            changed = true;
          }
        }
        updates.add(
          Component(
            id: row.id,
            type: row.type,
            properties: {...row.properties, 'children': rowChildren},
          ),
        );
      } else if (layoutOrphans.isEmpty) {
        for (final buttonId in buttonOrphans) {
          if (!rootChildren.contains(buttonId)) {
            rootChildren.add(buttonId);
            changed = true;
          }
        }
      }
    }

    for (final id in orphans) {
      if (layoutOrphans.contains(id) ||
          buttonOrphans.contains(id) ||
          definition.components[id]!.type == 'Text') {
        continue;
      }
      if (!rootChildren.contains(id)) {
        rootChildren.add(id);
        changed = true;
      }
    }

    if (!changed) {
      return false;
    }

    updates.add(
      Component(
        id: root.id,
        type: root.type,
        properties: {...root.properties, 'children': rootChildren},
      ),
    );

    for (final id in orphans) {
      updates.add(definition.components[id]!);
      final component = definition.components[id]!;
      if (component.type == 'Button') {
        final labelId = component.properties['child'];
        if (labelId is String && definition.components.containsKey(labelId)) {
          updates.add(definition.components[labelId]!);
        }
      }
    }

    controller.handleMessage(
      UpdateComponents(surfaceId: surfaceId, components: updates),
    );
    return true;
  }

  static Set<String> _collectReachable(
    SurfaceDefinition definition,
    String rootId,
  ) {
    final reachable = <String>{};
    void visit(String id) {
      if (!reachable.add(id)) {
        return;
      }
      final component = definition.components[id];
      if (component == null) {
        return;
      }
      for (final childId in _childIds(component)) {
        visit(childId);
      }
      final buttonChild = component.properties['child'];
      if (buttonChild is String) {
        visit(buttonChild);
      }
    }

    visit(rootId);
    return reachable;
  }

  static List<String> _childIds(Component component) {
    final children = component.properties['children'];
    if (children is List) {
      return children.map((child) => child.toString()).toList();
    }
    return [];
  }

  static String? _lastRowId(
    SurfaceDefinition definition,
    List<String> rootChildren,
  ) {
    for (final childId in rootChildren.reversed) {
      if (definition.components[childId]?.type == 'Row') {
        return childId;
      }
    }
    return null;
  }
}
