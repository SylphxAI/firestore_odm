/// Typed orderBy selectors and cursor extraction.
///
/// Pagination stability is explicit: include the generated `documentId`
/// selector in the orderBy record to get deterministic page boundaries (the
/// Firestore-recommended tie-breaker). Object cursors extract exactly the
/// values of the orderBy fields from the model.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'field_selector.dart';
import 'utils.dart';

/// Context that records the fields selected by an orderBy builder.
abstract class OrderByContext {
  void record(FieldNode field, bool descending);
}

final class OrderByBuilderContext implements OrderByContext {
  final List<OrderByFieldInfo> fields = [];

  @override
  void record(FieldNode field, bool descending) {
    fields.add(OrderByFieldInfo(field, descending));
  }
}

/// A single orderBy term.
final class OrderByFieldInfo {
  const OrderByFieldInfo(this.field, this.descending);

  final FieldNode field;
  final bool descending;

  @override
  String toString() =>
      'OrderByFieldInfo(${field.components.join('.')}, desc: $descending)';
}

/// A typed orderBy selector for one field. Calling it records the term in the
/// context and returns a dummy value so the user's record literal type-checks.
class OrderByField<T> {
  const OrderByField({
    required FieldNode field,
    required OrderByContext context,
  }) : _field = field,
       _context = context;

  final FieldNode _field;
  final OrderByContext _context;

  T call({bool descending = false}) {
    _context.record(_field, descending);
    return defaultValue<T>();
  }
}

/// Base class for generated orderBy builders.
abstract class OrderByBuilderRoot extends SelectorRoot {
  const OrderByBuilderRoot({super.field});
}

/// Builds and applies orderBy terms from a generated builder.
abstract final class QueryOrderbyHandler {
  static List<OrderByFieldInfo> build<T, OB extends OrderByBuilderRoot>({
    required Object Function(OB selector) orderByFunc,
    required OB Function(OrderByContext context) orderByBuilderFunc,
  }) {
    final context = OrderByBuilderContext();
    final builder = orderByBuilderFunc(context);
    orderByFunc(builder);
    return context.fields;
  }

  static firestore.Query<Map<String, dynamic>> applyOrderBy(
    firestore.Query<Map<String, dynamic>> query,
    List<OrderByFieldInfo> fields,
  ) {
    var newQuery = query;
    for (final info in fields) {
      newQuery = newQuery.orderBy(
        info.field.fieldPath,
        descending: info.descending,
      );
    }
    return newQuery;
  }
}

/// Extracts cursor values from a model object for the given orderBy terms.
///
/// The document ID term resolves to the model's document ID field value.
abstract final class OrderByExtractor {
  static List<Object?> extractValues<T>({
    required T object,
    required Map<String, dynamic> Function(T) toJson,
    required List<OrderByFieldInfo> fields,
    required String? documentIdFieldName,
  }) {
    final objectMap = toJson(object);
    final values = <Object?>[];
    for (final info in fields) {
      if (info.field.isDocumentId) {
        final id = documentIdFieldName == null
            ? null
            : objectMap[documentIdFieldName];
        values.add(id);
      } else {
        values.add(resolveJsonPath(objectMap, info.field.components));
      }
    }
    return values;
  }

  static Object? resolveJsonPath(Map<String, dynamic> json, List<String> path) {
    dynamic current = json;
    for (final part in path) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(part)) return null;
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}
