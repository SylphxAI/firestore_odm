import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/aggregate.dart';
import 'package:firestore_odm/src/field_selector.dart';
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/interfaces/aggregatable.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/filterable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/limitable.dart';
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'package:firestore_odm/src/types.dart' show FieldPath;
import 'package:firestore_odm/src/interfaces/paginatable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/pagination.dart';
import 'package:firestore_odm/src/services/update_operations_service.dart';
import 'package:firestore_odm/src/utils.dart';

typedef OrderByBuilderFunc<OB extends OrderByFieldNode> =
    OB Function({required OrderByContext context, required FieldPath field});

class OrderByFieldNode extends Node {
  final OrderByContext $context;

  /// Creates a new OrderByFieldNode with the given context
  const OrderByFieldNode({super.field, required OrderByContext context})
    : $context = context;
}

class OrderByField<T> extends OrderByFieldNode {
  final T? _defaultValue;
  
  OrderByField({super.field, required super.context, T? defaultValue})
      : _defaultValue = defaultValue;

  T call({bool descending = false}) {
    $context.resolver(field, descending);
    return _defaultValue ?? defaultValue<T>();
  }
}

/// Base class for orderBy field selectors
abstract class OrderByContext {
  void resolver(FieldPath field, bool descending);
}

class OrderByBuilderContext implements OrderByContext {
  OrderByBuilderContext();

  final List<OrderByFieldInfo> fields = [];

  @override
  void resolver(FieldPath field, bool descending) {
    fields.add(OrderByFieldInfo(field, descending));
  }
}

class OrderByExtractorContext implements OrderByContext {
  OrderByExtractorContext({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
  final List<dynamic> extractedValues = [];

  @override
  void resolver(FieldPath field, bool descending) {
    final value = resolveJsonWithParts(data, id, field);
    extractedValues.add(value);
  }
}

/// Information about an orderBy field for pagination
class OrderByFieldInfo {
  final FieldPath field; // Can be String or FieldPath
  final bool descending;

  const OrderByFieldInfo(this.field, this.descending);

  @override
  String toString() => 'OrderByFieldInfo($field, desc: $descending)';
}

/// Container for orderBy configuration used in pagination
class OrderByConfiguration<O extends Record, OB extends OrderByFieldNode> {
  final List<OrderByFieldInfo> fields;
  final O Function(OB selector) builder;

  const OrderByConfiguration(this.fields, this.builder);

  @override
  String toString() => 'OrderByConfiguration(${fields.join(', ')})';
}

abstract class QueryOrderbyHandler {
  static OrderByConfiguration<O, OB>
  buildOrderBy<T, O extends Record, OB extends OrderByFieldNode>({
    required O Function(OB selector) orderByFunc,
    required OB Function(OrderByContext context) orderByBuilderFunc,
    required String documentIdFieldName,
  }) {
    final context = OrderByBuilderContext();
    final builder = orderByBuilderFunc(context);

    // Call the order builder to populate the selector
    orderByFunc(builder);

    return OrderByConfiguration<O, OB>(context.fields, orderByFunc);
  }

  static firestore.Query<Map<String, dynamic>> applyOrderBy<
    T,
    O extends Record
  >(firestore.Query<Map<String, dynamic>> query, OrderByConfiguration config) {
    // Build the actual Firestore query from the collected fields
    firestore.Query<Map<String, dynamic>> newQuery = query;
    for (final info in config.fields) {
      newQuery = newQuery.orderBy(
        info.field.toFirestore(),
        descending: info.descending,
      );
    }

    return newQuery;
  }
}

class OrderedQuery<
  S extends FirestoreSchema,
  T,
  O extends Record,
  P extends PatchBuilder<T, Map<String, dynamic>?>,
  F extends FilterBuilderRoot,
  OB extends OrderByFieldNode,
  AB extends AggregateBuilderRoot
>
    implements
        Gettable<List<T>>,
        Streamable<List<T>>,
        Paginatable<T, O>,
        Limitable,
        Filterable<T>,
        Patchable<T>,
        Modifiable<T>,
        Aggregatable<T>,
        Deletable {
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;

  final String _documentIdField;

  /// The underlying Firestore query
  final firestore.Query<Map<String, dynamic>> _query;

  final OrderByConfiguration<O, OB> _orderByConfig;

  final P _patchBuilder;

  final F _filterBuilder;

  final OB Function(OrderByContext context) _orderByBuilderFunc;

  final AB Function(AggregateContext context) _aggregateBuilderFunc;

  const OrderedQuery({
    required firestore.Query<Map<String, dynamic>> query,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required String documentIdField,
    required OrderByConfiguration<O, OB> orderByConfig,
    required P patchBuilder,
    required F filterBuilder,
    required OB Function(OrderByContext context) orderByBuilderFunc,
    required AB Function(AggregateContext context) aggregateBuilderFunc,
  }) : _query = query,
       _toJson = toJson,
       _fromJson = fromJson,
       _documentIdField = documentIdField,
       _orderByConfig = orderByConfig,
       _patchBuilder = patchBuilder,
       _filterBuilder = filterBuilder,
       _orderByBuilderFunc = orderByBuilderFunc,
       _aggregateBuilderFunc = aggregateBuilderFunc;

  @override
  Future<List<T>> get() =>
      QueryHandler.get(_query, _fromJson, _documentIdField);

  @override
  Stream<List<T>?> get stream =>
      QueryHandler.stream(_query, _fromJson, _documentIdField);

  OrderedQuery<S, T, O, P, F, OB, AB> _newQuery(
    firestore.Query<Map<String, dynamic>> newQuery,
  ) {
    return OrderedQuery<S, T, O, P, F, OB, AB>(
      query: newQuery,
      toJson: _toJson,
      fromJson: _fromJson,
      documentIdField: _documentIdField,
      orderByConfig: _orderByConfig,
      filterBuilder: _filterBuilder,
      patchBuilder: _patchBuilder,
      orderByBuilderFunc: _orderByBuilderFunc,
      aggregateBuilderFunc: _aggregateBuilderFunc,
    );
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> limit(int limit) {
    final newQuery = QueryLimitHandler.applyLimit(_query, limit);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> limitToLast(int limit) {
    final newQuery = QueryLimitHandler.applyLimitToLast(_query, limit);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> endAt(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyEndAt(_query, cursors);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> endAtObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyEndAt(_query, values);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> endBefore(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyEndBefore(_query, cursors);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> endBeforeObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyEndBefore(_query, values);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> startAfter(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyStartAfter(_query, cursors);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> startAfterObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyStartAfter(_query, values);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> startAt(O cursorValues) {
    final cursors = QueryPaginationHandler.build(cursorValues);
    final newQuery = QueryPaginationHandler.applyStartAt(_query, cursors);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> startAtObject(T object) {
    final values = QueryPaginationHandler.buildValuesFromObject(
      object: object,
      toJson: _toJson,
      orderByFunc: _orderByConfig.builder,
      documentIdFieldName: _documentIdField,
      orderBuilderFunc: _orderByBuilderFunc,
    );
    final newQuery = QueryPaginationHandler.applyStartAt(_query, values);
    return _newQuery(newQuery);
  }

  @override
  OrderedQuery<S, T, O, P, F, OB, AB> where(
    FilterOperation Function(F builder) filterBuilder,
  ) {
    final filter = QueryFilterHandler.buildFilter(
      filterBuilder: filterBuilder,
      builderRoot: _filterBuilder,
    );
    final newQuery = QueryFilterHandler.applyFilter(_query, filter);
    return _newQuery(newQuery);
  }

  @override
  Future<void> patch(List<UpdateOperation> Function(P patchBuilder) patches) {
    final operations = patches(_patchBuilder);
    return QueryHandler.patch(_query, operations);
  }

  /// Modify multiple documents in this ordered query using diff-based updates.
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
  /// // Update top users with atomic operations (default)
  /// await db.users
  ///   .orderBy(($) => $.score(descending: true))
  ///   .limit(10)
  ///   .modify((user) => user.copyWith(
  ///     bonus: user.bonus + 100, // Auto-detects -> FieldValue.increment(100)
  ///   ));
  /// ```
  @override
  Future<void> modify(ModifierBuilder<T> modifier, {bool atomic = true}) =>
      QueryHandler.modify(
        _query,
        _documentIdField,
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
      _documentIdField,
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
