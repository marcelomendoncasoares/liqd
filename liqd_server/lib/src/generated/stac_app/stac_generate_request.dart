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
import '../stac_app/stac_chat_message.dart' as _i2;
import 'package:liqd_server/src/generated/protocol.dart' as _i3;

abstract class StacGenerateRequest
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  StacGenerateRequest._({
    this.model,
    required this.messages,
    this.existingStacJson,
  });

  factory StacGenerateRequest({
    String? model,
    required List<_i2.StacChatMessage> messages,
    String? existingStacJson,
  }) = _StacGenerateRequestImpl;

  factory StacGenerateRequest.fromJson(Map<String, dynamic> jsonSerialization) {
    return StacGenerateRequest(
      model: jsonSerialization['model'] as String?,
      messages: _i3.Protocol().deserialize<List<_i2.StacChatMessage>>(
        jsonSerialization['messages'],
      ),
      existingStacJson: jsonSerialization['existingStacJson'] as String?,
    );
  }

  String? model;

  List<_i2.StacChatMessage> messages;

  String? existingStacJson;

  /// Returns a shallow copy of this [StacGenerateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StacGenerateRequest copyWith({
    String? model,
    List<_i2.StacChatMessage>? messages,
    String? existingStacJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StacGenerateRequest',
      if (model != null) 'model': model,
      'messages': messages.toJson(valueToJson: (v) => v.toJson()),
      if (existingStacJson != null) 'existingStacJson': existingStacJson,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StacGenerateRequest',
      if (model != null) 'model': model,
      'messages': messages.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (existingStacJson != null) 'existingStacJson': existingStacJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StacGenerateRequestImpl extends StacGenerateRequest {
  _StacGenerateRequestImpl({
    String? model,
    required List<_i2.StacChatMessage> messages,
    String? existingStacJson,
  }) : super._(
         model: model,
         messages: messages,
         existingStacJson: existingStacJson,
       );

  /// Returns a shallow copy of this [StacGenerateRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StacGenerateRequest copyWith({
    Object? model = _Undefined,
    List<_i2.StacChatMessage>? messages,
    Object? existingStacJson = _Undefined,
  }) {
    return StacGenerateRequest(
      model: model is String? ? model : this.model,
      messages: messages ?? this.messages.map((e0) => e0.copyWith()).toList(),
      existingStacJson: existingStacJson is String?
          ? existingStacJson
          : this.existingStacJson,
    );
  }
}
