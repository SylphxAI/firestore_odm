import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter/widgets.dart';

part 'main.g.dart';

// 1. A model: a plain class (freezed and json_serializable classes work too).
@firestoreOdm
class User {
  const User({
    required this.id,
    required this.name,
    required this.age,
    this.tags = const [],
    this.lastLogin,
  });

  @DocumentIdField()
  final String id;
  final String name;
  final int age;
  final List<String> tags;
  final DateTime? lastLogin;
}

// 2. A schema: every collection, including subcollections, in one place.
class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
const appSchema = AppSchema();

// 3. Typed reads and writes. `dart run build_runner build` generates the
// `$` selectors from the model.
Future<void> run(FirestoreODM<AppSchema> db) async {
  await db.users.set(const User(id: 'kim', name: 'Kim', age: 31));
  await db.users.set(
    const User(id: 'lee', name: 'Lee', age: 17, tags: ['beta']),
  );

  final adults = await db.users
      .where(($) => $.age(isGreaterThanOrEqualTo: 18))
      .orderBy(($) => ($.age(descending: true), $.name()))
      .limit(20)
      .get(); // List<User>

  await db
      .users('kim')
      .patch(
        ($) => [
          $.age.increment(1),
          $.tags.arrayUnion(['admin']),
          $.lastLogin.serverTimestamp(),
        ],
      );

  final stats = await db.users
      .aggregate(($) => (count: $.count(), averageAge: $.age.average()))
      .get(); // ({int count, double averageAge})

  debugPrint(
    '${adults.map((u) => u.name)}: ${stats.count} users, '
    'average age ${stats.averageAge}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await run(FirestoreODM(appSchema));
}
