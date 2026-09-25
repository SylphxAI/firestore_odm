/// Field-path plumbing shared by all generated selectors (filter, orderBy,
/// aggregate, pipeline, patch).
library;

import 'package:cloud_firestore/cloud_firestore.dart' show FieldPath;

/// A named field path (list of components). The document ID is represented by
/// the special [FieldPath.documentId] in query positions.
class FieldNode {
  const FieldNode({this.components = const []});

  /// Path components; empty means the collection/document root.
  final List<String> components;

  /// A nested node with [name] appended.
  FieldNode append(String name) => FieldNode(components: [...components, name]);

  /// The native field reference: a [FieldPath] for normal paths or
  /// [FieldPath.documentId] (a `FieldPathType`) for the document-ID
  /// pseudo-field. Acceptable anywhere `cloud_firestore` takes a field.
  Object get fieldPath => FieldPath(components);

  bool get isDocumentId => false;

  @override
  String toString() => components.join('.');
}

/// The document-ID pseudo-field used by generated `documentId` selectors.
final class DocumentIdNode extends FieldNode {
  const DocumentIdNode();

  @override
  Object get fieldPath => FieldPath.documentId;

  @override
  bool get isDocumentId => true;
}

/// The root of any generated selector tree; carries the path prefix.
abstract class SelectorRoot {
  const SelectorRoot({this.field = const FieldNode()});

  final FieldNode field;

  FieldNode append(String name) => field.append(name);
}
