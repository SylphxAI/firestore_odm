/// The `cloud_firestore` implementation of the backend seam.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../aggregate.dart';
import 'odm_backend.dart';

typedef _Map = Map<String, dynamic>;

/// [OdmBackend] over a [firestore.FirebaseFirestore] instance.
final class CloudFirestoreBackend implements OdmBackend {
  CloudFirestoreBackend._(this.firestoreInstance);

  static final Expando<CloudFirestoreBackend> _byInstance = Expando();

  /// The backend for [instance] (one per Firestore instance).
  factory CloudFirestoreBackend(firestore.FirebaseFirestore instance) =>
      _byInstance[instance] ??= CloudFirestoreBackend._(instance);

  final firestore.FirebaseFirestore firestoreInstance;

  @override
  Object get native => firestoreInstance;

  @override
  OdmFieldValues get fieldValues => const CloudFirestoreFieldValues();

  @override
  OdmCollection collection(String path) =>
      wrapCollection(firestoreInstance.collection(path));

  @override
  OdmQuery collectionGroup(String collectionId) =>
      _Query(this, firestoreInstance.collectionGroup(collectionId));

  @override
  Future<void> runTransaction(Future<void> Function(OdmTransaction) body) =>
      firestoreInstance.runTransaction(
        (transaction) => body(_Transaction(this, transaction)),
      );

  @override
  OdmBatch batch() => _Batch(firestoreInstance.batch());

  OdmCollection wrapCollection(firestore.CollectionReference<_Map> ref) =>
      _Collection(this, ref);

  OdmQuery wrapQuery(firestore.Query<_Map> query) => _Query(this, query);

  OdmDocument wrapDocument(firestore.DocumentReference<_Map> ref) =>
      _Document(this, ref);
}

firestore.Filter _toFilter(OdmFilter filter) => switch (filter) {
  OdmAndFilter(:final left, :final right) => firestore.Filter.and(
    _toFilter(left),
    _toFilter(right),
  ),
  OdmOrFilter(:final left, :final right) => firestore.Filter.or(
    _toFilter(left),
    _toFilter(right),
  ),
  OdmFieldFilter() => firestore.Filter(
    _field(filter.field),
    isEqualTo: filter.isEqualTo,
    isNotEqualTo: filter.isNotEqualTo,
    isLessThan: filter.isLessThan,
    isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
    isGreaterThan: filter.isGreaterThan,
    isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
    arrayContains: filter.arrayContains,
    arrayContainsAny: filter.arrayContainsAny,
    whereIn: filter.whereIn,
    whereNotIn: filter.whereNotIn,
    isNull: filter.isNull,
  ),
};

Object _field(OdmFieldRef field) =>
    field.isDocumentId ? firestore.FieldPath.documentId : field.path;

final class CloudFirestoreFieldValues implements OdmFieldValues {
  const CloudFirestoreFieldValues();

  @override
  Object delete() => firestore.FieldValue.delete();

  @override
  Object increment(num delta) => firestore.FieldValue.increment(delta);

  @override
  Object arrayUnion(List<Object?> values) =>
      firestore.FieldValue.arrayUnion(values);

  @override
  Object arrayRemove(List<Object?> values) =>
      firestore.FieldValue.arrayRemove(values);

  @override
  Object serverTimestamp() => firestore.FieldValue.serverTimestamp();
}

final class _DocumentSnapshot implements OdmDocumentSnapshot {
  const _DocumentSnapshot(this._backend, this._snapshot);

  final CloudFirestoreBackend _backend;
  final firestore.DocumentSnapshot<_Map> _snapshot;

  @override
  OdmDocument get reference => _Document(_backend, _snapshot.reference);

  @override
  String get id => _snapshot.id;

  @override
  String get path => _snapshot.reference.path;

  @override
  bool get exists => _snapshot.exists;

  @override
  _Map? data() => _snapshot.data();
}

final class _QuerySnapshot implements OdmQuerySnapshot {
  _QuerySnapshot(
    CloudFirestoreBackend backend,
    firestore.QuerySnapshot<_Map> snapshot,
  ) : docs = [for (final doc in snapshot.docs) _DocumentSnapshot(backend, doc)];

  @override
  final List<OdmDocumentSnapshot> docs;
}

final class _Document implements OdmDocument {
  const _Document(this._backend, this._ref);

  final CloudFirestoreBackend _backend;
  final firestore.DocumentReference<_Map> _ref;

  @override
  OdmBackend get backend => _backend;

  @override
  Object get native => _ref;

  @override
  String get id => _ref.id;

  @override
  String get path => _ref.path;

  @override
  Future<OdmDocumentSnapshot> get([Object? options]) async => _DocumentSnapshot(
    _backend,
    await _ref.get(options as firestore.GetOptions?),
  );

  @override
  Stream<OdmDocumentSnapshot> snapshots() =>
      _ref.snapshots().map((s) => _DocumentSnapshot(_backend, s));

  @override
  Future<void> set(_Map data) => _ref.set(data);

  @override
  Future<void> update(Map<Object, Object?> data) => _ref.update(data);

  @override
  Future<void> delete() => _ref.delete();
}

firestore.DocumentReference<_Map> _nativeDoc(OdmDocument document) =>
    document.native as firestore.DocumentReference<_Map>;

class _Query implements OdmQuery {
  const _Query(this.backendImpl, this._query);

  final CloudFirestoreBackend backendImpl;
  final firestore.Query<_Map> _query;

  @override
  OdmBackend get backend => backendImpl;

  @override
  Object get native => _query;

  OdmQuery _next(firestore.Query<_Map> query) => _Query(backendImpl, query);

  @override
  OdmQuery where(OdmFilter filter) => _next(_query.where(_toFilter(filter)));

  @override
  OdmQuery orderBy(OdmFieldRef field, {bool descending = false}) =>
      _next(_query.orderBy(_field(field), descending: descending));

  @override
  OdmQuery limit(int limit) => _next(_query.limit(limit));

  @override
  OdmQuery limitToLast(int limit) => _next(_query.limitToLast(limit));

  @override
  OdmQuery startAt(List<Object?> values) => _next(_query.startAt(values));

  @override
  OdmQuery startAfter(List<Object?> values) => _next(_query.startAfter(values));

  @override
  OdmQuery endAt(List<Object?> values) => _next(_query.endAt(values));

  @override
  OdmQuery endBefore(List<Object?> values) => _next(_query.endBefore(values));

  @override
  Future<OdmQuerySnapshot> get([Object? options]) async => _QuerySnapshot(
    backendImpl,
    await _query.get(options as firestore.GetOptions?),
  );

  @override
  Stream<OdmQuerySnapshot> snapshots() =>
      _query.snapshots().map((s) => _QuerySnapshot(backendImpl, s));

  @override
  Future<int> count() async {
    final snapshot = await _query.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<Map<String, Object?>> aggregate(
    List<AggregateOperation> operations,
  ) async {
    final fields = <firestore.AggregateField>[
      for (final op in operations)
        switch (op) {
          CountOperation() => firestore.count(),
          SumOperation(:final field) => firestore.sum(
            field.components.join('.'),
          ),
          AverageOperation(:final field) => firestore.average(
            field.components.join('.'),
          ),
        },
    ];
    final snapshot = await _query
        .aggregate(
          fields[0],
          fields.length > 1 ? fields[1] : null,
          fields.length > 2 ? fields[2] : null,
          fields.length > 3 ? fields[3] : null,
          fields.length > 4 ? fields[4] : null,
          fields.length > 5 ? fields[5] : null,
          fields.length > 6 ? fields[6] : null,
          fields.length > 7 ? fields[7] : null,
          fields.length > 8 ? fields[8] : null,
          fields.length > 9 ? fields[9] : null,
          fields.length > 10 ? fields[10] : null,
          fields.length > 11 ? fields[11] : null,
          fields.length > 12 ? fields[12] : null,
          fields.length > 13 ? fields[13] : null,
          fields.length > 14 ? fields[14] : null,
          fields.length > 15 ? fields[15] : null,
          fields.length > 16 ? fields[16] : null,
          fields.length > 17 ? fields[17] : null,
          fields.length > 18 ? fields[18] : null,
          fields.length > 19 ? fields[19] : null,
          fields.length > 20 ? fields[20] : null,
          fields.length > 21 ? fields[21] : null,
          fields.length > 22 ? fields[22] : null,
          fields.length > 23 ? fields[23] : null,
          fields.length > 24 ? fields[24] : null,
          fields.length > 25 ? fields[25] : null,
          fields.length > 26 ? fields[26] : null,
          fields.length > 27 ? fields[27] : null,
          fields.length > 28 ? fields[28] : null,
          fields.length > 29 ? fields[29] : null,
        )
        .get();
    return {
      for (final op in operations)
        op.key: switch (op) {
          CountOperation() => snapshot.count ?? 0,
          SumOperation(:final field) =>
            snapshot.getSum(field.components.join('.')) ?? 0,
          // Firestore returns no average when no document matches.
          AverageOperation(:final field) =>
            snapshot.getAverage(field.components.join('.')) ?? double.nan,
        },
    };
  }
}

final class _Collection extends _Query implements OdmCollection {
  _Collection(CloudFirestoreBackend backendImpl, this._ref)
    : super(backendImpl, _ref);

  final firestore.CollectionReference<_Map> _ref;

  @override
  OdmDocument doc([String? id]) => _Document(backendImpl, _ref.doc(id));

  @override
  Future<OdmDocument> add(_Map data) async =>
      _Document(backendImpl, await _ref.add(data));
}

final class _Transaction implements OdmTransaction {
  const _Transaction(this._backend, this._transaction);

  final CloudFirestoreBackend _backend;
  final firestore.Transaction _transaction;

  @override
  Object get native => _transaction;

  @override
  Future<OdmDocumentSnapshot> get(OdmDocument document) async =>
      _DocumentSnapshot(_backend, await _transaction.get(_nativeDoc(document)));

  @override
  void set(OdmDocument document, _Map data) =>
      _transaction.set(_nativeDoc(document), data);

  @override
  void update(OdmDocument document, Map<Object, Object?> data) =>
      _transaction.update(_nativeDoc(document), data);

  @override
  void delete(OdmDocument document) =>
      _transaction.delete(_nativeDoc(document));
}

final class _Batch implements OdmBatch {
  const _Batch(this._batch);

  final firestore.WriteBatch _batch;

  @override
  void set(OdmDocument document, _Map data) =>
      _batch.set(_nativeDoc(document), data);

  @override
  void update(OdmDocument document, Map<Object, Object?> data) =>
      _batch.update(_nativeDoc(document), data);

  @override
  void delete(OdmDocument document) => _batch.delete(_nativeDoc(document));

  @override
  Future<void> commit() => _batch.commit();
}
