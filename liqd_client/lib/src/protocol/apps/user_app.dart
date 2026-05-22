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
import 'package:liqd_client/src/protocol/protocol.dart' as _i2;

abstract class UserApp implements _i1.SerializableModel {
  UserApp._({
    this.id,
    required this.authUserId,
    required this.title,
    required this.surfaceState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserApp({
    int? id,
    required _i1.UuidValue authUserId,
    required String title,
    required Map<String, dynamic> surfaceState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserAppImpl;

  factory UserApp.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserApp(
      id: jsonSerialization['id'] as int?,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      title: jsonSerialization['title'] as String,
      surfaceState: _i2.Protocol().deserialize<Map<String, dynamic>>(
        jsonSerialization['surfaceState'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue authUserId;

  String title;

  Map<String, dynamic> surfaceState;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [UserApp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserApp copyWith({
    int? id,
    _i1.UuidValue? authUserId,
    String? title,
    Map<String, dynamic>? surfaceState,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserApp',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      'title': title,
      'surfaceState': surfaceState.toJson(
        valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(v),
      ),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserAppImpl extends UserApp {
  _UserAppImpl({
    int? id,
    required _i1.UuidValue authUserId,
    required String title,
    required Map<String, dynamic> surfaceState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         title: title,
         surfaceState: surfaceState,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [UserApp]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserApp copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    String? title,
    Map<String, dynamic>? surfaceState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserApp(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      title: title ?? this.title,
      surfaceState:
          surfaceState ??
          this.surfaceState.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
