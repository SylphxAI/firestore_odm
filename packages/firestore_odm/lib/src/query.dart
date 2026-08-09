/// Typed query surface: where / orderBy / limit / aggregate / count / bulk
/// patch+delete. Bulk operations are chunked to Firestore's 500-write batch
/// limit (never one unbounded batch).
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'aggregate.dart';
import 'filter_builder.dart';
import 'orderby.dart';
import 'patch.dart';
import 'pagination.dart';
import 'schema.dart';
import 'types.dart';
import 'utils.dart';

/// Firestore's maximum number of writes per batch/transaction.
const int kFirestoreMaxWritesPerBatch = 500;

abstract class _QueryOperations<
  S extends FirestoreSchema,
  T,
  P extends PatchBuilder<T>,
  F extends FilterBuilderRoot,
  OB extends OrderByBuilderRoot,
  AB extends AggregateBuilderRoot
> {
  _QueryOperations(
    this._query,
    this._toJson,
    this._fromJson,
    this._documentIdField,
    this._patchBuilderFactory,
    this._filterBuilder,
    this._orderByBuilderFunc,
    this._aggregateBuilderFunc,
  );

  final firestore.Query<Map<String, dynamic>> _query;
  final JsonSerializer<T> _toJson;
  final JsonDeserializer<T> _fromJson;
  final String? _documentIdField;
  final P Function() _patchBuilderFactory;
  final F _filterBuilder;
  final OB Function(OrderByContext context) _orderByBuilderFunc;
  final AB Function(AggregateContext context) _aggregateBuilderFunc;

  firestore.Query<Map<String, dynamic>> get nativeQuery => _query;

  Future<List<T>> get() async {
    final snapshot = await _query.get();
    return processQuerySnapshot(snapshot, _fromJson, _documentIdField);
  }

  Stream<List<T>> get stream => _query.snapshots().map(
    (snapshot) => processQuerySnapshot(snapshot, _fromJson, _documentIdField),
  );

  /// Server-side document count (native AggregateQuery; one-shot).
  Future<int> count() async {
    final snapshot = await _query.count().get();
    return snapshot.count ?? 0;
  }

  /// Typed server-side aggregate (one-shot). Result is a Dart record, e.g.
  /// `(count: c, avgAge: a)`.
  AggregateQuery<R, AB> aggregate<R extends Record>(
    R Function(AB selector) aggregateFunc,
  ) {
    final operations = QueryAggregatableHandler.build(
      aggregateFunc: aggregateFunc,
      aggregateBuilderFunc: _aggregateBuilderFunc,
    );
    return AggregateQuery<R, AB>(
      QueryAggregatableHandler.applyAggregate(_query, operations),
      _aggregateBuilderFunc,
      aggregateFunc,
      operations,
    );
  }

  /// Applies the same patch operations to every document matching this query.
  /// Chunked into batches of at most 500 writes.
  Future<void> patchAll(List<UpdateOperation> operations) async {
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) return;
    final snapshot = await _query.get();
    await _runChunked(
      snapshot.docs.map((d) => d.reference).toList(),
      (batch, ref) => batch.update(ref, updateMap),
    );
  }

  /// Deletes every document matching this query. Chunked into batches of at
  /// most 500 writes.
  Future<void> deleteAll() async {
    final snapshot = await _query.get();
    await _runChunked(
      snapshot.docs.map((d) => d.reference).toList(),
      (batch, ref) => batch.delete(ref),
    );
  }

  Future<void> _runChunked(
    List<firestore.DocumentReference<Map<String, dynamic>>> refs,
    void Function(firestore.WriteBatch batch, firestore.DocumentReference<Map<String, dynamic>> ref) op,
  ) async {
    for (var i = 0; i < refs.length; i += kFirestoreMaxWritesPerBatch) {
      final batch = _query.firestore.batch();
      for (final ref in refs.skip(i).take(kFirestoreMaxWritesPerBatch)) {
        op(batch, ref);
      }
      await batch.commit();
    }
  }
}

/// A typed Firestore query.
class Query<
  S extends FirestoreSchema,
  T,
  P extends PatchBuilder<T>,
  F extends FilterBuilderRoot,
  OB extends OrderByBuilderRoot,
  AB extends AggregateBuilderRoot
> extends _QueryOperations<S, T, P, F, OB, AB> {
  Query({
    required firestore.Query<Map<String, dynamic>> query,
    required JsonSerializer<T> toJson,
    required JsonDeserializer<T> fromJson,
    required String? documentIdField,
    required P Function() patchBuilderFactory,
    required F filterBuilder,
    required OB Function(OrderByContext context) orderByBuilderFunc,
    required AB Function(AggregateContext context) aggregateBuilderFunc,
  }) : super(
         query,
         toJson,
         fromJson,
         documentIdField,
         patchBuilderFactory,
         filterBuilder,
         orderByBuilderFunc,
         aggregateBuilderFunc,
       );

  Query<S, T, P, F, OB, AB> where(
    FilterOperation Function(F builder) filterFunc,
  ) {
    final filter = filterFunc(_filterBuilder);
    return _newQuery(QueryFilterHandler.applyFilter(_query, filter));
  }

  OrderedQuery<S, T, O, P, F, OB, AB> orderBy<O extends Record>(
    O Function(OB selector) orderByFunc,
  ) {
    final fields = QueryOrderbyHandler.build(
      orderByFunc: orderByFunc,
      orderByBuilderFunc: _orderByBuilderFunc,
    );
    return OrderedQuery<S, T, O, P, F, OB, AB>(
      query: QueryOrderbyHandler.applyOrderBy(_query, fields),
      orderByFields: fields,
      toJson: _toJson,
      fromJson: _fromJson,
      documentIdField: _documentIdField,
      patchBuilderFactory: _patchBuilderFactory,
      filterBuilder: _filterBuilder,
      orderByBuilderFunc: _orderByBuilderFunc,
      aggregateBuilderFunc: _aggregateBuilderFunc,
    );
  }

  Query<S, T, P, F, OB, AB> limit(int limit) =>
      _newQuery(_query.limit(limit));

  Query<S, T, P, F, OB, AB> limitToLast(int limit) =>
      _newQuery(_query.limitToLast(limit));

  Query<S, T, P, F, OB, AB> _newQuery(
    firestore.Query<Map<String, dynamic>> query,
  ) => Query<S, T, P, F, OB, AB>(
    query: query,
    toJson: _toJson,
    fromJson: _fromJson,
    documentIdField: _documentIdField,
    patchBuilderFactory: _patchBuilderFactory,
    filterBuilder: _filterBuilder,
    orderByBuilderFunc: _orderByBuilderFunc,
    aggregateBuilderFunc: _aggregateBuilderFunc,
  );
}

/// A typed ordered query with pagination.
class OrderedQuery<
  S extends FirestoreSchema,
  T,
  O extends Record,
  P extends PatchBuilder<T>,
  F extends FilterBuilderRoot,
  OB extends OrderByBuilderRoot,
  AB extends AggregateBuilderRoot
> extends _QueryOperations<S, T, P, F, OB, AB> {
  OrderedQuery({
    required firestore.Query<Map<String, dynamic>> query,
    required this.orderByFields,
    required JsonSerializer<T> toJson,
    required JsonDeserializer<T> fromJson,
    required String? documentIdField,
    required P Function() patchBuilderFactory,
    required F filterBuilder,
    required OB Function(OrderByContext context) orderByBuilderFunc,
    required AB Function(AggregateContext context) aggregateBuilderFunc,
  }) : super(
         query,
         toJson,
         fromJson,
         documentIdField,
         patchBuilderFactory,
         filterBuilder,
         orderByBuilderFunc,
         aggregateBuilderFunc,
       );

  /// The orderBy terms this query was built with (single source of truth for
  /// pagination).
  final List<OrderByFieldInfo> orderByFields;

  OrderedQuery<S, T, O, P, F, OB, AB> startAt(O cursor) =>
      _newQuery(QueryPaginationHandler.applyStartAt(_query, cursor));

  OrderedQuery<S, T, O, P, F, OB, AB> startAfter(O cursor) =>
      _newQuery(QueryPaginationHandler.applyStartAfter(_query, cursor));

  OrderedQuery<S, T, O, P, F, OB, AB> endAt(O cursor) =>
      _newQuery(QueryPaginationHandler.applyEndAt(_query, cursor));

  OrderedQuery<S, T, O, P, F, OB, AB> endBefore(O cursor) =>
      _newQuery(QueryPaginationHandler.applyEndBefore(_query, cursor));

  OrderedQuery<S, T, O, P, F, OB, AB> startAtObject(T object) =>
      _newQuery(
        QueryPaginationHandler.applyStartAt(_query, _extract(object)),
      );

  OrderedQuery<S, T, O, P, F, OB, AB> startAfterObject(T object) =>
      _newQuery(
        QueryPaginationHandler.applyStartAfter(_query, _extract(object)),
      );

  OrderedQuery<S, T, O, P, F, OB, AB> endAtObject(T object) =>
      _newQuery(QueryPaginationHandler.applyEndAt(_query, _extract(object)));

  OrderedQuery<S, T, O, P, F, OB, AB> endBeforeObject(T object) =>
      _newQuery(
        QueryPaginationHandler.applyEndBefore(_query, _extract(object)),
      );

  List<Object?> _extract(T object) => OrderByExtractor.extractValues(
    object: object,
    toJson: _toJson,
    fields: orderByFields,
    documentIdFieldName: _documentIdField,
  );

  OrderedQuery<S, T, O, P, F, OB, AB> where(
    FilterOperation Function(F builder) filterFunc,
  ) {
    final filter = filterFunc(_filterBuilder);
    return _newQuery(QueryFilterHandler.applyFilter(_query, filter));
  }

  OrderedQuery<S, T, O, P, F, OB, AB> limit(int limit) =>
      _newQuery(_query.limit(limit));

  OrderedQuery<S, T, O, P, F, OB, AB> limitToLast(int limit) =>
      _newQuery(_query.limitToLast(limit));

  OrderedQuery<S, T, O, P, F, OB, AB> _newQuery(
    firestore.Query<Map<String, dynamic>> query,
  ) => OrderedQuery<S, T, O, P, F, OB, AB>(
    query: query,
    orderByFields: orderByFields,
    toJson: _toJson,
    fromJson: _fromJson,
    documentIdField: _documentIdField,
    patchBuilderFactory: _patchBuilderFactory,
    filterBuilder: _filterBuilder,
    orderByBuilderFunc: _orderByBuilderFunc,
    aggregateBuilderFunc: _aggregateBuilderFunc,
  );
}
