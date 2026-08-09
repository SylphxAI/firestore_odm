/// Typed, one-shot server-side aggregates backed by the native
/// `AggregateQuery`. There is no streaming aggregate: `cloud_firestore` does
/// not expose server-side aggregate snapshots, and a client-side re-query
/// would silently download every document (the v4 behavior, removed).
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'field_selector.dart';
import 'utils.dart';

/// Context that records the aggregate operations of an aggregate builder.
abstract class AggregateContext {
  R resolve<R extends num?>(AggregateOperation operation);
}

final class AggregateBuilderContext implements AggregateContext {
  final List<AggregateOperation> operations = [];

  @override
  R resolve<R extends num?>(AggregateOperation operation) {
    operations.add(operation);
    return defaultValue<R>();
  }
}

final class AggregateResultContext implements AggregateContext {
  AggregateResultContext(this.results);

  final Map<String, Object?> results;

  @override
  R resolve<R extends num?>(AggregateOperation operation) {
    final value = results[operation.key];
    if (value == null) {
      throw ArgumentError(
        'No result found for aggregate operation "${operation.key}"',
      );
    }
    if (value is R) return value as R;
    if (value is num) {
      if (R == int) return value.toInt() as R;
      if (R == double) return value.toDouble() as R;
    }
    throw ArgumentError(
      'Expected $R but found ${value.runtimeType} for operation ${operation.key}',
    );
  }
}

/// Base class for aggregate operations.
sealed class AggregateOperation {
  const AggregateOperation(this.key);

  /// Unique key within one aggregate query (derived from field + operation).
  final String key;
}

final class CountOperation extends AggregateOperation {
  const CountOperation(super.key);
}

final class SumOperation extends AggregateOperation {
  const SumOperation(super.key, this.field);

  final FieldNode field;
}

final class AverageOperation extends AggregateOperation {
  const AverageOperation(super.key, this.field);

  final FieldNode field;
}

/// Root of a generated aggregate builder; provides `count()`.
abstract class AggregateBuilderRoot extends SelectorRoot {
  const AggregateBuilderRoot({super.field});

  int count() =>
      throw UnsupportedError('count() must be overridden by generated code');
}

/// Typed aggregate selector for one numeric field.
class AggregateField<T extends num?> {
  const AggregateField({
    required FieldNode field,
    required AggregateContext context,
  }) : _field = field,
       _context = context;

  final FieldNode _field;
  final AggregateContext _context;

  T sum() => _context.resolve<T>(
    SumOperation('sum:${_field.components.join('.')}', _field),
  );

  double average() => _context.resolve<double>(
    AverageOperation('avg:${_field.components.join('.')}', _field),
  );

}

/// The result of an aggregate query; one-shot only.
class AggregateQuery<R extends Record, AB extends AggregateBuilderRoot> {
  AggregateQuery(
    this._query,
    this._builderFunc,
    this._configuration,
    List<AggregateOperation> operations,
  ) : _operations = List.unmodifiable(operations);

  final firestore.AggregateQuery _query;
  final AB Function(AggregateContext context) _builderFunc;
  final R Function(AB selector) _configuration;
  final List<AggregateOperation> _operations;

  /// Executes the aggregate query and returns the typed result record.
  Future<R> get() async {
    final snapshot = await _query.get();
    final results = <String, Object?>{
      for (final op in _operations)
        op.key: switch (op) {
          CountOperation() => snapshot.count ?? 0,
          SumOperation(:final field) => snapshot.getSum(
            field.components.join('.'),
          ),
          AverageOperation(:final field) => snapshot.getAverage(
            field.components.join('.'),
          ),
        },
    };
    final context = AggregateResultContext(results);
    final builder = _builderFunc(context);
    return _configuration(builder);
  }
}

/// Builds and applies aggregate terms from a generated builder.
abstract final class QueryAggregatableHandler {
  static List<AggregateOperation> build<AB extends AggregateBuilderRoot>({
    required Object Function(AB selector) aggregateFunc,
    required AB Function(AggregateContext context) aggregateBuilderFunc,
  }) {
    final context = AggregateBuilderContext();
    final builder = aggregateBuilderFunc(context);
    aggregateFunc(builder);
    return context.operations;
  }

  static firestore.AggregateQuery applyAggregate(
    firestore.Query<Map<String, dynamic>> query,
    List<AggregateOperation> operations,
  ) {
    final fields = <firestore.AggregateField>[
      for (final op in operations)
        switch (op) {
          CountOperation() => firestore.count(),
          SumOperation(:final field) => firestore.sum(
            field.components.join('.'),
          ),
          AverageOperation(:final field) => firestore.average(
            field.components.join('.'),
          ),

        },
    ];
    if (fields.length > 30) {
      throw ArgumentError(
        'Firestore supports a maximum of 30 aggregate fields, but '
        '${fields.length} were provided.',
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
}
