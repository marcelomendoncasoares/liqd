/// Prepares LLM-generated Stac JSON for embedding in the app builder preview.
Map<String, dynamic> normalizeStacForPreview(Map<String, dynamic> stacJson) {
  return _normalizeNode(stacJson);
}

Map<String, dynamic> _normalizeNode(Map<String, dynamic> node) {
  final type = node['type'];
  if (type == 'setValue') {
    final child = node['child'];
    if (child is Map<String, dynamic>) {
      return {
        ...node,
        'child': _normalizeNode(child),
      };
    }
    return node;
  }

  if (type == 'scaffold') {
    final body = node['body'];
    if (body is Map<String, dynamic>) {
      return _normalizeNode(body);
    }
    return {'type': 'column', 'children': <Map<String, dynamic>>[]};
  }

  return node;
}
