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

abstract class WidgetValidationResult implements _i1.SerializableModel {
  WidgetValidationResult._({
    required this.valid,
    this.errors,
    this.stacJson,
  });

  factory WidgetValidationResult({
    required bool valid,
    List<String>? errors,
    Map<String, dynamic>? stacJson,
  }) = _WidgetValidationResultImpl;

  factory WidgetValidationResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WidgetValidationResult(
      valid: _i1.BoolJsonExtension.fromJson(jsonSerialization['valid']),
      errors: jsonSerialization['errors'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['errors'],
            ),
      stacJson: jsonSerialization['stacJson'] == null
          ? null
          : _i2.Protocol().deserialize<Map<String, dynamic>>(
              jsonSerialization['stacJson'],
            ),
    );
  }

  bool valid;

  List<String>? errors;

  Map<String, dynamic>? stacJson;

  /// Returns a shallow copy of this [WidgetValidationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WidgetValidationResult copyWith({
    bool? valid,
    List<String>? errors,
    Map<String, dynamic>? stacJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WidgetValidationResult',
      'valid': valid,
      if (errors != null) 'errors': errors?.toJson(),
      if (stacJson != null)
        'stacJson': stacJson?.toJson(
          valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(v),
        ),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WidgetValidationResultImpl extends WidgetValidationResult {
  _WidgetValidationResultImpl({
    required bool valid,
    List<String>? errors,
    Map<String, dynamic>? stacJson,
  }) : super._(
         valid: valid,
         errors: errors,
         stacJson: stacJson,
       );

  /// Returns a shallow copy of this [WidgetValidationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WidgetValidationResult copyWith({
    bool? valid,
    Object? errors = _Undefined,
    Object? stacJson = _Undefined,
  }) {
    return WidgetValidationResult(
      valid: valid ?? this.valid,
      errors: errors is List<String>?
          ? errors
          : this.errors?.map((e0) => e0).toList(),
      stacJson: stacJson is Map<String, dynamic>?
          ? stacJson
          : this.stacJson?.map(
              (
                key0,
                value0,
              ) => MapEntry(
                key0,
                value0,
              ),
            ),
    );
  }
}
