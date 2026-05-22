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

abstract class UserWidget implements _i1.SerializableModel {
  UserWidget._({
    this.id,
    required this.authUserId,
    required this.name,
    required this.description,
    this.dataSchema,
    required this.stacJson,
    bool? isSeed,
    DateTime? createdAt,
  }) : isSeed = isSeed ?? false,
       createdAt = createdAt ?? DateTime.now();

  factory UserWidget({
    int? id,
    required _i1.UuidValue authUserId,
    required String name,
    required String description,
    Map<String, dynamic>? dataSchema,
    required Map<String, dynamic> stacJson,
    bool? isSeed,
    DateTime? createdAt,
  }) = _UserWidgetImpl;

  factory UserWidget.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserWidget(
      id: jsonSerialization['id'] as int?,
      authUserId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authUserId'],
      ),
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      dataSchema: jsonSerialization['dataSchema'] == null
          ? null
          : _i2.Protocol().deserialize<Map<String, dynamic>>(
              jsonSerialization['dataSchema'],
            ),
      stacJson: _i2.Protocol().deserialize<Map<String, dynamic>>(
        jsonSerialization['stacJson'],
      ),
      isSeed: jsonSerialization['isSeed'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isSeed']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue authUserId;

  String name;

  String description;

  Map<String, dynamic>? dataSchema;

  Map<String, dynamic> stacJson;

  bool isSeed;

  DateTime createdAt;

  /// Returns a shallow copy of this [UserWidget]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserWidget copyWith({
    int? id,
    _i1.UuidValue? authUserId,
    String? name,
    String? description,
    Map<String, dynamic>? dataSchema,
    Map<String, dynamic>? stacJson,
    bool? isSeed,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserWidget',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      'name': name,
      'description': description,
      if (dataSchema != null)
        'dataSchema': dataSchema?.toJson(
          valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(v),
        ),
      'stacJson': stacJson.toJson(
        valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(v),
      ),
      'isSeed': isSeed,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserWidgetImpl extends UserWidget {
  _UserWidgetImpl({
    int? id,
    required _i1.UuidValue authUserId,
    required String name,
    required String description,
    Map<String, dynamic>? dataSchema,
    required Map<String, dynamic> stacJson,
    bool? isSeed,
    DateTime? createdAt,
  }) : super._(
         id: id,
         authUserId: authUserId,
         name: name,
         description: description,
         dataSchema: dataSchema,
         stacJson: stacJson,
         isSeed: isSeed,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [UserWidget]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserWidget copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authUserId,
    String? name,
    String? description,
    Object? dataSchema = _Undefined,
    Map<String, dynamic>? stacJson,
    bool? isSeed,
    DateTime? createdAt,
  }) {
    return UserWidget(
      id: id is int? ? id : this.id,
      authUserId: authUserId ?? this.authUserId,
      name: name ?? this.name,
      description: description ?? this.description,
      dataSchema: dataSchema is Map<String, dynamic>?
          ? dataSchema
          : this.dataSchema?.map(
              (
                key0,
                value0,
              ) => MapEntry(
                key0,
                value0,
              ),
            ),
      stacJson:
          stacJson ??
          this.stacJson.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0,
            ),
          ),
      isSeed: isSeed ?? this.isSeed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
