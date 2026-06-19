import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/field_selector.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/types.dart';
import 'package:firestore_odm/src/utils.dart';

typedef AggregateBuilderFunc<AB extends AggregateFieldNode> =
    AB Function({required AggregateContext context, required FieldPath field});

abstract class AggregateContext {
  R resolve<R extends num?>(AggregateOperation operation);
}

class AggregateBuilderContext extends AggregateContext {
  final List<AggregateOperation> operations = [];

  @override
  R resolve<R extends num?>(AggregateOperation operation) {
    operations.add(operation);
    return defaultValue<R>();
  }
}

class AggregateResultContext extends AggregateContext {
  final Map<String, dynamic> results;

  AggregateResultContext(this.results);

  @override
  R resolve<R extends num?>(AggregateOperation operation) {
    if (results.containsKey(operation.key)) {
      final value = results[operation.key];
      return value is R
          ? value
          : R == int
          ? (value as num).toInt() as R
          : R == double
          ? (value as num).toDouble() as R
          : throw ArgumentError(
              'Expected type $R but found ${value.runtimeType} for operation: ${operation.key}',
            );
    } else {
      throw ArgumentError('No result found for operation: ${operation.key}');
    }
  }
}

/// Selector that provides strongly-typed field access for aggregations
abstract class AggregateFieldNode extends Node {
  final AggregateContext $context;
  const AggregateFieldNode({super.field, required AggregateContext context})
    : $context = context;
}

abstract class AggregateBuilderRoot extends AggregateFieldNode {
  const AggregateBuilderRoot({super.field, required super.context});

  /// Get count of documents
  int count();
}

mixin AggregateRootMixin on AggregateFieldNode implements AggregateBuilderRoot {
  /// Get count of documents
  int count() {
    return $context.resolve(CountOperation('count'));
  }
}

class AggregateField<T extends num?> extends AggregateFieldNode {
  /// Creates a new aggregate field node for a specific field type.
  ///
  /// [name] - The name of the field in the document
  /// [context] - The aggregate context used to resolve operations
  const AggregateField({required super.field, required super.context});

  /// Get sum of this field
  T sum() {
    return $context.resolve<T>(SumOperation('sum:${path}', path));
  }

  /// Get average of this field
  double average() {
    return $context.resolve<double>(AverageOperation('avg:${path}', path));
  }
}

/// Configuration for aggregate operations on a Firestore collection.
///
/// This class holds the aggregate operations to be performed and the builder
/// function that defines how to construct the result record from the aggregated data.
///
/// Type parameters:
/// - [T]: The document type being aggregated
/// - [R]: The result record type containing the aggregated values
class AggregateConfiguration<R, AB extends AggregateBuilderRoot> {
  /// List of aggregate operations to be performed
  final List<AggregateOperation> operations;

  /// Builder function that constructs the result record
  final R Function(AB selector) aggregates;

  /// Creates a new aggregate configuration.
  ///
  /// [operations] - The list of aggregate operations to perform
  /// [aggregates] - Function that builds the result record from aggregated data
  AggregateConfiguration(this.operations, this.aggregates);
}

abstract class QueryAggregatableHandler {
  static firestore.AggregateQuery applyCount(
    firestore.Query<Map<String, dynamic>> query,
  ) {
    return query.count();
  }

  static AggregateConfiguration<R, AB>
  buildAggregate<T, R extends Record, AB extends AggregateBuilderRoot>(
    R Function(AB selector) aggregates,
    AB Function(AggregateContext context) builderFunc,
  ) {
    // Create the selector and build the aggregate specification
    final context = AggregateBuilderContext();
    final builder = builderFunc(context);
    aggregates(builder);
    return AggregateConfiguration(context.operations, aggregates);
  }

  static firestore.AggregateQuery applyAggregate<R extends Record>(
    firestore.Query<Map<String, dynamic>> query,
    List<AggregateOperation> operations,
  ) {
    // Build the aggregate query using the operations collected
    final fields = operations
        .map(
          (op) => switch (op) {
            CountOperation() => firestore.count(),
            SumOperation(:final field) => firestore.sum(field.path),
            AverageOperation(:final field) => firestore.average(field.path),
          },
        )
        .toList();
    // Create the aggregate query using native Firestore API
    // Firestore supports up to 30 aggregate fields
    if (fields.length > 30) {
      throw ArgumentError(
        'Firestore supports a maximum of 30 aggregate fields, but ${fields.length} were provided.',
      );
    }

    return query.aggregate(
      fields[0],
      fields.length > 1 ? fields[1] : null,
      fields.length > 2 ? fields[2] : null,
      fields.length > 3 ? fields[3] : null,
      fields.length > 4 ? fields[4] : null,
      fields.length > 5 ? fields[5] : null,
      fields.length > 6 ? fields[6] : null,
      fields.length > 7 ? fields[7] : null,
      fields.length > 8 ? fields[8] : null,
      fields.length > 9 ? fields[9] : null,
      fields.length > 10 ? fields[10] : null,
      fields.length > 11 ? fields[11] : null,
      fields.length > 12 ? fields[12] : null,
      fields.length > 13 ? fields[13] : null,
      fields.length > 14 ? fields[14] : null,
      fields.length > 15 ? fields[15] : null,
      fields.length > 16 ? fields[16] : null,
      fields.length > 17 ? fields[17] : null,
      fields.length > 18 ? fields[18] : null,
      fields.length > 19 ? fields[19] : null,
      fields.length > 20 ? fields[20] : null,
      fields.length > 21 ? fields[21] : null,
      fields.length > 22 ? fields[22] : null,
      fields.length > 23 ? fields[23] : null,
      fields.length > 24 ? fields[24] : null,
      fields.length > 25 ? fields[25] : null,
      fields.length > 26 ? fields[26] : null,
      fields.length > 27 ? fields[27] : null,
      fields.length > 28 ? fields[28] : null,
      fields.length > 29 ? fields[29] : null,
    );
  }

  static Future<R> get<T, R, AB extends AggregateBuilderRoot>(
    firestore.AggregateQuery query,
    AB Function(AggregateContext context) builderFunc,
    AggregateConfiguration<R, AB> configuration,
  ) async {
    return query.get().then((snapshot) {
      // Build the result record from the snapshot
      return _buildResultRecordFromSnapshot(
        snapshot,
        builderFunc,
        configuration,
      );
    });
  }

  static R
  _buildResultRecordFromSnapshot<T, R, AB extends AggregateBuilderRoot>(
    firestore.AggregateQuerySnapshot snapshot,
    AB Function(AggregateContext context) builderFunc,
    AggregateConfiguration<R, AB> configuration,
  ) {
    final results = {
      for (final op in configuration.operations)
        op.key: switch (op) {
          CountOperation() => snapshot.count ?? 0,
          SumOperation(:final field) => snapshot.getSum(field.path) ?? 0,
          AverageOperation(:final field) =>
            snapshot.getAverage(field.path) ?? 0.0,
        },
    };

    return _buildResultRecord(
      results: results,
      builderFunc: builderFunc,
      configuration: configuration,
    );
  }

  static Stream<R> stream<T, R, AB extends AggregateBuilderRoot>(
    firestore.AggregateQuery query,
    Map<String, dynamic> Function(T) _toJson,
    T Function(Map<String, dynamic>) _fromJson,
    String _documentIdField,
    AB Function(AggregateContext context) builderFunc,
    AggregateConfiguration<R, AB> configuration,
  ) {
    return (query.query as firestore.Query<Map<String, dynamic>>)
        .snapshots()
        .map(
          (snapshot) =>
              processQuerySnapshot(snapshot, _fromJson, _documentIdField),
        )
        .map(
          (data) => _calculateAggregationsFromSnapshot(
            data,
            configuration.operations,
            _toJson,
          ),
        )
        .map((data) {
          return _buildResultRecord(
            results: data,
            builderFunc: builderFunc,
            configuration: configuration,
          );
        });
  }

  static R _buildResultRecord<T, R, AB extends AggregateBuilderRoot>({
    required Map<String, dynamic> results,
    required AB Function(AggregateContext context) builderFunc,
    required AggregateConfiguration<R, AB> configuration,
  }) {
    final context = AggregateResultContext(results);
    final builder = builderFunc(context);
    return configuration.aggregates(builder);
  }

  /// Calculate aggregations from snapshot for streaming
  static Map<String, dynamic> _calculateAggregationsFromSnapshot<T>(
    List<T> snapshot,
    List<AggregateOperation> operations,
    Map<String, dynamic> Function(T) toJson,
  ) {
    final results = <String, dynamic>{};

    // Count operations - can use snapshot length
    final countOps = operations.whereType<CountOperation>().toList();
    final count = snapshot.length;
    for (final op in countOps) {
      results[op.key] = count;
    }

    // For sum/average, parse documents manually
    final sumOps = operations.whereType<SumOperation>().toList();
    final avgOps = operations.whereType<AverageOperation>().toList();

    if (sumOps.isNotEmpty || avgOps.isNotEmpty) {
      // Calculate sums
      for (final op in sumOps) {
        results[op.key] = _calculateSum(snapshot, op.field, toJson);
      }

      // Calculate averages
      for (final op in avgOps) {
        results[op.key] = _calculateAverage(snapshot, op.field, toJson);
      }
    }

    return results;
  }

  /// Calculate sum for a field path
  static num _calculateSum<T>(
    List<T> documents,
    PathFieldPath field,
    Map<String, dynamic> Function(T) toJson,
  ) {
    num total = 0;
    for (final doc in documents) {
      final json = toJson(doc);
      final value = _getNestedValue(json, field);
      if (value is num) {
        total += value;
      }
    }
    return total;
  }

  /// Calculate average for a field path
  static double _calculateAverage<T>(
    List<T> documents,
    PathFieldPath field,
    Map<String, dynamic> Function(T) toJson,
  ) {
    num total = 0;
    int count = 0;
    for (final doc in documents) {
      final json = toJson(doc);
      final value = _getNestedValue(json, field);
      if (value is num) {
        total += value;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  /// Get nested value from JSON using dot notation
  static dynamic _getNestedValue(
    Map<String, dynamic> json,
    PathFieldPath field,
  ) {
    dynamic current = json;
    for (final part in field.components) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

/// Base class for aggregate operations.
///
/// All aggregate operations (count, sum, average) extend this class
/// and provide a unique key for identifying the operation result.
sealed class AggregateOperation {
  /// Unique identifier for this aggregate operation
  final String key;

  /// Creates a new aggregate operation with the given key.
  ///
  /// [key] - Unique identifier for this operation
  const AggregateOperation(this.key);
}

/// Count operation that counts the number of documents.
class CountOperation extends AggregateOperation {
  /// Creates a count operation.
  ///
  /// [key] - Unique identifier for this operation
  const CountOperation(String key) : super(key);
}

/// Sum operation that calculates the sum of numeric values in a field.
class SumOperation extends AggregateOperation {
  /// The field path to sum values from
  final PathFieldPath field;

  /// Creates a sum operation.
  ///
  /// [key] - Unique identifier for this operation
  /// [fieldPath] - The field path to sum values from
  const SumOperation(String key, this.field) : super(key);
}

/// Average operation that calculates the average of numeric values in a field.
class AverageOperation extends AggregateOperation {
  /// The field path to calculate average from
  final PathFieldPath field;

  /// Creates an average operation.
  ///
  /// [key] - Unique identifier for this operation
  /// [fieldPath] - The field path to calculate average from
  const AverageOperation(String key, this.field) : super(key);
}

/// A query that performs aggregate operations on a Firestore collection.
///
/// This class provides methods to execute aggregate queries and get results
/// either as a one-time operation or as a real-time stream.
///
/// Type parameters:
/// - [S]: The Firestore schema type
/// - [T]: The document type being aggregated
/// - [R]: The result record type containing aggregated values
class AggregateQuery<T, R, AB extends AggregateBuilderRoot>
    implements Gettable<R>, Streamable<R> {
  /// Creates a new aggregate query.
  ///
  /// [query] - The underlying Firestore aggregate query
  /// [_converter] - Model converter for document serialization
  /// [_documentIdField] - The document ID field name
  /// [_configuration] - The aggregate configuration
  AggregateQuery(
    this.query,
    this._toJson,
    this._fromJson,
    this._documentIdField,
    this._configuration,
    this._builderFunc,
  );

  /// Model converter for document serialization (used in streaming)
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;

  /// The document ID field name (used in streaming)
  final String _documentIdField;

  /// The underlying Firestore aggregate query
  final firestore.AggregateQuery query;

  /// The aggregate configuration defining operations and result building
  final AggregateConfiguration<R, AB> _configuration;

  final AB Function(AggregateContext context) _builderFunc;

  /// Executes the aggregate query and returns the result.
  ///
  /// Returns a [Future] that completes with the aggregated result record.
  Future<R> get() =>
      QueryAggregatableHandler.get(query, _builderFunc, _configuration);

  @override
  /// Returns a stream that emits aggregated results in real-time.
  ///
  /// The stream will emit new aggregated values whenever the underlying
  /// collection changes in a way that affects the query results.
  Stream<R> get stream => QueryAggregatableHandler.stream(
    query,
    _toJson,
    _fromJson,
    _documentIdField,
    _builderFunc,
    _configuration,
  );
}

/// A query that performs count aggregation on a Firestore collection.
///
/// This class provides methods to get the count of documents matching
/// a query either as a one-time operation or as a real-time stream.
class AggregateCountQuery implements Gettable<int>, Streamable<int> {
  /// Creates a new aggregate count query.
  ///
  /// [query] - The underlying Firestore aggregate query
  AggregateCountQuery(this.query);

  /// The underlying Firestore aggregate query
  final firestore.AggregateQuery query;

  /// Executes the aggregate query and returns the count result.
  ///
  /// Returns a [Future] that completes with the number of documents
  /// matching the query criteria.
  Future<int> get() => query.get().then((snapshot) {
    // Firestore's count query returns a single integer
    return snapshot.count ?? 0;
  });

  @override
  /// Returns a stream that emits the count of documents matching the query.
  ///
  /// The stream will emit a new count value whenever the underlying
  /// collection changes in a way that affects the query results.
  Stream<int> get stream =>
      (query.query as firestore.Query<Map<String, dynamic>>).snapshots().map((
        snapshot,
      ) {
        return snapshot.docs.length;
      });
}
