import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/aggregate.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/interfaces/aggregatable.dart';
import 'package:firestore_odm/src/interfaces/filterable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/limitable.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/interfaces/orderable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/orderby.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';

class Query<
  S extends FirestoreSchema,
  T,
  P extends PatchBuilder<T, Map<String, dynamic>?>,
  F extends FilterBuilderRoot,
  OB extends OrderByFieldNode,
  AB extends AggregateBuilderRoot
>
    implements
        Gettable<List<T>>,
        Streamable<List<T>>,
        Filterable<T>,
        Orderable<T>,
        Patchable<T>,
        Modifiable<T>,
        Aggregatable<T>,
        Limitable,
        Deletable {
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;
  final String _documentIdFieldName;

  /// The underlying Firestore query
  final firestore.Query<Map<String, dynamic>> _query;

  final P _patchBuilder;

  final F _filterBuilder;

  final OB Function(OrderByContext) _orderByBuilderFunc;

  final AB Function(AggregateContext) _aggregateBuilderFunc;

  const Query({
    required firestore.Query<Map<String, dynamic>> query,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required String documentIdField,
    required P patchBuilder,
    required F filterBuilder,
    required OB Function(OrderByContext) orderByBuilderFunc,
    required AB Function(AggregateContext) aggregateBuilderFunc,
  }) : _query = query,
       _toJson = toJson,
       _fromJson = fromJson,
       _documentIdFieldName = documentIdField,
       _patchBuilder = patchBuilder,
       _filterBuilder = filterBuilder,
       _orderByBuilderFunc = orderByBuilderFunc,
       _aggregateBuilderFunc = aggregateBuilderFunc;

  @override
  Future<List<T>> get() =>
      QueryHandler.get(_query, _fromJson, _documentIdFieldName);

  @override
  Stream<List<T>> get stream =>
      QueryHandler.stream(_query, _fromJson, _documentIdFieldName);

  Query<S, T, P, F, OB, AB> _newQuery(
    firestore.Query<Map<String, dynamic>> newQuery,
  ) {
    return Query<S, T, P, F, OB, AB>(
      query: newQuery,
      toJson: _toJson,
      fromJson: _fromJson,
      documentIdField: _documentIdFieldName,
      patchBuilder: _patchBuilder,
      filterBuilder: _filterBuilder,
      orderByBuilderFunc: _orderByBuilderFunc,
      aggregateBuilderFunc: _aggregateBuilderFunc,
    );
  }

  @override
  Query<S, T, P, F, OB, AB> where(
    FilterOperation Function(F builder) filterFunc,
  ) {
    final filter = filterFunc(_filterBuilder);
    final newQuery = QueryFilterHandler.applyFilter(_query, filter);
    // Handle different types of query objects
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> orderBy<O extends Record>(
    O Function(OB selector) orderByFunc,
  ) {
    final config = QueryOrderbyHandler.buildOrderBy<T, O, OB>(
      orderByFunc: orderByFunc,
      orderByBuilderFunc: _orderByBuilderFunc,
      documentIdFieldName: _documentIdFieldName,
    );
    final newQuery = QueryOrderbyHandler.applyOrderBy(_query, config);
    return OrderedQuery<S, T, O, P, F, OB, AB>(
      query: newQuery,
      toJson: _toJson,
      fromJson: _fromJson,
      documentIdField: _documentIdFieldName,
      orderByConfig: config,
      patchBuilder: _patchBuilder,
      filterBuilder: _filterBuilder,
      orderByBuilderFunc: _orderByBuilderFunc,
      aggregateBuilderFunc: _aggregateBuilderFunc,
    );
  }

  @override
  Query<S, T, P, F, OB, AB> limit(int limit) {
    final newQuery = QueryLimitHandler.applyLimit(_query, limit);
    return _newQuery(newQuery);
  }

  @override
  Query<S, T, P, F, OB, AB> limitToLast(int limit) {
    final newQuery = QueryLimitHandler.applyLimitToLast(_query, limit);
    return _newQuery(newQuery);
  }

  @override
  Future<void> patch(List<UpdateOperation> Function(P patchBuilder) patches) {
    final operations = patches(_patchBuilder);
    return QueryHandler.patch(_query, operations);
  }

  /// Modify multiple documents using diff-based updates.
  ///
  /// This method performs a read operation followed by batch update operations.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// **Important Notes:**
  /// - **Performance**: This method has an additional read operation, making it slower than [patch]
  /// - **Concurrency**: Firestore uses last-write-wins semantics. This read-modify-write
  ///   operation is NOT transactional and may be subject to race conditions
  /// - **Transactions**: For transactional updates, use transactions instead
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  ///
  /// **Example:**
  /// ```dart
  /// // Update all premium users with atomic operations (default)
  /// await db.users
  ///   .where(($) => $.isPremium(isEqualTo: true))
  ///   .modify((user) => user.copyWith(points: user.points + 100));
  ///
  /// // Update without atomic operations
  /// await db.users
  ///   .where(($) => $.status(isEqualTo: 'inactive'))
  ///   .modify((user) => user.copyWith(status: 'archived'), atomic: false);
  /// ```
  @override
  Future<void> modify(ModifierBuilder<T> modifier, {bool atomic = true}) =>
      QueryHandler.modify(
        _query,
        _documentIdFieldName,
        _toJson,
        _fromJson,
        modifier,
        atomic: atomic,
      );

  @override
  AggregateQuery<T, R, AB> aggregate<R extends Record>(
    R Function(AB selector) builder,
  ) {
    final config = QueryAggregatableHandler.buildAggregate(
      builder,
      _aggregateBuilderFunc,
    );
    final newQuery = QueryAggregatableHandler.applyAggregate(
      _query,
      config.operations,
    );
    return AggregateQuery(
      newQuery,
      _toJson,
      _fromJson,
      _documentIdFieldName,
      config,
      _aggregateBuilderFunc,
    );
  }

  @override
  AggregateCountQuery count() {
    final newQuery = QueryAggregatableHandler.applyCount(_query);
    return AggregateCountQuery(newQuery);
  }

  @override
  Future<void> delete() => QueryHandler.delete(_query);
}
