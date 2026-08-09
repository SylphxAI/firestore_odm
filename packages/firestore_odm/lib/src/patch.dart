/// The v5 patch surface: exactly six operations, each mapping 1:1 to a
/// Firestore `FieldValue` or `update` primitive. There is no operation DSL,
/// no precedence resolution, no client-side emulation.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'field_selector.dart';
import 'types.dart';

/// A single patch operation applied at [field] (a dotted path relative to the
/// document).
sealed class UpdateOperation {
  const UpdateOperation(this.field);

  final FieldNode field;

  @override
  String toString() => '$runtimeType(${field.components.join('.')})';
}

/// Sets [value] at [field]. Top-level fields are replaced; nested map paths
/// follow Firestore's native `update` merge semantics.
class SetOperation extends UpdateOperation {
  const SetOperation(super.field, this.value);

  final Object? value;
}

/// Deletes [field].
class DeleteOperation extends UpdateOperation {
  const DeleteOperation(super.field);
}

/// Atomically increments the numeric value at [field] by [delta].
class IncrementOperation extends UpdateOperation {
  const IncrementOperation(super.field, this.delta);

  final num delta;
}

/// Atomically adds [values] to the array at [field] (deduplicated server-side).
class ArrayUnionOperation extends UpdateOperation {
  const ArrayUnionOperation(super.field, this.values);

  final List<Object?> values;
}

/// Atomically removes [values] from the array at [field].
class ArrayRemoveOperation extends UpdateOperation {
  const ArrayRemoveOperation(super.field, this.values);

  final List<Object?> values;
}

/// Sets [field] to the server timestamp at write time.
class ServerTimestampOperation extends UpdateOperation {
  const ServerTimestampOperation(super.field);
}

/// Converts patch operations to the native `update` map keyed by [FieldPath].
///
/// Returns an empty map when there is nothing to apply.
Map<Object, Object?> operationsToMap(List<UpdateOperation> operations) {
  final result = <Object, Object?>{};
  for (final op in operations) {
    result[op.field.components.join('.')] = switch (op) {
      SetOperation(:final value) => value,
      DeleteOperation() => firestore.FieldValue.delete(),
      IncrementOperation(:final delta) => firestore.FieldValue.increment(delta),
      ArrayUnionOperation(:final values) => firestore.FieldValue.arrayUnion(
        values,
      ),
      ArrayRemoveOperation(:final values) => firestore.FieldValue.arrayRemove(
        values,
      ),
      ServerTimestampOperation() => firestore.FieldValue.serverTimestamp(),
    };
  }
  return result;
}

/// Base class for generated patch builders. Instances are stateless
/// path-namespaces; the actual operations are produced by the field-update
/// objects returned from the builder's getters.
abstract class PatchBuilder<T> {
  const PatchBuilder();
}

/// Per-field update handle for non-specialized fields: `set` and `delete`.
class FieldUpdate<T> {
  const FieldUpdate({required FieldNode field, required FieldToJson<T> toJson})
    : _field = field,
      _toJson = toJson;

  final FieldNode _field;
  final FieldToJson<T> _toJson;

  SetOperation set(T value) => SetOperation(_field, _toJson(value));

  DeleteOperation delete() => DeleteOperation(_field);
}

/// Numeric fields additionally support atomic `increment`.
class NumericFieldUpdate<T extends num> extends FieldUpdate<T> {
  const NumericFieldUpdate({required super.field, required super.toJson});

  IncrementOperation increment(T delta) => IncrementOperation(_field, delta);
}

/// DateTime fields additionally support server timestamps.
class DateTimeFieldUpdate extends FieldUpdate<DateTime> {
  const DateTimeFieldUpdate({required super.field, required super.toJson});

  ServerTimestampOperation serverTimestamp() =>
      ServerTimestampOperation(_field);
}

/// List fields additionally support atomic array union/remove.
class ListFieldUpdate<T> extends FieldUpdate<List<T>> {
  const ListFieldUpdate({
    required super.field,
    required super.toJson,
    required FieldToJson<T> elementToJson,
  }) : _elementToJson = elementToJson;

  final FieldToJson<T> _elementToJson;

  ArrayUnionOperation arrayUnion(Iterable<T> values) =>
      ArrayUnionOperation(_field, values.map(_elementToJson).toList());

  ArrayRemoveOperation arrayRemove(Iterable<T> values) =>
      ArrayRemoveOperation(_field, values.map(_elementToJson).toList());
}
