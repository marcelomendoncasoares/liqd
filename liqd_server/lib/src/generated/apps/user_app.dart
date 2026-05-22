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

abstract class UserApp
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = UserAppTable();

  static const db = UserAppRepository._();

  @override
  int? id;

  _i1.UuidValue authUserId;

  String title;

  Map<String, dynamic> surfaceState;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserApp',
      if (id != null) 'id': id,
      'authUserId': authUserId.toJson(),
      'title': title,
      'surfaceState': surfaceState.toJson(
        valueToJson: (v) => _i2.Protocol().dynamicFieldToJson(
          v,
          forProtocol: true,
        ),
      ),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static UserAppInclude include() {
    return UserAppInclude._();
  }

  static UserAppIncludeList includeList({
    _i1.WhereExpressionBuilder<UserAppTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserAppTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppTable>? orderByList,
    UserAppInclude? include,
  }) {
    return UserAppIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserApp.t),
      orderDescending: // ignore: deprecated_member_use_from_same_package
          orderDescending,
      orderByList: orderByList?.call(UserApp.t),
      include: include,
    );
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

class UserAppUpdateTable extends _i1.UpdateTable<UserAppTable> {
  UserAppUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> authUserId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.authUserId,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
    value,
  );

  _i1.ColumnValue<Map<String, dynamic>, Map<String, dynamic>> surfaceState(
    Map<String, dynamic> value,
  ) => _i1.ColumnValue(
    table.surfaceState,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class UserAppTable extends _i1.Table<int?> {
  UserAppTable({super.tableRelation}) : super(tableName: 'user_app') {
    updateTable = UserAppUpdateTable(this);
    authUserId = _i1.ColumnUuid(
      'authUserId',
      this,
    );
    title = _i1.ColumnString(
      'title',
      this,
    );
    surfaceState = _i1.ColumnSerializable<Map<String, dynamic>>(
      'surfaceState',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
  }

  late final UserAppUpdateTable updateTable;

  late final _i1.ColumnUuid authUserId;

  late final _i1.ColumnString title;

  late final _i1.ColumnSerializable<Map<String, dynamic>> surfaceState;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    authUserId,
    title,
    surfaceState,
    createdAt,
    updatedAt,
  ];
}

class UserAppInclude extends _i1.IncludeObject {
  UserAppInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => UserApp.t;
}

class UserAppIncludeList extends _i1.IncludeList {
  UserAppIncludeList._({
    _i1.WhereExpressionBuilder<UserAppTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserApp.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => UserApp.t;
}

class UserAppRepository {
  const UserAppRepository._();

  /// Returns a list of [UserApp]s matching the given query parameters.
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
  Future<List<UserApp>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserAppTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserAppTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UserApp>(
      where: where?.call(UserApp.t),
      orderBy: orderBy?.call(UserApp.t),
      orderByList: orderByList?.call(UserApp.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [UserApp] matching the given query parameters.
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
  Future<UserApp?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserAppTable>? where,
    int? offset,
    _i1.OrderByBuilder<UserAppTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UserApp>(
      where: where?.call(UserApp.t),
      orderBy: orderBy?.call(UserApp.t),
      orderByList: orderByList?.call(UserApp.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UserApp] by its [id] or null if no such row exists.
  Future<UserApp?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UserApp>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UserApp]s in the list and returns the inserted rows.
  ///
  /// The returned [UserApp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<UserApp>> insert(
    _i1.DatabaseSession session,
    List<UserApp> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<UserApp>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [UserApp] and returns the inserted row.
  ///
  /// The returned [UserApp] will have its `id` field set.
  Future<UserApp> insertRow(
    _i1.DatabaseSession session,
    UserApp row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserApp>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [UserApp]s in the list and returns the resulting rows.
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
  /// The returned [UserApp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  Future<List<UserApp>> upsert(
    _i1.DatabaseSession session,
    List<UserApp> rows, {
    required _i1.ColumnSelections<UserAppTable> conflictColumns,
    _i1.ColumnSelections<UserAppTable>? updateColumns,
    _i1.WhereExpressionBuilder<UserAppTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsert<UserApp>(
      rows,
      conflictColumns: conflictColumns(UserApp.t),
      updateColumns: updateColumns?.call(UserApp.t),
      updateWhere: updateWhere?.call(UserApp.t),
      transaction: transaction,
    );
  }

  /// Upserts a single [UserApp] and returns the resulting row.
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
  /// The returned [UserApp] will have its `id` field set.
  Future<UserApp?> upsertRow(
    _i1.DatabaseSession session,
    UserApp row, {
    required _i1.ColumnSelections<UserAppTable> conflictColumns,
    _i1.ColumnSelections<UserAppTable>? updateColumns,
    _i1.WhereExpressionBuilder<UserAppTable>? updateWhere,
    _i1.Transaction? transaction,
  }) async {
    return session.db.upsertRow<UserApp>(
      row,
      conflictColumns: conflictColumns(UserApp.t),
      updateColumns: updateColumns?.call(UserApp.t),
      updateWhere: updateWhere?.call(UserApp.t),
      transaction: transaction,
    );
  }

  /// Updates all [UserApp]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<UserApp>> update(
    _i1.DatabaseSession session,
    List<UserApp> rows, {
    _i1.ColumnSelections<UserAppTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<UserApp>(
      rows,
      columns: columns?.call(UserApp.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserApp]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserApp> updateRow(
    _i1.DatabaseSession session,
    UserApp row, {
    _i1.ColumnSelections<UserAppTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserApp>(
      row,
      columns: columns?.call(UserApp.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserApp] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserApp?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<UserAppUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<UserApp>(
      id,
      columnValues: columnValues(UserApp.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserApp]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<UserApp>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<UserAppUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<UserAppTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<UserAppTable>? orderBy,
    _i1.OrderByListBuilder<UserAppTable>? orderByList,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<UserApp>(
      columnValues: columnValues(UserApp.t.updateTable),
      where: where(UserApp.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserApp.t),
      orderByList: orderByList?.call(UserApp.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [UserApp]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<UserApp>> delete(
    _i1.DatabaseSession session,
    List<UserApp> rows, {
    _i1.OrderByBuilder<UserAppTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<UserApp>(
      rows,
      orderBy: orderBy?.call(UserApp.t),
      orderByList: orderByList?.call(UserApp.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes a single [UserApp].
  Future<UserApp> deleteRow(
    _i1.DatabaseSession session,
    UserApp row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserApp>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  Future<List<UserApp>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UserAppTable> where,
    _i1.OrderByBuilder<UserAppTable>? orderBy,
    @Deprecated('Use desc() on the orderBy column instead.')
    bool orderDescending = false,
    _i1.OrderByListBuilder<UserAppTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<UserApp>(
      where: where(UserApp.t),
      orderBy: orderBy?.call(UserApp.t),
      orderByList: orderByList?.call(UserApp.t),
      orderDescending: // ignore: deprecated_member_use
          orderDescending,
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<UserAppTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<UserApp>(
      where: where?.call(UserApp.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UserApp] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<UserAppTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UserApp>(
      where: where(UserApp.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
