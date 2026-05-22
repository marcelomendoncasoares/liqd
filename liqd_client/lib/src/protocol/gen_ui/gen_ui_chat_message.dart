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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class GenUiChatMessage implements _i1.SerializableModel {
  GenUiChatMessage._({
    required this.role,
    required this.content,
  });

  factory GenUiChatMessage({
    required String role,
    required String content,
  }) = _GenUiChatMessageImpl;

  factory GenUiChatMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return GenUiChatMessage(
      role: jsonSerialization['role'] as String,
      content: jsonSerialization['content'] as String,
    );
  }

  String role;

  String content;

  /// Returns a shallow copy of this [GenUiChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GenUiChatMessage copyWith({
    String? role,
    String? content,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GenUiChatMessage',
      'role': role,
      'content': content,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GenUiChatMessageImpl extends GenUiChatMessage {
  _GenUiChatMessageImpl({
    required String role,
    required String content,
  }) : super._(
         role: role,
         content: content,
       );

  /// Returns a shallow copy of this [GenUiChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GenUiChatMessage copyWith({
    String? role,
    String? content,
  }) {
    return GenUiChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
    );
  }
}
