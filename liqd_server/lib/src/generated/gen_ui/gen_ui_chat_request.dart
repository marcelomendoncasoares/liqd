/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../gen_ui/gen_ui_chat_message.dart' as _i2;
import 'package:liqd_server/src/generated/protocol.dart' as _i3;

abstract class GenUiChatRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GenUiChatRequest._({
    this.model,
    required this.messages,
    this.conversationId,
    this.existingSurfacesJson,
    this.catalogManifestJson,
  });

  factory GenUiChatRequest({
    String? model,
    required List<_i2.GenUiChatMessage> messages,
    String? conversationId,
    String? existingSurfacesJson,
    String? catalogManifestJson,
  }) = _GenUiChatRequestImpl;

  factory GenUiChatRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return GenUiChatRequest(
      model: jsonSerialization['model'] as String?,
      messages: _i3.Protocol().deserialize<List<_i2.GenUiChatMessage>>(
        jsonSerialization['messages'],
      ),
      conversationId: jsonSerialization['conversationId'] as String?,
      existingSurfacesJson:
          jsonSerialization['existingSurfacesJson'] as String?,
      catalogManifestJson: jsonSerialization['catalogManifestJson'] as String?,
    );
  }

  String? model;

  List<_i2.GenUiChatMessage> messages;

  String? conversationId;

  String? existingSurfacesJson;

  String? catalogManifestJson;

  /// Returns a shallow copy of this [GenUiChatRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GenUiChatRequest copyWith({
    String? model,
    List<_i2.GenUiChatMessage>? messages,
    String? conversationId,
    String? existingSurfacesJson,
    String? catalogManifestJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GenUiChatRequest',
      if (model != null) 'model': model,
      'messages': messages.toJson(valueToJson: (v) => v.toJson()),
      if (conversationId != null) 'conversationId': conversationId,
      if (existingSurfacesJson != null)
        'existingSurfacesJson': existingSurfacesJson,
      if (catalogManifestJson != null)
        'catalogManifestJson': catalogManifestJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GenUiChatRequest',
      if (model != null) 'model': model,
      'messages': messages.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (conversationId != null) 'conversationId': conversationId,
      if (existingSurfacesJson != null)
        'existingSurfacesJson': existingSurfacesJson,
      if (catalogManifestJson != null)
        'catalogManifestJson': catalogManifestJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GenUiChatRequestImpl extends GenUiChatRequest {
  _GenUiChatRequestImpl({
    String? model,
    required List<_i2.GenUiChatMessage> messages,
    String? conversationId,
    String? existingSurfacesJson,
    String? catalogManifestJson,
  }) : super._(
         model: model,
         messages: messages,
         conversationId: conversationId,
         existingSurfacesJson: existingSurfacesJson,
         catalogManifestJson: catalogManifestJson,
       );

  /// Returns a shallow copy of this [GenUiChatRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GenUiChatRequest copyWith({
    Object? model = _Undefined,
    List<_i2.GenUiChatMessage>? messages,
    Object? conversationId = _Undefined,
    Object? existingSurfacesJson = _Undefined,
    Object? catalogManifestJson = _Undefined,
  }) {
    return GenUiChatRequest(
      model: model is String? ? model : this.model,
      messages: messages ?? this.messages.map((e0) => e0.copyWith()).toList(),
      conversationId: conversationId is String?
          ? conversationId
          : this.conversationId,
      existingSurfacesJson: existingSurfacesJson is String?
          ? existingSurfacesJson
          : this.existingSurfacesJson,
      catalogManifestJson: catalogManifestJson is String?
          ? catalogManifestJson
          : this.catalogManifestJson,
    );
  }
}
