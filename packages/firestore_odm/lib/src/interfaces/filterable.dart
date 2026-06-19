import 'package:firestore_odm/src/filter_builder.dart';

/// An interface for applying filters to a Firestore query.
///
/// [T] is the type of the model for the collection being queried.
abstract interface class Filterable<T> {
  /// Filters the query using a strongly-typed filter builder.
  ///
  /// This method allows you to construct complex `where` clauses using a
  /// type-safe approach. The [filterBuilder] function provides a
  /// [FilterBuilderRoot] that enables access to the fields of type [T]
  /// for comparison.
  ///
  /// [filterBuilder]: A function that builds the [FirestoreFilter] based on
  /// the schema of type [T].
  ///
  /// Returns a dynamic type representing the query with the applied filter.
  dynamic where(
    FilterOperation Function(FilterBuilderRoot builder) filterBuilder,
  );
}
