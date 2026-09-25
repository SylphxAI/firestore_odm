# firestore_odm_annotation

Annotations for [firestore_odm](https://pub.dev/packages/firestore_odm), the
type-safe Firestore ODM for Flutter and Dart — the maintained successor to
cloud_firestore_odm.

You normally do not depend on this package directly: `firestore_odm` exports
it. It defines:

- `@firestoreOdm`: generate converters and typed selectors for a model class.
- `@DocumentIdField()`: the model field that holds the document ID.
- `@Schema()` and `@Collection<T>('path')`: the collections of a schema,
  including subcollections such as `users/*/posts`.

See the [firestore_odm README](https://github.com/SylphxAI/firestore_odm#readme)
and the [documentation](https://sylphxai.github.io/firestore_odm/).
