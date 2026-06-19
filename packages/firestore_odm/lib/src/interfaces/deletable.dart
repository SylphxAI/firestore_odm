import 'dart:async';

/// Interface for deleting a single document.
abstract interface class Deletable {
  /// Deletes the document from Firestore.
  ///
  /// This operation is performed directly on the document reference and is
  /// not part of a transaction.
  ///
  /// Returns a [Future] that completes when the deletion is successfully applied.
  FutureOr<void> delete();
}
