import 'dart:convert';

/// Merges [data] into a Stac JSON [template], replacing `{{key}}` placeholders.
Map<String, dynamic> mergeStacTemplate(
  Map<String, dynamic> template,
  Map<String, dynamic> data,
) {
  final encoded = jsonEncode(template);
  var result = encoded;
  for (final entry in data.entries) {
    final placeholder = '{{${entry.key}}}';
    if (result.contains(placeholder)) {
      if (entry.value is String) {
        result = result.replaceAll(placeholder, entry.value as String);
      } else {
        result = result.replaceAll(
          '"$placeholder"',
          jsonEncode(entry.value),
        );
        result = result.replaceAll(placeholder, jsonEncode(entry.value));
      }
    }
  }
  return jsonDecode(result) as Map<String, dynamic>;
}

/// Deep-merges [data] values into [template] where keys match.
Map<String, dynamic> deepMergeStacTemplate(
  Map<String, dynamic> template,
  Map<String, dynamic> data,
) {
  final merged = mergeStacTemplate(template, data);
  return _substitutePlaceholders(merged, data);
}

Map<String, dynamic> _substitutePlaceholders(
  Map<String, dynamic> node,
  Map<String, dynamic> data,
) {
  final result = <String, dynamic>{};
  for (final entry in node.entries) {
    result[entry.key] = _substituteValue(entry.value, data);
  }
  return result;
}

dynamic _substituteValue(dynamic value, Map<String, dynamic> data) {
  if (value is String && value.startsWith('{{') && value.endsWith('}}')) {
    final key = value.substring(2, value.length - 2);
    return data[key] ?? value;
  }
  if (value is Map) {
    return _substitutePlaceholders(
      value.cast<String, dynamic>(),
      data,
    );
  }
  if (value is List) {
    return value.map((item) => _substituteValue(item, data)).toList();
  }
  return value;
}

/// Extracts GenUI component parameters from catalog item data.
Map<String, dynamic> extractComponentData(Object data) {
  if (data is! Map) {
    return {};
  }
  final map = Map<String, dynamic>.from(data.cast<String, dynamic>());
  map.remove('component');
  return map;
}

/// Snapshot helper for surface export.
class SurfaceControllerSnapshot {
  const SurfaceControllerSnapshot({
    required this.surfaces,
    this.messages = const [],
  });

  final Map<String, dynamic> surfaces;
  final List<Map<String, String>> messages;
}

/// Serializes active GenUI surfaces for persistence.
Map<String, dynamic> exportSurfaceState(SurfaceControllerSnapshot snapshot) {
  return {
    'surfaces': snapshot.surfaces,
    if (snapshot.messages.isNotEmpty) 'messages': snapshot.messages,
  };
}
