import 'dart:convert';

import 'package:json_schema_builder/json_schema_builder.dart';

import 'catalog_manifest.dart';
import 'constants.dart';

/// Result of validating a single A2UI message.
final class A2uiValidationResult {
  const A2uiValidationResult.valid(this.message)
    : errors = const [],
      messageJson = null,
      skipped = false;

  const A2uiValidationResult.invalid(this.errors, {this.messageJson})
    : message = null,
      skipped = false;

  /// Message is intentionally ignored (e.g. redundant createSurface).
  const A2uiValidationResult.skip()
    : message = null,
      errors = const [],
      messageJson = null,
      skipped = true;

  final Map<String, dynamic>? message;
  final List<String> errors;
  final String? messageJson;
  final bool skipped;

  bool get isValid => errors.isEmpty && message != null;
}

/// Validates A2UI messages against a [CatalogManifest] schema and Liqd rules.
final class A2uiValidator {
  A2uiValidator(this._manifest)
    : _schema = Schema.fromMap(
        _manifest.messageSchemaJson.cast<String, Object?>(),
      );

  final CatalogManifest _manifest;
  final Schema _schema;

  final _knownSurfaces = <String>{};
  final _existingSurfaceIds = <String>{};

  /// Marks surfaces that already exist on the client (edit mode).
  void seedExistingSurfaces(Iterable<String> surfaceIds) {
    _existingSurfaceIds.addAll(surfaceIds);
    _knownSurfaces.addAll(surfaceIds);
  }

  /// Validates raw JSON text extracted from the model stream.
  A2uiValidationResult validateJson(String rawJson) {
    final decoded = _decodeJson(rawJson);
    if (decoded == null) {
      return A2uiValidationResult.invalid([
        'Invalid JSON: malformed payload',
      ], messageJson: rawJson);
    }

    return validateMessageDry(decoded);
  }

  /// Structural validation without mutating surface state.
  A2uiValidationResult validateMessageDry(Map<String, dynamic> decoded) {
    final messageType = _messageType(decoded);
    if (messageType == null) {
      return A2uiValidationResult.invalid([
        'A2UI message must contain exactly one message type',
      ], messageJson: jsonEncode(decoded));
    }

    final payload = decoded[messageType];
    if (payload is! Map<String, dynamic>) {
      return A2uiValidationResult.invalid([
        '$messageType payload must be an object',
      ], messageJson: jsonEncode(decoded));
    }

    if (messageType == 'createSurface') {
      final surfaceId = payload['surfaceId'];
      if (surfaceId is String &&
          surfaceId.isNotEmpty &&
          (_knownSurfaces.contains(surfaceId) ||
              _existingSurfaceIds.contains(surfaceId))) {
        return const A2uiValidationResult.skip();
      }
    }

    final scratch = Set<String>.from(_knownSurfaces);
    final errors = _validatePayload(messageType, payload, scratch);
    if (errors.isNotEmpty) {
      return A2uiValidationResult.invalid(
        errors,
        messageJson: jsonEncode(decoded),
      );
    }

    return A2uiValidationResult.valid(decoded);
  }

  /// Applies surface-state changes after a message passes full validation.
  void commitMessage(Map<String, dynamic> decoded) {
    final messageType = _messageType(decoded);
    if (messageType == null) {
      return;
    }

    final payload = decoded[messageType];
    if (payload is! Map<String, dynamic>) {
      return;
    }

    switch (messageType) {
      case 'createSurface':
        final surfaceId = payload['surfaceId'];
        if (surfaceId is String && surfaceId.isNotEmpty) {
          _knownSurfaces.add(surfaceId);
        }
      case 'deleteSurface':
        final surfaceId = payload['surfaceId'];
        if (surfaceId is String) {
          _knownSurfaces.remove(surfaceId);
        }
      case 'updateComponents':
      case 'updateDataModel':
        break;
    }
  }

  /// Validates JSON schema only.
  Future<A2uiValidationResult> validateSchema(
    Map<String, dynamic> decoded,
  ) async {
    final schemaErrors = await _schema.validate(decoded);
    if (schemaErrors.isNotEmpty) {
      return A2uiValidationResult.invalid(
        schemaErrors.map((error) => error.toErrorString()).toList(),
        messageJson: jsonEncode(decoded),
      );
    }

    return A2uiValidationResult.valid(decoded);
  }

  Map<String, dynamic>? _decodeJson(String rawJson) {
    try {
      final value = jsonDecode(rawJson);
      if (value is! Map<String, dynamic>) {
        return null;
      }
      return value;
    } on FormatException {
      return null;
    }
  }

  String? _messageType(Map<String, dynamic> decoded) {
    if (decoded['version'] != a2uiVersion) {
      return null;
    }

    final messageKeys = decoded.keys.where((key) => key != 'version').toList();
    if (messageKeys.length != 1) {
      return null;
    }

    return messageKeys.single;
  }

  List<String> _validatePayload(
    String messageType,
    Map<String, dynamic> payload,
    Set<String> knownSurfaces,
  ) {
    return switch (messageType) {
      'createSurface' => _validateCreateSurface(payload, knownSurfaces),
      'updateComponents' => _validateUpdateComponents(payload, knownSurfaces),
      'updateDataModel' => _validateUpdateDataModel(payload, knownSurfaces),
      'deleteSurface' => _validateDeleteSurface(payload, knownSurfaces),
      _ => ['Unknown A2UI message type: $messageType'],
    };
  }

  List<String> _validateCreateSurface(
    Map<String, dynamic> payload,
    Set<String> knownSurfaces,
  ) {
    final errors = <String>[];
    final surfaceId = payload['surfaceId'];
    if (surfaceId is! String || surfaceId.isEmpty) {
      errors.add('createSurface requires non-empty surfaceId');
    } else if (knownSurfaces.contains(surfaceId)) {
      errors.add('createSurface: duplicate surfaceId "$surfaceId"');
    } else {
      knownSurfaces.add(surfaceId);
    }

    final catalogId = payload['catalogId'];
    if (catalogId is! String || catalogId.isEmpty) {
      errors.add('createSurface requires catalogId');
    } else if (catalogId != _manifest.catalogId) {
      errors.add(
        'createSurface catalogId must be "${_manifest.catalogId}" '
        '(got "$catalogId")',
      );
    }

    return errors;
  }

  List<String> _validateUpdateDataModel(
    Map<String, dynamic> payload,
    Set<String> knownSurfaces,
  ) {
    final errors = <String>[];
    final surfaceId = payload['surfaceId'];
    if (surfaceId is! String || surfaceId.isEmpty) {
      errors.add('updateDataModel requires non-empty surfaceId');
    } else if (!knownSurfaces.contains(surfaceId)) {
      errors.add(
        'updateDataModel: unknown surface "$surfaceId"; '
        'emit createSurface first',
      );
    }

    final path = payload['path'];
    if (path is! String || path.isEmpty) {
      errors.add('updateDataModel requires path');
    }

    if (!payload.containsKey('value')) {
      errors.add('updateDataModel requires value');
    }

    return errors;
  }

  List<String> _validateDeleteSurface(
    Map<String, dynamic> payload,
    Set<String> knownSurfaces,
  ) {
    final errors = <String>[];
    final surfaceId = payload['surfaceId'];
    if (surfaceId is! String || surfaceId.isEmpty) {
      errors.add('deleteSurface requires non-empty surfaceId');
    } else if (!knownSurfaces.contains(surfaceId)) {
      errors.add('deleteSurface: unknown surface "$surfaceId"');
    } else {
      knownSurfaces.remove(surfaceId);
    }
    return errors;
  }

  List<String> _validateUpdateComponents(
    Map<String, dynamic> payload,
    Set<String> knownSurfaces,
  ) {
    final errors = <String>[];
    final surfaceId = payload['surfaceId'];
    if (surfaceId is! String || surfaceId.isEmpty) {
      errors.add('updateComponents requires non-empty surfaceId');
      return errors;
    }
    if (!knownSurfaces.contains(surfaceId)) {
      errors.add(
        'updateComponents: unknown surface "$surfaceId"; '
        'emit createSurface first',
      );
      return errors;
    }

    final components = payload['components'];
    if (components is! List || components.isEmpty) {
      errors.add('updateComponents requires a non-empty components array');
      return errors;
    }

    final byId = <String, Map<String, dynamic>>{};
    for (final item in components) {
      if (item is! Map<String, dynamic>) {
        errors.add('updateComponents: each component must be an object');
        continue;
      }
      final id = item['id'];
      if (id is! String || id.isEmpty) {
        errors.add('updateComponents: each component requires non-empty id');
        continue;
      }
      if (byId.containsKey(id)) {
        errors.add('updateComponents: duplicate component id "$id"');
      }
      byId[id] = item;
    }

    if (!byId.containsKey('root')) {
      errors.add('updateComponents must include a component with id "root"');
      return errors;
    }

    final reachable = _collectReachableIds(byId, 'root');
    for (final id in byId.keys) {
      if (!reachable.contains(id)) {
        errors.add(
          'updateComponents/$surfaceId: component "$id" is not reachable from root',
        );
      }
    }

    for (final entry in byId.entries) {
      errors.addAll(_validateComponentReferences(entry.key, entry.value, byId));
    }

    return errors;
  }

  List<String> _validateComponentReferences(
    String componentId,
    Map<String, dynamic> component,
    Map<String, Map<String, dynamic>> byId,
  ) {
    final errors = <String>[];

    final child = component['child'];
    if (child is String && child.isNotEmpty && !byId.containsKey(child)) {
      errors.add(
        'updateComponents: component "$componentId" references '
        'missing child "$child"',
      );
    }

    final children = component['children'];
    if (children is List) {
      for (final childId in children) {
        if (childId is! String || childId.isEmpty) {
          errors.add(
            'updateComponents: component "$componentId" children '
            'must be string ids',
          );
          continue;
        }
        if (!byId.containsKey(childId)) {
          errors.add(
            'updateComponents: component "$componentId" references '
            'missing child "$childId"',
          );
        }
      }
    }

    return errors;
  }

  Set<String> _collectReachableIds(
    Map<String, Map<String, dynamic>> byId,
    String rootId,
  ) {
    final reachable = <String>{};

    void visit(String id) {
      if (!reachable.add(id)) {
        return;
      }
      final component = byId[id];
      if (component == null) {
        return;
      }

      final child = component['child'];
      if (child is String && child.isNotEmpty) {
        visit(child);
      }

      final children = component['children'];
      if (children is List) {
        for (final childId in children) {
          if (childId is String && childId.isNotEmpty) {
            visit(childId);
          }
        }
      }
    }

    visit(rootId);
    return reachable;
  }
}

/// Runs dry-run structural validation, schema validation, then commits state.
Future<A2uiValidationResult> validateA2uiJson(
  A2uiValidator validator,
  String rawJson,
) async {
  Map<String, dynamic> decoded;
  try {
    final value = jsonDecode(rawJson);
    if (value is! Map<String, dynamic>) {
      return A2uiValidationResult.invalid([
        'A2UI message must be a JSON object',
      ], messageJson: rawJson);
    }
    decoded = value;
  } on FormatException catch (error) {
    return A2uiValidationResult.invalid([
      'Invalid JSON: $error',
    ], messageJson: rawJson);
  }

  if (decoded['version'] != a2uiVersion) {
    return A2uiValidationResult.invalid([
      'A2UI message must have version "$a2uiVersion"',
    ], messageJson: jsonEncode(decoded));
  }

  final structural = validator.validateMessageDry(decoded);
  if (structural.skipped || !structural.isValid) {
    return structural;
  }

  final schemaResult = await validator.validateSchema(decoded);
  if (!schemaResult.isValid) {
    return schemaResult;
  }

  validator.commitMessage(decoded);
  return schemaResult;
}
