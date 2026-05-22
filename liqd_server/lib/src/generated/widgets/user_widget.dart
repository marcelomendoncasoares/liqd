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
import 'package:liqd_server/src/generated/protocol.dart' as _i2;

abstract class UserWidget
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = UserWidgetTable();

  static const db = UserWidgetRepository._();

  @override
  int? id;

  _i1.UuidValue authUserId;

  String name;

  String description;

  Map<String, dynamic>? dataSchema;

  Map<String, dynamic> stacJson;

  bool isSeed;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserWidget',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      'name': name,
      'description': description,
      if (dataSchema != null)
        'dataSchema': dataSchema?.toJson(
          valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(
            v,
            forProtocol: true,
          ),
        ),
      'stacJson': stacJson.toJson(
        valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(
          v,
          forProtocol: true,
        ),
      ),
      'isSeed': isSeed,
      'createdAt': createdAt.toJson(),
    };
  }

  static UserWidgetInclude include() {
    return UserWidgetInclude._();
  }

  static UserWidgetIncludeList includeList({
    _i1.WhereExpressionBuilder<UserWidgetTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserWidgetTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserWidgetTable>? orderByList,
    UserWidgetInclude? include,
  }) {
    return UserWidgetIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserWidget.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(UserWidget.t),
      include: include,
    );
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

class UserWidgetUpdateTable extends _i1.UpdateTable<UserWidgetTable> {
  UserWidgetUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> description(String value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<Map<String, dynamic>, Map<String, dynamic>> dataSchema(
    Map<String, dynamic>? value,
  ) => _i1.ColumnValue(
    table.dataSchema,
    value,
  );

  _i1.ColumnValue<Map<String, dynamic>, Map<String, dynamic>> stacJson(
    Map<String, dynamic> value,
  ) => _i1.ColumnValue(
    table.stacJson,
    value,
  );

  _i1.ColumnValue<bool, bool> isSeed(bool value) => _i1.ColumnValue(
    table.isSeed,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class UserWidgetTable extends _i1.Table<int?> {
  UserWidgetTable({super.tableRelation}) : super(tableName: 'user_widget') {
    updateTable = UserWidgetUpdateTable(this);
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    dataSchema = _i1.ColumnSerializable<Map<String, dynamic>>(
      'dataSchema',
      this,
    );
    stacJson = _i1.ColumnSerializable<Map<String, dynamic>>(
      'stacJson',
      this,
    );
    isSeed = _i1.ColumnBool(
      'isSeed',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
  }

  late final UserWidgetUpdateTable updateTable;

  late final _i1.ColumnUuid authUserId;

  late final _i1.ColumnString name;

  late final _i1.ColumnString description;

  late final _i1.ColumnSerializable<Map<String, dynamic>> dataSchema;

  late final _i1.ColumnSerializable<Map<String, dynamic>> stacJson;

  late final _i1.ColumnBool isSeed;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    authUserId,
    name,
    description,
    dataSchema,
    stacJson,
    isSeed,
    createdAt,
  ];
}

class UserWidgetInclude extends _i1.IncludeObject {
  UserWidgetInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserWidget.t;
}

class UserWidgetIncludeList extends _i1.IncludeList {
  UserWidgetIncludeList._({
    _i1.WhereExpressionBuilder<UserWidgetTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserWidget.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserWidget.t;
}

class UserWidgetRepository {
  const UserWidgetRepository._();

  /// Returns a list of [UserWidget]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<UserWidget>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserWidgetTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserWidgetTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserWidgetTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UserWidget>(
      where: where?.call(UserWidget.t),
      orderBy: orderBy?.call(UserWidget.t),
      orderByList: orderByList?.call(UserWidget.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [UserWidget] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<UserWidget?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserWidgetTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserWidgetTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserWidgetTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UserWidget>(
      where: where?.call(UserWidget.t),
      orderBy: orderBy?.call(UserWidget.t),
      orderByList: orderByList?.call(UserWidget.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UserWidget] by its [id] or null if no such row exists.
  Future<UserWidget?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UserWidget>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UserWidget]s in the list and returns the inserted rows.
  ///
  /// The returned [UserWidget]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<UserWidget>> insert(
    _i1.DatabaseSession session,
    List<UserWidget> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<UserWidget>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [UserWidget] and returns the inserted row.
  ///
  /// The returned [UserWidget] will have its `id` field set.
  Future<UserWidget> insertRow(
    _i1.DatabaseSession session,
    UserWidget row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserWidget>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [UserWidget]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [UserWidget]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  Future<List<UserWidget>> upsert(
    _i1.DatabaseSession session,
    List<UserWidget> rows, {
    required _i1.ColumnSelections<UserWidgetTable> conflictColumns,
    _i1.ColumnSelections<UserWidgetTable>? updateColumns,
    _i1.WhereExpressionBuilder<UserWidgetTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsert<UserWidget>(
      rows,
      conflictColumns: conflictColumns(UserWidget.t),
      updateColumns: updateColumns?.call(UserWidget.t),
      updateWhere: updateWhere?.call(UserWidget.t),
      transaction: transaction,
    );
  }

  /// Upserts a single [UserWidget] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [UserWidget] will have its `id` field set.
  Future<UserWidget?> upsertRow(
    _i1.DatabaseSession session,
    UserWidget row, {
    required _i1.ColumnSelections<UserWidgetTable> conflictColumns,
    _i1.ColumnSelections<UserWidgetTable>? updateColumns,
    _i1.WhereExpressionBuilder<UserWidgetTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<UserWidget>(
      row,
      conflictColumns: conflictColumns(UserWidget.t),
      updateColumns: updateColumns?.call(UserWidget.t),
      updateWhere: updateWhere?.call(UserWidget.t),
      transaction: transaction,
    );
  }

  /// Updates all [UserWidget]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserWidget>> update(
    _i1.DatabaseSession session,
    List<UserWidget> rows, {
    _i1.ColumnSelections<UserWidgetTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserWidget>(
      rows,
      columns: columns?.call(UserWidget.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserWidget]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserWidget> updateRow(
    _i1.DatabaseSession session,
    UserWidget row, {
    _i1.ColumnSelections<UserWidgetTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserWidget>(
      row,
      columns: columns?.call(UserWidget.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserWidget] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserWidget?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<UserWidgetUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserWidget>(
      id,
      columnValues: columnValues(UserWidget.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserWidget]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserWidget>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<UserWidgetUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserWidgetTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserWidgetTable>? orderBy,
    _i1.OrderByListBuilder<UserWidgetTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserWidget>(
      columnValues: columnValues(UserWidget.t.updateTable),
      where: where(UserWidget.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserWidget.t),
      orderByList: orderByList?.call(UserWidget.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserWidget]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserWidget>> delete(
    _i1.DatabaseSession session,
    List<UserWidget> rows, {
    _i1.OrderByBuilder<UserWidgetTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserWidgetTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserWidget>(
      rows,
      orderBy: orderBy?.call(UserWidget.t),
      orderByList: orderByList?.call(UserWidget.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserWidget].
  Future<UserWidget> deleteRow(
    _i1.DatabaseSession session,
    UserWidget row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserWidget>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  Future<List<UserWidget>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UserWidgetTable> where,
    _i1.OrderByBuilder<UserWidgetTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserWidgetTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserWidget>(
      where: where(UserWidget.t),
      orderBy: orderBy?.call(UserWidget.t),
      orderByList: orderByList?.call(UserWidget.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserWidgetTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserWidget>(
      where: where?.call(UserWidget.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UserWidget] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UserWidgetTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UserWidget>(
      where: where(UserWidget.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
