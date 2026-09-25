/// The ODM entry point. One instance per Firestore database/instance; all
/// functionality is provided by generated extensions on this class.
library;

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;

import 'batch.dart';
import 'schema.dart';
import 'transaction.dart';

/// Main ODM class. Create one per schema:
///
/// ```dart
/// final db = FirestoreODM(schema);
/// final users = await db.users.where(($) => $.isActive(isEqualTo: true)).get();
/// ```
class FirestoreODM<S extends FirestoreSchema> {
  FirestoreODM(this.schema, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final S schema;
  final FirebaseFirestore _firestore;

  /// The Firestore instance backing this ODM.
  FirebaseFirestore get firestore => _firestore;

  /// Runs [cb] in a Firestore transaction. Reads are awaited inside [cb] in
  /// any order; writes are deferred and flushed after [cb] completes, which
  /// guarantees the read-before-write rule.
  Future<void> runTransaction(
    Future<void> Function(TransactionContext<S> context) cb,
  ) {
    return _firestore.runTransaction((transaction) async {
      final context = TransactionContext<S>(transaction);
      await cb(context);
      context.flush();
    });
  }

  /// Runs [cb] with a batch; all queued writes commit atomically.
  Future<void> runBatch(void Function(BatchContext<S> context) cb) async {
    final context = BatchContext<S>(_firestore);
    cb(context);
    await context.commit();
  }

  /// Creates a batch context for manual commit control.
  BatchContext<S> batch() => BatchContext<S>(_firestore);
}
