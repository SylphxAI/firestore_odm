# firestore_odm_builder

The code generator for [firestore_odm](https://pub.dev/packages/firestore_odm),
the type-safe Firestore ODM for Flutter and Dart — the maintained successor to
cloud_firestore_odm.

```sh
flutter pub add firestore_odm cloud_firestore firebase_core
flutter pub add dev:firestore_odm_builder dev:build_runner
dart run build_runner build --delete-conflicting-outputs
```

It generates, for every `@firestoreOdm` model and `@Schema()`, the Firestore
converters and the typed filter, order, update and aggregate selectors. Use
the same version as `firestore_odm`.

## Migrate from cloud_firestore_odm

This package also ships a codemod:

```sh
dart pub global activate firestore_odm_builder
dart pub global run firestore_odm_builder:migrate           # preview
dart pub global run firestore_odm_builder:migrate --apply   # write
```

See the [migration guide](https://sylphxai.github.io/firestore_odm/guide/migrate-from-cloud-firestore-odm).
