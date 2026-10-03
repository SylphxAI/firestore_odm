/// Typed, one-shot server-side aggregates backed by the native
/// `AggregateQuery`. There is no streaming aggregate: `cloud_firestore` does
/// not expose server-side aggregate snapshots, and a client-side re-query
/// would silently download every document (the v4 behavior, removed).
library;

import 'backend/odm_backend.dart';
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

/// Deprecated name of [AggregateFieldSelector]; it collides with
/// cloud_firestore's `AggregateField` in files that import both.
@Deprecated('Use AggregateFieldSelector')
typedef AggregateField<T extends num?> = AggregateFieldSelector<T>;

/// Typed aggregate selector for one numeric field.
class AggregateFieldSelector<T extends num?> {
  const AggregateFieldSelector({
    required FieldNode field,
    required AggregateContext context,
  }) : _field = field,
       _context = context;

  final FieldNode _field;
  final AggregateContext _context;

  T sum() => _context.resolve<T>(
    SumOperation('sum:${_field.components.join('.')}', _field),
  );

  /// The average of the field; `double.nan` when no document matches.
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

  final OdmQuery _query;
  final AB Function(AggregateContext context) _builderFunc;
  final R Function(AB selector) _configuration;
  final List<AggregateOperation> _operations;

  /// Executes the aggregate query and returns the typed result record.
  Future<R> get() async {
    final results = await _query.aggregate(_operations);
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

  /// Rejects aggregates beyond Firestore's limit of 30 fields.
  static void validate(List<AggregateOperation> operations) {
    if (operations.length > 30) {
      throw ArgumentError(
        'Firestore supports a maximum of 30 aggregate fields, but '
        '${operations.length} were provided.',
      );
    }
  }
}
