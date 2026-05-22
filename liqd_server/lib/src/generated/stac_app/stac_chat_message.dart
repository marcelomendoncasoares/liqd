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

abstract class StacChatMessage
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  StacChatMessage._({
    required this.role,
    required this.content,
  });

  factory StacChatMessage({
    required String role,
    required String content,
  }) = _StacChatMessageImpl;

  factory StacChatMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return StacChatMessage(
      role: jsonSerialization['role'] as String,
      content: jsonSerialization['content'] as String,
    );
  }

  String role;

  String content;

  /// Returns a shallow copy of this [StacChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StacChatMessage copyWith({
    String? role,
    String? content,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StacChatMessage',
      'role': role,
      'content': content,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StacChatMessage',
      'role': role,
      'content': content,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _StacChatMessageImpl extends StacChatMessage {
  _StacChatMessageImpl({
    required String role,
    required String content,
  }) : super._(
         role: role,
         content: content,
       );

  /// Returns a shallow copy of this [StacChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StacChatMessage copyWith({
    String? role,
    String? content,
  }) {
    return StacChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
    );
  }
}
