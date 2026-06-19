import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/orderby.dart';
import 'package:firestore_odm/src/record_helper.dart';

abstract class QueryPaginationHandler {
  static List<dynamic> build<R extends Record>(R cursorValues) {
    return cursorValues.toList();
  }

  /// Smart value extraction using the SAME builder function as orderBy
  /// This ensures perfect consistency and type safety
  static List<dynamic>
  buildValuesFromObject<T, O extends Record, OB extends OrderByFieldNode>({
    required T object,
    required Map<String, dynamic> Function(T) toJson,
    required O Function(OB selector) orderByFunc,
    required OB Function(OrderByContext context) orderBuilderFunc,
    required String documentIdFieldName,
  }) {
    // Convert object to Map for extraction
    final objectMap = toJson(object);

    final context = OrderByExtractorContext(
      id: objectMap[documentIdFieldName],
      data: objectMap,
    );

    final builder = orderBuilderFunc(context);

    // Reuse the SAME builder function to extract values!
    // This guarantees perfect consistency with orderBy
    orderByFunc(builder);

    return context.extractedValues;
  }

  static firestore.Query<R> applyStartAt<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.startAt(cursorValues);
  }

  static firestore.Query<R> applyStartAfter<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.startAfter(cursorValues);
  }

  static firestore.Query<R> applyEndAt<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.endAt(cursorValues);
  }

  static firestore.Query<R> applyEndBefore<R>(
    firestore.Query<R> query,
    Iterable<dynamic> cursorValues,
  ) {
    return query.endBefore(cursorValues);
  }
}
