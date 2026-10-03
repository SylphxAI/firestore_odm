/// Cursor application for ordered queries.
///
/// Value cursors are Dart records matching the orderBy record shape; object
/// cursors extract the orderBy values from a model instance.
library;

import 'backend/odm_backend.dart';
import 'record_utils.dart';

abstract final class QueryPaginationHandler {
  static OdmQuery applyStartAt(OdmQuery query, Object? cursor) =>
      query.startAt(_toList(cursor));

  static OdmQuery applyStartAfter(OdmQuery query, Object? cursor) =>
      query.startAfter(_toList(cursor));

  static OdmQuery applyEndAt(OdmQuery query, Object? cursor) =>
      query.endAt(_toList(cursor));

  static OdmQuery applyEndBefore(OdmQuery query, Object? cursor) =>
      query.endBefore(_toList(cursor));

  static List<Object?> _toList(Object? cursor) {
    if (cursor is Record) return cursor.toList();
    if (cursor is List) return cursor.cast<Object?>();
    return [cursor];
  }
}
