/// Merges incremental A2UI component patches (server-side mirror of client).
abstract final class ComponentPatchMerger {
  static List<Map<String, dynamic>> mergeJsonComponents({
    required Map<String, dynamic>? existingSurface,
    required List<dynamic> incoming,
  }) {
    if (existingSurface == null) {
      return incoming.cast<Map<String, dynamic>>();
    }

    final existingComponents = _existingComponentsById(existingSurface);
    final merged = <Map<String, dynamic>>[];

    for (final item in incoming) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final id = item['id'] as String?;
      if (id == null) {
        merged.add(item);
        continue;
      }
      merged.add(_mergeJsonComponent(existingComponents[id], item));
    }

    return merged;
  }

  static Map<String, Map<String, dynamic>> _existingComponentsById(
    Map<String, dynamic> existingSurface,
  ) {
    final components = existingSurface['components'];
    if (components is List) {
      return {
        for (final item in components)
          if (item is Map<String, dynamic> && item['id'] is String)
            item['id'] as String: item,
      };
    }
    if (components is Map) {
      return components.map(
        (key, value) => MapEntry(
          key.toString(),
          Map.castFrom<dynamic, dynamic, String, dynamic>(value as Map),
        ),
      );
    }
    return {};
  }

  static Map<String, dynamic> _mergeJsonComponent(
    Map<String, dynamic>? prior,
    Map<String, dynamic> patch,
  ) {
    if (prior == null) {
      return patch;
    }

    final priorType = prior['component'];
    final patchType = patch['component'];
    if (priorType != patchType) {
      return patch;
    }

    final merged = Map<String, dynamic>.from(prior)..addAll(patch);

    final priorChildren = prior['children'];
    final patchChildren = patch['children'];
    if (priorChildren is List && patchChildren is List) {
      merged['children'] = _mergeChildIds(priorChildren, patchChildren);
    }

    return merged;
  }

  static List<String> _mergeChildIds(
    List<dynamic> existing,
    List<dynamic> patch,
  ) {
    final existingIds = existing.map((id) => id.toString()).toList();
    final patchIds = patch.map((id) => id.toString()).toList();

    if (patch.length >= existing.length &&
        existingIds.every(patchIds.contains)) {
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
}
