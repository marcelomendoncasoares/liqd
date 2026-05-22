import 'package:genui/genui.dart';

/// Merges incremental [UpdateComponents] patches into existing surfaces.
///
/// GenUI replaces whole components on patch; this preserves layout [children]
/// and other properties when the model sends partial follow-up updates.
abstract final class ComponentPatchMerger {
  static List<Component> merge({
    required SurfaceDefinition? existing,
    required List<Component> incoming,
  }) {
    if (existing == null || incoming.isEmpty) {
      return incoming;
    }

    return [
      for (final component in incoming)
        _mergeComponent(
          existing.components[component.id],
          component,
        ),
    ];
  }

  static Component _mergeComponent(Component? prior, Component patch) {
    if (prior == null || prior.type != patch.type) {
      return patch;
    }

    final mergedProps = Map<String, Object?>.from(prior.properties);
    for (final entry in patch.properties.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key == 'children' &&
          value is List &&
          mergedProps['children'] is List) {
        mergedProps['children'] = _mergeChildIds(
          mergedProps['children'] as List,
          value,
        );
      } else if (value != null) {
        mergedProps[key] = value;
      }
    }

    return Component(
      id: patch.id,
      type: patch.type,
      properties: mergedProps,
    );
  }

  static List<String> _mergeChildIds(
    List<dynamic> existing,
    List<dynamic> patch,
  ) {
    final existingIds = existing.map((id) => id.toString()).toList();
    final patchIds = patch.map((id) => id.toString()).toList();

    if (_patchReplacesChildren(existingIds, patchIds)) {
      return patchIds;
    }

    final merged = List<String>.from(existingIds);
    for (final id in patchIds) {
      if (!merged.contains(id)) {
        merged.add(id);
      }
    }
    return merged;
  }

  /// True when the patch lists every existing child (full children update).
  static bool _patchReplacesChildren(
    List<String> existing,
    List<String> patch,
  ) {
    return patch.length >= existing.length && existing.every(patch.contains);
  }
}
