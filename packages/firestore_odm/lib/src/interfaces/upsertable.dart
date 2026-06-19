import 'dart:async';

/// An interface for performing "upsert" operations on documents in a Firestore collection.
///
/// An upsert operation creates a new document if it does not exist, or updates
/// an existing document if it does.
///
/// [T] is the type of the model that will be used for the upsert operation.
abstract interface class Upsertable<T> {
  /// Upserts a document into the collection.
  ///
  /// The document's ID will be determined by the `id` field within the
  /// provided [value].
  ///
  /// If a document with the same ID already exists, its data will be updated
  /// with the provided [value]. If no such document exists, a new document
  /// will be created with the provided ID and data.
  ///
  /// [value]: The data of the document to be upserted.
  ///
  /// Returns a [Future] that completes when the document has been successfully
  /// upserted.
  FutureOr<void> upsert(T value);
}
