# Example

```dart
import 'package:firestore_odm/firestore_odm.dart';

part 'schema.g.dart';

@firestoreOdm
class User {
  const User({required this.id, required this.name});

  @DocumentIdField()
  final String id;
  final String name;
}

class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
const appSchema = AppSchema();
```

A complete, tested example is in
[firestore_odm/example](https://github.com/SylphxAI/firestore_odm/blob/main/packages/firestore_odm/example/lib/main.dart).
