import 'package:firestore_odm/firestore_odm.dart';

/// An interface for ordering the results of a Firestore query.
///
/// [T] is the type of the model in the collection being queried.
abstract interface class Orderable<T> {
  /// Orders the query results by specified fields, which is essential for
  /// efficient pagination.
  ///
  /// This method allows you to define one or more fields by which to sort the
  /// documents. The [orderBuilder] provides access to the document fields in
  /// a type-safe manner, and the returned record/tuple [O] specifies the
  /// fields and their sort directions (ascending or descending).
  ///
  /// The ordering defined here is crucial for enabling strongly-typed cursor-based
  /// pagination using the methods available in [Paginatable].
  ///
  /// [orderBuilder]: A function that constructs the order-by clause using an
  /// [OrderByFieldSelector].
  ///
  /// Returns a dynamic type that represents an `OrderedQuery` that supports
  /// strongly-typed pagination.
  OrderedQuery<
    FirestoreSchema,
    T,
    O,
    PatchBuilder<T, Map<String, dynamic>?>,
    FilterBuilderRoot,
    OrderByFieldNode,
    AggregateBuilderRoot
  >
  orderBy<O extends Record>(
    O Function(OrderByFieldNode builder) orderByEntries,
  );
}
