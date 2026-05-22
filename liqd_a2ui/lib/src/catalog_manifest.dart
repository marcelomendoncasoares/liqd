import 'dart:convert';

import 'constants.dart';

/// Serializable catalog description sent from the Flutter client to the server.
///
/// The client builds this from a live [Catalog] using genui [PromptBuilder] so
/// prompt text and JSON schema stay in sync with the registered widgets.
final class CatalogManifest {
  const CatalogManifest({
    required this.catalogId,
    required this.systemPrompt,
    required this.messageSchemaJson,
    this.componentNames = const [],
    this.functionNames = const [],
  });

  final String catalogId;
  final String systemPrompt;

  /// JSON Schema for A2UI v0.9 messages (from genui `A2uiMessage.a2uiMessageSchema`).
  final Map<String, dynamic> messageSchemaJson;
  final List<String> componentNames;
  final List<String> functionNames;

  Map<String, dynamic> toJson() => {
    'catalogId': catalogId,
    'systemPrompt': systemPrompt,
    'messageSchemaJson': messageSchemaJson,
    'componentNames': componentNames,
    'functionNames': functionNames,
  };

  String toJsonString() => jsonEncode(toJson());

  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    final schema = json['messageSchemaJson'];
    return CatalogManifest(
      catalogId: json['catalogId'] as String? ?? basicCatalogId,
      systemPrompt: json['systemPrompt'] as String? ?? '',
      messageSchemaJson: schema is Map<String, dynamic>
          ? schema
          : Map<String, dynamic>.from(schema as Map),
      componentNames:
          (json['componentNames'] as List<dynamic>?)
              ?.map((name) => name.toString())
              .toList() ??
          const [],
      functionNames:
          (json['functionNames'] as List<dynamic>?)
              ?.map((name) => name.toString())
              .toList() ??
          const [],
    );
  }

  factory CatalogManifest.fromJsonString(String jsonString) {
    return CatalogManifest.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}
