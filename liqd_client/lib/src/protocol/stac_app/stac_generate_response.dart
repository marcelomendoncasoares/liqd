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

abstract class StacGenerateResponse implements _i1.SerializableModel {
  StacGenerateResponse._({
    this.stacJson,
    required this.rawResponse,
    this.validationErrors,
  });

  factory StacGenerateResponse({
    Map<String, dynamic>? stacJson,
    required String rawResponse,
    List<String>? validationErrors,
  }) = _StacGenerateResponseImpl;

  factory StacGenerateResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return StacGenerateResponse(
      stacJson: jsonSerialization['stacJson'] == null
          ? null
          : _i2.Protocol().deserialize<Map<String, dynamic>>(
              jsonSerialization['stacJson'],
            ),
      rawResponse: jsonSerialization['rawResponse'] as String,
      validationErrors: jsonSerialization['validationErrors'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['validationErrors'],
            ),
    );
  }

  Map<String, dynamic>? stacJson;

  String rawResponse;

  List<String>? validationErrors;

  /// Returns a shallow copy of this [StacGenerateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StacGenerateResponse copyWith({
    Map<String, dynamic>? stacJson,
    String? rawResponse,
    List<String>? validationErrors,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StacGenerateResponse',
      if (stacJson != null)
        'stacJson': stacJson?.toJson(
          valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(v),
        ),
      'rawResponse': rawResponse,
      if (validationErrors != null)
        'validationErrors': validationErrors?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StacGenerateResponseImpl extends StacGenerateResponse {
  _StacGenerateResponseImpl({
    Map<String, dynamic>? stacJson,
    required String rawResponse,
    List<String>? validationErrors,
  }) : super._(
         stacJson: stacJson,
         rawResponse: rawResponse,
         validationErrors: validationErrors,
       );

  /// Returns a shallow copy of this [StacGenerateResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StacGenerateResponse copyWith({
    Object? stacJson = _Undefined,
    String? rawResponse,
    Object? validationErrors = _Undefined,
  }) {
    return StacGenerateResponse(
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
      rawResponse: rawResponse ?? this.rawResponse,
      validationErrors: validationErrors is List<String>?
          ? validationErrors
          : this.validationErrors?.map((e0) => e0).toList(),
    );
  }
}
