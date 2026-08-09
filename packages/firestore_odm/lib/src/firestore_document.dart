/// The typed document surface: get/stream/set/patch/delete (ADR-0002).
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'patch.dart';
import 'schema.dart';
import 'types.dart';
import 'utils.dart';

/// A type-safe wrapper around a Firestore document reference.
class FirestoreDocument<S extends FirestoreSchema, T, P extends PatchBuilder<T>> {
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

  final JsonSerializer<T> _toJson;
  final JsonDeserializer<T> _fromJson;
  final String? documentIdField;
  final P Function() _patchBuilderFactory;

  /// The document data, or null when the document does not exist.
  Future<T?> get() async {
    final snapshot = await ref.get();
    if (!snapshot.exists) return null;
    return processDocumentSnapshot(snapshot, _fromJson, documentIdField);
  }

  /// Live stream of the document; emits null when it does not exist.
  Stream<T?> get stream => ref.snapshots().map(
    (snapshot) => snapshot.exists
        ? processDocumentSnapshot(snapshot, _fromJson, documentIdField)
        : null,
  );

  /// Replaces this document.
  Future<void> set(T value) async {
    await ref.set(toFirestoreData(_toJson, value, documentIdField: documentIdField));
  }

  /// Applies typed patch operations to this document.
  Future<void> patch(List<UpdateOperation> Function(P builder) patches) async {
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) return;
    await ref.update(updateMap);
  }

  /// Deletes this document.
  Future<void> delete() => ref.delete();
}
