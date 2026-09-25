/// Cursor application for ordered queries.
///
/// Value cursors are Dart records matching the orderBy record shape; object
/// cursors extract the orderBy values from a model instance.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'record_utils.dart';

abstract final class QueryPaginationHandler {
  static firestore.Query<Map<String, dynamic>> applyStartAt(
    firestore.Query<Map<String, dynamic>> query,
    Object? cursor,
  ) => query.startAt(_toList(cursor));

  static firestore.Query<Map<String, dynamic>> applyStartAfter(
    firestore.Query<Map<String, dynamic>> query,
    Object? cursor,
  ) => query.startAfter(_toList(cursor));

  static firestore.Query<Map<String, dynamic>> applyEndAt(
    firestore.Query<Map<String, dynamic>> query,
    Object? cursor,
  ) => query.endAt(_toList(cursor));

  static firestore.Query<Map<String, dynamic>> applyEndBefore(
    firestore.Query<Map<String, dynamic>> query,
    Object? cursor,
  ) => query.endBefore(_toList(cursor));

  static List<Object?> _toList(Object? cursor) {
    if (cursor is Record) return cursor.toList();
    if (cursor is List) return cursor.cast<Object?>();
    return [cursor];
  }
}
