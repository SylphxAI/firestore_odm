/// Typed query filters. Each generated selector exposes the full set of
/// Firestore comparison operators through a single `call` — no string paths.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'field_selector.dart';
import 'types.dart';

/// A composable filter operation backed by a native [firestore.Filter].
sealed class FilterOperation {
  firestore.Filter toFilter();
}

extension FilterOperationComposition on FilterOperation {
  FilterOperation and(FilterOperation other) =>
      _CombinedOperation.and(this, other);

  FilterOperation or(FilterOperation other) =>
      _CombinedOperation.or(this, other);

  FilterOperation operator &(FilterOperation other) => and(other);

  FilterOperation operator |(FilterOperation other) => or(other);
}

final class _CombinedOperation implements FilterOperation {
  const _CombinedOperation.and(this.left, this.right) : isAnd = true;

  const _CombinedOperation.or(this.left, this.right) : isAnd = false;

  final FilterOperation left;
  final FilterOperation right;
  final bool isAnd;

  @override
  firestore.Filter toFilter() => isAnd
      ? firestore.Filter.and(left.toFilter(), right.toFilter())
      : firestore.Filter.or(left.toFilter(), right.toFilter());
}

final class _FieldFilterOperation implements FilterOperation {
  const _FieldFilterOperation(this._build);

  final firestore.Filter Function() _build;

  @override
  firestore.Filter toFilter() => _build();
}

/// A typed filter selector for a single field.
class FilterField<T> {
  const FilterField({required FieldNode field, required FieldToJson<T> toJson})
    : _field = field,
      _toJson = toJson;

  final FieldNode _field;
  final FieldToJson<T> _toJson;

  FilterOperation call({
    T? isEqualTo,
    T? isNotEqualTo,
    T? isLessThan,
    T? isLessThanOrEqualTo,
    T? isGreaterThan,
    T? isGreaterThanOrEqualTo,
    T? arrayContains,
    List<T>? arrayContainsAny,
    List<T>? whereIn,
    List<T>? whereNotIn,
    bool? isNull,
  }) {
    final field = _field.fieldPath;
    final conditions = [
      isEqualTo,
      isNotEqualTo,
      isLessThan,
      isLessThanOrEqualTo,
      isGreaterThan,
      isGreaterThanOrEqualTo,
      arrayContains,
      arrayContainsAny,
      whereIn,
      whereNotIn,
    ].where((e) => e != null).length;
    if (conditions + (isNull == null ? 0 : 1) != 1) {
      throw ArgumentError(
        'Filter on ${_field.components.join('.')} requires exactly one condition',
      );
    }
    return _FieldFilterOperation(
      () => firestore.Filter(
        field,
        isEqualTo: isEqualTo == null ? null : _toJson(isEqualTo),
        isNotEqualTo: isNotEqualTo == null ? null : _toJson(isNotEqualTo),
        isLessThan: isLessThan == null ? null : _toJson(isLessThan),
        isLessThanOrEqualTo: isLessThanOrEqualTo == null
            ? null
            : _toJson(isLessThanOrEqualTo),
        isGreaterThan: isGreaterThan == null ? null : _toJson(isGreaterThan),
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo == null
            ? null
            : _toJson(isGreaterThanOrEqualTo),
        arrayContains: arrayContains == null ? null : _toJson(arrayContains),
        arrayContainsAny: arrayContainsAny == null
            ? null
            : arrayContainsAny.map(_toJson).toList(),
        whereIn: whereIn == null ? null : whereIn.map(_toJson).toList(),
        whereNotIn: whereNotIn == null ? null : whereNotIn.map(_toJson).toList(),
        isNull: isNull,
      ),
    );
  }
}

/// Base class for generated filter builders; carries the path prefix.
abstract class FilterBuilderRoot extends SelectorRoot {
  const FilterBuilderRoot({super.field});
}

/// Applies a built filter to a native query.
abstract final class QueryFilterHandler {
  static firestore.Query<Map<String, dynamic>> applyFilter(
    firestore.Query<Map<String, dynamic>> query,
    FilterOperation filter,
  ) {
    return query.where(filter.toFilter());
  }
}
