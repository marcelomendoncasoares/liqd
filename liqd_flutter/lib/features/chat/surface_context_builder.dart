import 'dart:convert';

import 'package:genui/genui.dart';

/// Builds JSON context describing active surfaces for follow-up GenUI requests.
String? buildExistingSurfacesJson(SurfaceController? controller) {
  if (controller == null || controller.activeSurfaceIds.isEmpty) {
    return null;
  }

  final surfaces = <String, dynamic>{};
  final dataModels = <String, dynamic>{};

  for (final surfaceId in controller.activeSurfaceIds) {
    final definition = controller.registry.getSurface(surfaceId);
    if (definition != null) {
      surfaces[surfaceId] = definition.toJson();
    }

    final root = controller.store
        .getDataModel(surfaceId)
        .getValue<Map<String, Object?>>(DataPath.root);
    if (root != null && root.isNotEmpty) {
      dataModels[surfaceId] = root;
    }
  }

  if (surfaces.isEmpty) {
    return null;
  }

  return jsonEncode({
    'surfaces': surfaces,
    if (dataModels.isNotEmpty) 'dataModels': dataModels,
  });
}
