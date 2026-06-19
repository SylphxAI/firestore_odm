import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Annotation to define a Firestore collection in a schema
///
/// Used on schema variable declarations to define collections:
/// ```dart
/// @Collection<User>("users")
/// @Collection<Post>("posts")
/// @Collection<Post>("users/*/posts")
/// final schema = _$Schema;
/// ```
///
/// Supports both regular collections and subcollections with wildcard syntax:
/// - Regular collection: `@Collection<User>("users")`
/// - Subcollection: `@Collection<Post>("users/*/posts")` where * represents a document ID
@Target({TargetKind.topLevelVariable})
@immutable
class Collection<T> {
  /// The path to the Firestore collection or subcollection
  ///
  /// Examples:
  /// - `"users"` - Regular collection
  /// - `"users/*/posts"` - Subcollection where * represents the parent document ID
  /// - `"organizations/*/departments/*/employees"` - Nested subcollection
  final String path;

  /// Creates a [Collection] annotation with type parameter
  const Collection(this.path);
}

/// Annotation to mark a field as the document ID
/// This field will be synchronized with the Firestore document ID
/// but will not be included in the document content.
@Target({TargetKind.field, TargetKind.parameter})
@immutable
class DocumentIdField {
  /// Creates a [DocumentIdField] annotation
  const DocumentIdField();
}

/// Annotation to mark a variable as a Firestore schema definition
///
/// Used to identify schema variables that contain multiple @Collection annotations:
/// ```dart
/// @Schema()
/// @Collection<User>("users")
/// @Collection<Post>("posts")
/// final testSchema = _$TestSchema;
/// ```
///
/// This helps the code generator identify which variables represent complete schemas
/// for automatic discovery of nested model types.
@Target({TargetKind.topLevelVariable})
@immutable
class Schema {
  /// Creates a [Schema] annotation
  const Schema();
}

@Target({TargetKind.classType})
@immutable
class FirestoreOdm {
  const FirestoreOdm();
}

const FirestoreOdm firestoreOdm = FirestoreOdm();
