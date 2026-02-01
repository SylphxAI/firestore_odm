import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/existable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'package:firestore_odm/src/services/update_helpers.dart';
import 'package:firestore_odm/src/utils.dart';

class TransactionContext<Schema extends FirestoreSchema> {
  final firestore.FirebaseFirestore ref;
  final firestore.Transaction transaction;
  final Map<String, firestore.DocumentSnapshot<Map<String, dynamic>>>
  _documentCache = {};
  final List<Function()> _deferredWrites = [];

  TransactionContext(this.ref, this.transaction);

  /// Cache a document snapshot for reuse within the transaction
  void _cacheDocument(
    firestore.DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    _documentCache[snapshot.reference.path] = snapshot;
  }

  /// Get a cached document snapshot if available
  firestore.DocumentSnapshot<Map<String, dynamic>>? _getCachedDocument(
    firestore.DocumentReference<Map<String, dynamic>> ref,
  ) {
    return _documentCache[ref.path];
  }

  /// Add a deferred write operation
  void _addDeferredWrite(Function() writeOperation) {
    _deferredWrites.add(writeOperation);
  }

  /// Execute all deferred writes
  void executeDeferredWrites() {
    for (final write in _deferredWrites) {
      write();
    }
    _deferredWrites.clear();
  }
}

class TransactionCollection<
  S extends FirestoreSchema,
  T,
  Path extends Record,
  P extends PatchBuilder<T, Map<String, dynamic>?>
> {
  final firestore.CollectionReference<Map<String, dynamic>> query;
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;
  final String documentIdField;
  final TransactionContext<S> context;
  final P _patchBuilder;

  TransactionCollection({
    required this.query,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required this.context,
    required this.documentIdField,
    required P patchBuilder,
  })  : _toJson = toJson,
        _fromJson = fromJson,
        _patchBuilder = patchBuilder;

  /// Gets a document reference with the specified ID
  /// Documents are cached to ensure consistency
  /// Usage: users('id')
  TransactionDocument<S, T, Path, P> call(String id) => TransactionDocument(
    ref: query.doc(id),
    toJson: _toJson,
    fromJson: _fromJson,
    documentIdField: documentIdField,
    context: context,
    patchBuilder: _patchBuilder,
  );
}

class TransactionDocument<
  S extends FirestoreSchema,
  T,
  Path extends Record,
  P extends PatchBuilder<T, Map<String, dynamic>?>
>
    implements Gettable<T?>, Modifiable<T>, Patchable<T>, Existable, Deletable {
  final firestore.DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;
  final String documentIdField;
  final TransactionContext<S> context;
  final P _patchBuilder;

  TransactionDocument({
    required this.ref,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required this.documentIdField,
    required this.context,
    required P patchBuilder,
  })  : _toJson = toJson,
        _fromJson = fromJson,
        _patchBuilder = patchBuilder;

  @override
  Future<T?> get() async {
    final snapshot = await context.transaction.get(ref);
    // Cache the snapshot for future use in this transaction
    context._cacheDocument(snapshot);
    if (!snapshot.exists) return null;
    return fromFirestoreData(
      _fromJson,
      snapshot.data()!,
      documentIdField,
      snapshot.id,
    );
  }

  /// Get a document snapshot, reading if not cached
  Future<firestore.DocumentSnapshot<Map<String, dynamic>>>
  _getSnapshot() async {
    final cached = context._getCachedDocument(ref);
    if (cached != null) {
      return cached;
    }
    final snapshot = await context.transaction.get(ref);
    context._cacheDocument(snapshot);
    return snapshot;
  }

  /// Modify a document within a transaction using diff-based updates.
  ///
  /// This method performs a read operation followed by an update operation within a transaction.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// **Important Notes:**
  /// - **Transactions**: This operation is transactional and handles read-before-write correctly
  /// - **Deferred Writes**: Write operations are automatically deferred until transaction commit
  /// - **Performance**: Additional read operation impacts performance compared to [patch]
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  ///
  /// **Example:**
  /// ```dart
  /// await db.runTransaction((tx) async {
  ///   // With atomic operations (default)
  ///   await tx.users('user1').modify((user) => user.copyWith(
  ///     balance: user.balance - 100, // Auto-detects -> FieldValue.increment(-100)
  ///   ));
  ///
  ///   // Without atomic operations
  ///   await tx.users('user2').modify((user) => user.copyWith(
  ///     status: 'processed',
  ///   ), atomic: false);
  /// });
  /// ```
  @override
  Future<void> modify(
    T Function(T docData) modifier, {
    bool atomic = true,
  }) async {
    // Read the document and prepare the write operation
    final snapshot = await _getSnapshot();
    final patch = DocumentHandler.processPatch(
      snapshot,
      modifier,
      _toJson,
      _fromJson,
      documentIdField,
      atomic ? computeDiffWithAtomicOperations : computeDiff,
    );
    if (patch.isNotEmpty) {
      // Defer the write operation
      context._addDeferredWrite(() => context.transaction.update(ref, patch));
    }
  }

  @override
  void patch(List<UpdateOperation> Function(P patchBuilder) patchBuilder) {
    final operations = patchBuilder(_patchBuilder);
    final updateMap = operationsToMap(operations);
    if (updateMap.isNotEmpty) {
      // Defer the write operation
      context._addDeferredWrite(
        () => context.transaction.update(ref, processKeysTo(updateMap)),
      );
    }
  }

  @override
  Future<bool> exists() async {
    final snapshot = await _getSnapshot();
    return snapshot.exists;
  }

  @override
  void delete() {
    // Defer the delete operation
    context._addDeferredWrite(() => context.transaction.delete(ref));
  }
}
