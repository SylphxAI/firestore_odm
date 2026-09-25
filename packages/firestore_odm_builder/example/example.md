# Example

Annotate models and a schema (see
[firestore_odm/example](https://github.com/SylphxAI/firestore_odm/blob/main/packages/firestore_odm/example/lib/main.dart)),
then generate:

```sh
dart run build_runner build --delete-conflicting-outputs
```

The generated part gives each collection typed queries and updates:

```dart
final db = FirestoreODM(appSchema);
final adults = await db.users
    .where(($) => $.age(isGreaterThanOrEqualTo: 18))
    .orderBy(($) => ($.name(),))
    .get();
await db.users('kim').patch(($) => [$.age.increment(1)]);
```

To migrate a cloud_firestore_odm project:

```sh
dart pub global run firestore_odm_builder:migrate --apply
```
