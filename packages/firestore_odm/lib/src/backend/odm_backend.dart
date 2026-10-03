/// The backend seam: everything the ODM runtime needs from a Firestore SDK.
///
/// Internal (not exported). The runtime talks to these interfaces only; the
/// `cloud_firestore` implementation lives in `cloud_firestore_backend.dart`.
/// Value types (`Timestamp`, `GeoPoint`, `Blob`, `DocumentReference`) are not
/// abstracted here: they stay the SDK's own (see docs/design/server-support.md).
library;

import '../aggregate.dart' show AggregateOperation;

/// A field in a query position: a dotted path, or the document ID.
final class OdmFieldRef {
  const OdmFieldRef.path(this.path) : isDocumentId = false;
  const OdmFieldRef.documentId() : path = '', isDocumentId = true;

  final String path;
  final bool isDocumentId;
}

/// A backend-neutral query filter tree.
sealed class OdmFilter {
  const OdmFilter();
}

/// One field condition; exactly one condition is set (the typed filter
/// builder enforces it).
final class OdmFieldFilter extends OdmFilter {
  const OdmFieldFilter(
    this.field, {
    this.isEqualTo,
    this.isNotEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.whereNotIn,
    this.isNull,
  });

  final OdmFieldRef field;
  final Object? isEqualTo;
  final Object? isNotEqualTo;
  final Object? isLessThan;
  final Object? isLessThanOrEqualTo;
  final Object? isGreaterThan;
  final Object? isGreaterThanOrEqualTo;
  final Object? arrayContains;
  final List<Object?>? arrayContainsAny;
  final List<Object?>? whereIn;
  final List<Object?>? whereNotIn;
  final bool? isNull;
}

final class OdmAndFilter extends OdmFilter {
  const OdmAndFilter(this.left, this.right);
  final OdmFilter left;
  final OdmFilter right;
}

final class OdmOrFilter extends OdmFilter {
  const OdmOrFilter(this.left, this.right);
  final OdmFilter left;
  final OdmFilter right;
}

/// Sentinel values for patch operations.
abstract interface class OdmFieldValues {
  Object delete();
  Object increment(num delta);
  Object arrayUnion(List<Object?> values);
  Object arrayRemove(List<Object?> values);
  Object serverTimestamp();
}

abstract interface class OdmDocumentSnapshot {
  String get id;
  String get path;
  OdmDocument get reference;
  bool get exists;
  Map<String, dynamic>? data();
}

abstract interface class OdmQuerySnapshot {
  List<OdmDocumentSnapshot> get docs;
}

abstract interface class OdmDocument {
  OdmBackend get backend;
  String get id;
  String get path;

  /// [options] are backend-specific read options (`GetOptions` for
  /// `cloud_firestore`).
  Future<OdmDocumentSnapshot> get([Object? options]);
  Stream<OdmDocumentSnapshot> snapshots();
  Future<void> set(Map<String, dynamic> data);
  Future<void> update(Map<Object, Object?> data);
  Future<void> delete();

  /// The SDK reference (escape hatch).
  Object get native;
}

abstract interface class OdmQuery {
  OdmQuery where(OdmFilter filter);
  OdmQuery orderBy(OdmFieldRef field, {bool descending = false});
  OdmQuery limit(int limit);
  OdmQuery limitToLast(int limit);
  OdmQuery startAt(List<Object?> values);
  OdmQuery startAfter(List<Object?> values);
  OdmQuery endAt(List<Object?> values);
  OdmQuery endBefore(List<Object?> values);

  Future<OdmQuerySnapshot> get([Object? options]);
  Stream<OdmQuerySnapshot> snapshots();

  /// Server-side count.
  Future<int> count();

  /// Runs the aggregate [operations] in one request and returns the results
  /// keyed by [AggregateOperation.key]; absent sums are 0, absent averages
  /// are NaN.
  Future<Map<String, Object?>> aggregate(List<AggregateOperation> operations);

  /// The backend this query belongs to.
  OdmBackend get backend;

  /// The SDK query (escape hatch).
  Object get native;
}

abstract interface class OdmCollection implements OdmQuery {
  /// The document at [id], or a new generated ID when null.
  OdmDocument doc([String? id]);
  Future<OdmDocument> add(Map<String, dynamic> data);
}

abstract interface class OdmTransaction {
  Future<OdmDocumentSnapshot> get(OdmDocument document);
  void set(OdmDocument document, Map<String, dynamic> data);
  void update(OdmDocument document, Map<Object, Object?> data);
  void delete(OdmDocument document);
  Object get native;
}

abstract interface class OdmBatch {
  void set(OdmDocument document, Map<String, dynamic> data);
  void update(OdmDocument document, Map<Object, Object?> data);
  void delete(OdmDocument document);
  Future<void> commit();
}

abstract interface class OdmBackend {
  OdmFieldValues get fieldValues;
  OdmCollection collection(String path);
  OdmQuery collectionGroup(String collectionId);
  Future<void> runTransaction(Future<void> Function(OdmTransaction) body);
  OdmBatch batch();

  /// The SDK instance (escape hatch).
  Object get native;
}
