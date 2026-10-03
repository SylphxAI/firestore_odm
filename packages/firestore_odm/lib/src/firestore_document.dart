/// The typed document surface: get/stream/set/patch/delete.
library;

import 'package:cloud_firestore/cloud_firestore.dart'
    as firestore
    show DocumentReference, GetOptions;

import 'backend/cloud_firestore_backend.dart';
import 'backend/odm_backend.dart';
import 'firestore_builder.dart';
import 'patch.dart';
import 'schema.dart';
import 'types.dart';
import 'utils.dart';

/// A type-safe wrapper around a Firestore document reference.
class FirestoreDocument<S extends FirestoreSchema, T, P extends PatchBuilder<T>>
    implements FirestoreListenable<T?> {
  FirestoreDocument({
    required this.ref,
    required JsonSerializer<T> toJson,
    required JsonDeserializer<T> fromJson,
    required this.documentIdField,
    required P Function() patchBuilderFactory,
  }) : _toJson = toJson,
       _fromJson = fromJson,
       _patchBuilderFactory = patchBuilderFactory;

  /// The underlying Firestore document reference (escape hatch).
  final firestore.DocumentReference<Map<String, dynamic>> ref;

  late final OdmDocument _doc = CloudFirestoreBackend(
    ref.firestore,
  ).wrapDocument(ref);

  final JsonSerializer<T> _toJson;
  final JsonDeserializer<T> _fromJson;
  final String? documentIdField;
  final P Function() _patchBuilderFactory;

  /// The document data, or null when the document does not exist. Pass
  /// [options] to read from the cache or the server only.
  Future<T?> get([firestore.GetOptions? options]) async {
    final snapshot = await _doc.get(options);
    if (!snapshot.exists) return null;
    return processDocumentSnapshot(snapshot, _fromJson, documentIdField);
  }

  /// Live stream of the document; emits null when it does not exist.
  @override
  Stream<T?> get stream => _doc.snapshots().map(
    (snapshot) => snapshot.exists
        ? processDocumentSnapshot(snapshot, _fromJson, documentIdField)
        : null,
  );

  @override
  Object get nativeReference => ref;

  /// Replaces this document.
  Future<void> set(T value) async {
    await _doc.set(
      toFirestoreData(_toJson, value, documentIdField: documentIdField),
    );
  }

  /// Applies typed patch operations to this document.
  Future<void> patch(List<UpdateOperation> Function(P builder) patches) async {
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations, _doc.backend.fieldValues);
    if (updateMap.isEmpty) return;
    await _doc.update(updateMap);
  }

  /// Deletes this document.
  Future<void> delete() => _doc.delete();
}
