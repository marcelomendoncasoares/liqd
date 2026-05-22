import 'dart:convert';

import 'package:genui/genui.dart';

/// Builds JSON context describing active surfaces for follow-up GenUI requests.
///
/// Uses A2UI-friendly shape: flat [components] arrays and per-surface [dataModel].
String? buildExistingSurfacesJson(SurfaceController? controller) {
  if (controller == null || controller.activeSurfaceIds.isEmpty) {
    return null;
  }

  final surfaces = <String, dynamic>{};

  for (final surfaceId in controller.activeSurfaceIds) {
    final definition = controller.registry.getSurface(surfaceId);
    if (definition == null) {
      continue;
    }

    final surface = <String, dynamic>{
      'surfaceId': definition.surfaceId,
      'catalogId': definition.catalogId,
      'components': definition.components.values
          .map((component) => component.toJson())
          .toList(),
    };

    final dataModel = _readDataModelRoot(controller, surfaceId);
    if (dataModel != null && dataModel.isNotEmpty) {
      surface['dataModel'] = dataModel;
    }

    surfaces[surfaceId] = surface;
  }

  if (surfaces.isEmpty) {
    return null;
  }

  return jsonEncode({'surfaces': surfaces});
}

Map<String, dynamic>? _readDataModelRoot(
  SurfaceController controller,
  String surfaceId,
) {
  final root = controller.store
      .getDataModel(surfaceId)
      .getValue<Map<String, Object?>>(DataPath.root);
  if (root == null || root.isEmpty) {
    return null;
  }
  return root.map((key, value) => MapEntry(key.toString(), value));
}

/// Restores ephemeral data model values from saved or context JSON.
void restoreDataModelForSurface(
  SurfaceController controller,
  String surfaceId,
  Map<String, dynamic>? dataModel,
) {
  if (dataModel == null || dataModel.isEmpty) {
    return;
  }

  for (final entry in dataModel.entries) {
    final path = entry.key.startsWith('/') ? entry.key : '/${entry.key}';
    controller.handleMessage(
      UpdateDataModel(
        surfaceId: surfaceId,
        path: DataPath(path),
        value: entry.value,
      ),
    );
  }
}

/// Reads a per-surface data model map from saved surface JSON.
Map<String, dynamic>? dataModelFromSurfaceJson(
  Map<String, dynamic> surfaceJson,
) {
  final dataModel = surfaceJson['dataModel'];
  if (dataModel is Map<String, dynamic>) {
    return dataModel;
  }
  if (dataModel is Map) {
    return dataModel.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  return null;
}
