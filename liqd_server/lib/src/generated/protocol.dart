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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'apps/user_app.dart' as _i5;
import 'stac_app/stac_chat_message.dart' as _i6;
import 'stac_app/stac_generate_exception.dart' as _i7;
import 'stac_app/stac_generate_request.dart' as _i8;
import 'stac_app/stac_generate_response.dart' as _i9;
import 'widgets/user_widget.dart' as _i10;
import 'widgets/widget_validation_result.dart' as _i11;
import 'package:liqd_server/src/generated/apps/user_app.dart' as _i12;
import 'package:liqd_server/src/generated/widgets/user_widget.dart' as _i13;
export 'apps/user_app.dart';
export 'stac_app/stac_chat_message.dart';
export 'stac_app/stac_generate_exception.dart';
export 'stac_app/stac_generate_request.dart';
export 'stac_app/stac_generate_response.dart';
export 'widgets/user_widget.dart';
export 'widgets/widget_validation_result.dart';

class Protocol extends _i1.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'user_app',
      dartName: 'UserApp',
      schema: 'public',
      module: 'liqd',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'surfaceState',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'Map<String,dynamic>',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_widget',
      dartName: 'UserWidget',
      schema: 'public',
      module: 'liqd',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _i2.ColumnDefinition(
          name: 'authUserId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'dataSchema',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'Map<String,dynamic>?',
        ),
        _i2.ColumnDefinition(
          name: 'stacJson',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'Map<String,dynamic>',
        ),
        _i2.ColumnDefinition(
          name: 'isSeed',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_widget_name_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.UserApp) {
      return _i5.UserApp.fromJson(data) as T;
    }
    if (t == _i6.StacChatMessage) {
      return _i6.StacChatMessage.fromJson(data) as T;
    }
    if (t == _i7.StacGenerateException) {
      return _i7.StacGenerateException.fromJson(data) as T;
    }
    if (t == _i8.StacGenerateRequest) {
      return _i8.StacGenerateRequest.fromJson(data) as T;
    }
    if (t == _i9.StacGenerateResponse) {
      return _i9.StacGenerateResponse.fromJson(data) as T;
    }
    if (t == _i10.UserWidget) {
      return _i10.UserWidget.fromJson(data) as T;
    }
    if (t == _i11.WidgetValidationResult) {
      return _i11.WidgetValidationResult.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.UserApp?>()) {
      return (data != null ? _i5.UserApp.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.StacChatMessage?>()) {
      return (data != null ? _i6.StacChatMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.StacGenerateException?>()) {
      return (data != null ? _i7.StacGenerateException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.StacGenerateRequest?>()) {
      return (data != null ? _i8.StacGenerateRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i9.StacGenerateResponse?>()) {
      return (data != null ? _i9.StacGenerateResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.UserWidget?>()) {
      return (data != null ? _i10.UserWidget.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.WidgetValidationResult?>()) {
      return (data != null ? _i11.WidgetValidationResult.fromJson(data) : null)
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == dynamic) {
      return deserializeDynamicFieldValue(data) as T;
    }
    if (t == List<_i6.StacChatMessage>) {
      return (data as List)
              .map((e) => deserialize<_i6.StacChatMessage>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
                )
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i12.UserApp>) {
      return (data as List).map((e) => deserialize<_i12.UserApp>(e)).toList()
          as T;
    }
    if (t == List<_i13.UserWidget>) {
      return (data as List).map((e) => deserialize<_i13.UserWidget>(e)).toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
                )
              : null)
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.UserApp => 'UserApp',
      _i6.StacChatMessage => 'StacChatMessage',
      _i7.StacGenerateException => 'StacGenerateException',
      _i8.StacGenerateRequest => 'StacGenerateRequest',
      _i9.StacGenerateResponse => 'StacGenerateResponse',
      _i10.UserWidget => 'UserWidget',
      _i11.WidgetValidationResult => 'WidgetValidationResult',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('liqd.', '');
    }

    switch (data) {
      case _i5.UserApp():
        return 'UserApp';
      case _i6.StacChatMessage():
        return 'StacChatMessage';
      case _i7.StacGenerateException():
        return 'StacGenerateException';
      case _i8.StacGenerateRequest():
        return 'StacGenerateRequest';
      case _i9.StacGenerateResponse():
        return 'StacGenerateResponse';
      case _i10.UserWidget():
        return 'UserWidget';
      case _i11.WidgetValidationResult():
        return 'WidgetValidationResult';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'UserApp') {
      return deserialize<_i5.UserApp>(data['data']);
    }
    if (dataClassName == 'StacChatMessage') {
      return deserialize<_i6.StacChatMessage>(data['data']);
    }
    if (dataClassName == 'StacGenerateException') {
      return deserialize<_i7.StacGenerateException>(data['data']);
    }
    if (dataClassName == 'StacGenerateRequest') {
      return deserialize<_i8.StacGenerateRequest>(data['data']);
    }
    if (dataClassName == 'StacGenerateResponse') {
      return deserialize<_i9.StacGenerateResponse>(data['data']);
    }
    if (dataClassName == 'UserWidget') {
      return deserialize<_i10.UserWidget>(data['data']);
    }
    if (dataClassName == 'WidgetValidationResult') {
      return deserialize<_i11.WidgetValidationResult>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _i3.Protocol().registerHostProtocol('liqd', this);
    _i4.Protocol().registerHostProtocol('liqd', this);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i5.UserApp:
        return _i5.UserApp.t;
      case _i10.UserWidget:
        return _i10.UserWidget.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'liqd';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
