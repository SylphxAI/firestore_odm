import 'dart:async';

/// An interface for inserting new documents into a Firestore collection.
///
/// [T] is the type of the model that will be inserted.
abstract interface class Insertable<T> {
  /// Inserts a new document into the collection.
  ///
  /// The document's ID will be determined by the `id` field within the
  /// provided [value]. If a document with the same ID already exists in the
  /// collection, this operation will fail.
  ///
  /// [value]: The data of the document to be inserted.
  ///
  /// Returns a [Future] that completes when the document has been successfully inserted.
  FutureOr<void> insert(T value);
}
