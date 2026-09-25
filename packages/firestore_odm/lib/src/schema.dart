/// Marker base class for ODM schemas.
///
/// A schema is a plain Dart class annotated with `@Schema` whose instance is
/// passed to [FirestoreODM]. All functionality is provided by generated
/// extensions.
abstract class FirestoreSchema {
  const FirestoreSchema();
}
