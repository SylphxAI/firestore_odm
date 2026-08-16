<div align="center">

# Firestore ODM 🔥

<p align="center">
  <img src="https://mark.sylphx.com/api/v1/banner?type=wave&theme=tokyonight&text=firestore+odm&desc=%F0%9F%94%A5+Type-safe+Firestore+ODM+for+Dart%2FFlutter+-+code-generation+with+zero+reflecti&height=200&animation=rise&credit=0" alt="firestore_odm — Sylphx Mark banner" width="100%" />
</p>

**Type-safe Firestore ODM for Dart/Flutter - zero reflection, code generation**

[![pub package](https://img.shields.io/pub/v/firestore_odm?style=flat-square)](https://pub.dev/packages/firestore_odm)
[![license](https://img.shields.io/github/license/SylphxAI/firestore_odm?style=flat-square)](https://github.com/SylphxAI/firestore_odm/blob/main/LICENSE)

**Zero reflection** • **Full type safety** • **Native Timestamp** • **Measured performance**

[Documentation](https://SylphxAI.github.io/firestore_odm/) • [Getting Started](https://SylphxAI.github.io/firestore_odm/guide/getting-started.html) • [Examples](#-quick-start)

</div>

---

## 🚀 Overview

Firestore ODM transforms your Firestore development experience with type-safe, intuitive database operations that feel natural and productive.

**The Problem:**
```dart
// Standard cloud_firestore - Runtime errors waiting to happen
DocumentSnapshot doc = await FirebaseFirestore.instance
  .collection('users').doc('user123').get();
Map<String, dynamic>? data = doc.data();
String name = data?['name'];  // ❌ Runtime error if field doesn't exist
int age = data?['profile']['age'];  // ❌ Nested access is fragile
```

**The Solution:**
```dart
// Firestore ODM - Compile-time safety
User? user = await db.users('user123').get();
String name = user.name;  // ✅ IDE autocomplete, compile-time checking
int age = user.profile.age;  // ✅ Type-safe nested access
```

**Result: Zero reflection, exact Firestore semantics, eliminate runtime errors.**

---

## 🎉 New in Version 5.0 (clean break, ADR-0002)

- **Exact Firestore semantics** - DateTime ↔ native Timestamp both directions;
  the ODM owns storage serialization.
- **Honest write verbs** - `create` (returns the generated ID), `set`, `patch`
  (six FieldValue-shaped ops), `delete`. No sentinels, no `modify()` magic.
- **One-shot server-side aggregates** - no fake client-side streaming.
- **Typed bulk writes** - `patchAll` / `deleteAll` chunked to Firestore's
  500-write batch limit.
- **Stable pagination** - orderBy with the `$.documentId` tie-breaker selector.
- **Recorded benchmarks + emulator e2e lane** - measured, not asserted.

## 🔭 Capabilities retained in the v5 contract

These capabilities remain available under the v5 semantics contract:

- ✅ **Enum support** - `@JsonValue` with both string *and* numeric values, enums in `orderBy()`, and default-value generation
- 🧪 **Firestore Pipelines** *(experimental)* - `collection.pipeline()` for Enterprise-edition pipeline queries (see [ADR-0001](docs/adr/0001-firestore-pipelines.md))
- ✅ **Automatic nested-class imports** - filter, patch, aggregate, and `orderBy` selectors for nested types need no manual imports
- ✅ **Stronger nullable handling** - nullable `Map` fields, and nested `fromJson` factories that accept nullable input no longer crash when a field is missing
- ✅ **Batch & transaction patch builders** - atomic patch operations in `runBatch` / `runTransaction`
- ✅ **Unified code generator** - converters and filter/orderBy/aggregate/patch selectors share one generated model surface

### Performance (measured, not asserted)

The repo ships a recorded benchmark harness (`apps/flutter_example/test/benchmarks_test.dart`,
run by the `performance` CI lane). Numbers are recorded per run; claims without
measurements are not made.

| Metric | How it is measured |
|--------|--------------------|
| Serialization round-trip | `BENCH serialization_roundtrip_us_per_op` (Stopwatch, 10k iterations) |
| Patch operation latency | `BENCH patch_op_ms_per_op` (1000 ops against the test double) |
| Runtime overhead | Zero reflection — all magic happens at compile time |

### Carried over from 3.0
- ✅ **Full generic model support** - generic classes with type-safe patch
  operations and converter-argument threading (freezed-style `toT`/`fromT`)
- ✅ **JsonKey subset** (`name`, `ignore`, `includeFromJson`/`includeToJson`)
  and `@JsonConverter` — documented honestly, no silent partial support
- ✅ **ODM-owned storage serialization** - native Timestamp both directions;
  your model's `toJson`/`fromJson` remain for JSON interchange only

---

## ⚡ Key Features

### Type Safety Revolution

| Feature | Standard Firestore | Firestore ODM |
|---------|-------------------|---------------|
| **Type Safety** | ❌ Map<String, dynamic> | ✅ Strong types throughout |
| **Query Building** | ❌ String-based, error-prone | ✅ Type-safe with IDE support |
| **Data Updates** | ❌ Manual map construction | ✅ Explicit typed Firestore primitives |
| **Generic Support** | ❌ No generic handling | ✅ Full generic models |
| **Aggregations** | ❌ Basic count only | ✅ One-shot count/sum/average (server-side) |
| **Pagination** | ❌ Manual, risky | ✅ Smart Builder, zero risk |
| **Transactions** | ❌ Manual read-before-write | ✅ Automatic deferred writes |
| **Runtime Errors** | ❌ Common | ✅ Eliminated at compile-time |

### Lightning Fast Code Generation

- 🚀 **Inline-first optimized** - Callables and Dart extensions for maximum performance
- 📦 **Small generated surface** - one unified codegen pipeline per model
- ⚡ **Measured performance** - recorded benchmark harness in CI
- 🔄 **Model reusability** - Same model works in collections and subcollections
- ⏱️ **Sub-second generation** - Complex schemas compile in under 1 second
- 🎯 **Zero runtime overhead** - All magic happens at compile time (no reflection)

### Revolutionary Features

**Smart Builder Pagination** - Eliminates common Firestore pagination bugs:
```dart
// Get first page with ordering
final page1 = await db.users
  .orderBy(($) => ($.followers(descending: true), $.name(), $.documentId()))
  .limit(10)
  .get();

// Get next page with perfect type-safety - zero inconsistency risk
final page2 = await db.users
  .orderBy(($) => ($.followers(descending: true), $.name(), $.documentId()))
  .startAfterObject(page1.last) // Auto-extracts cursor values
  .limit(10)
  .get();
```

**One-shot Server-Side Aggregations** (ADR-0002 — no fake client-side
streaming; server-side aggregate streams are added only when
`cloud_firestore` exposes them):
```dart
final stats = await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (
    count: $.count(),
    averageAge: $.age.average(),
    totalFollowers: $.profile.followers.sum(),
  ))
  .get();
print('${stats.count} users, avg ${stats.averageAge}');


---

## 🔥 Before vs After

### Smart Query Building
```dart
// ❌ Standard - String-based field paths, typos cause runtime errors
final result = await FirebaseFirestore.instance
  .collection('users')
  .where('isActive', isEqualTo: true)
  .where('profile.followers', isGreaterThan: 100)
  .where('age', isLessThan: 30)
  .get();
```

```dart
// ✅ ODM - Type-safe query builder with IDE support
final result = await db.users
  .where(($) =>
    $.isActive(isEqualTo: true) &
    $.profile.followers(isGreaterThan: 100) &
    $.age(isLessThan: 30),
  )
  .get();
```

### Intelligent Updates
```dart
// ❌ Standard - Manual map construction, error-prone
await userDoc.update({
  'profile.followers': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['verified']),
  'lastLogin': FieldValue.serverTimestamp(),
});
```

```dart
// ✅ ODM - Explicit typed patch operations (ADR-0002)
await userDoc.patch((p) => [
  p.profile.followers.increment(1),
  p.age.increment(1),
  p.tags.arrayUnion(['premium', 'active']), // atomic array union
  p.scores.arrayRemove([0, -1]),            // atomic array remove
  p.lastLogin.serverTimestamp(),            // server-set time
  p.name.set('Renamed'),                    // plain set
  p.oldField.delete(),                      // field delete
]);
```
Read-modify-write belongs in transactions, where it is safe:
```dart
await db.runTransaction((tx) async {
  final txUsers = db.users.inTransaction(tx);
  final user = await txUsers('jane').get();
  txUsers('jane').patch((p) => [p.age.increment(1)]);
});
```

---

## 📦 Installation

### 1. Add Dependencies

```bash
dart pub add firestore_odm
dart pub add dev:firestore_odm_builder
dart pub add dev:build_runner
```

You'll also need a JSON serialization solution:

```bash
# If using Freezed (recommended)
dart pub add freezed_annotation
dart pub add dev:freezed
dart pub add dev:json_serializable

# If using plain classes
dart pub add json_annotation
dart pub add dev:json_serializable
```

### 2. Configure json_serializable (Critical for Nested Models)

**⚠️ Important:** If you're using models with nested objects (especially with Freezed), you **must** create a `build.yaml` file next to your `pubspec.yaml`:

```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
```

**Why is this required?** Without this configuration, `json_serializable` generates broken `toJson()` methods for nested objects. Instead of proper JSON, you'll get `Instance of 'NestedClass'` stored in Firestore, causing data corruption and deserialization failures.

**When you need this:**
- ✅ Using nested Freezed classes
- ✅ Using nested objects with `json_serializable`
- ✅ Working with complex object structures
- ✅ Encountering "Instance of..." in Firestore console

**Alternative:** Add `@JsonSerializable(explicitToJson: true)` to individual classes if you can't use global configuration.

---

## 🚀 Quick Start

### 1. Define Your Model
```dart
// lib/models/user.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    DateTime? lastLogin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### 2. Define Your Schema
```dart
// lib/schema.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'models/user.dart';

part 'schema.odm.dart';

@Schema()
@Collection<User>("users")
final appSchema = _$AppSchema;
```

### 3. Generate Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Start Using
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart';

final firestore = FirebaseFirestore.instance;
final db = FirestoreODM(appSchema, firestore: firestore);

// Create a user with an explicit ID (full replace)
await db.users.set(User(
  id: 'jane',
  name: 'Jane Smith',
  email: 'jane@example.com',
  age: 28,
));

// Create a user with a server-generated ID (the ID is returned)
final id = await db.users.create(User(
  id: '',
  name: 'John Doe',
  email: 'john@example.com',
  age: 30,
));

// Get a user
final user = await db.users('jane').get();
print(user?.name); // "Jane Smith"

// Type-safe queries
final youngUsers = await db.users
  .where(($) => $.age(isLessThan: 30))
  .orderBy(($) => $.name())
  .get();
```

---

## 🌟 Advanced Features

### Subcollections with Model Reusability
```dart
@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
@Collection<Post>("users/*/posts") // Same Post model, different location
final appSchema = AppSchema();

// Access a user's posts (path-derived accessor: users/*/posts -> usersPosts)
final userPosts = db.usersPosts('jane');
await userPosts.set(Post(id: 'post1', title: 'Hello World!'));
```

### Bulk Operations (chunked to Firestore's 500-write limit)
```dart
// Patch every match with the same typed operations
await db.users
  .where(($) => $.isPremium(isEqualTo: true))
  .patchAll([IncrementOperation(const FieldNode(components: ['points']), 100)]);

// Delete every match
await db.users
  .where(($) => $.isActive(isEqualTo: false))
  .deleteAll();
```

### Smart Transactions
```dart
await db.runTransaction((tx) async {
  // All reads happen first automatically
  final sender = await tx.users('user1').get();
  final receiver = await tx.users('user2').get();

  // Writes are automatically deferred until the end
  tx.users('user1').patch(($) => [$.balance.increment(-100)]);
  tx.users('user2').patch(($) => [$.balance.increment(100)]);
});
```

### Atomic Batch Operations (typed create/set/patch/delete)
```dart
// Automatic management - simple and clean
await db.runBatch((batch) {
  final users = db.users.inBatch(batch);
  users.set(newUser);
  db.posts.inBatch(batch).set(existingPost);
  db.usersPosts('user_id').inBatch(batch).set(userPost);
  users.delete('old_user');
});

// Manual management - fine-grained control
final batch = db.batch();
db.users.inBatch(batch).set(user1);
db.users.inBatch(batch).set(user2);
db.posts.inBatch(batch).patch('p1', (p) => [p.likes.increment(1)]);
await batch.commit();
```

### Server Timestamps & Generated IDs (no sentinels, ADR-0002)
```dart
// Server timestamps are explicit patch operations
await userDoc.patch((p) => [p.updatedAt.serverTimestamp()]);

// Server-generated document IDs come from create()
final id = await db.users.create(User(
  id: '',
  name: 'John Doe',
  email: 'john@example.com',
));
```

Server-set times use the explicit patch op (ADR-0002 — no sentinels):
`patch((p) => [p.updatedAt.serverTimestamp()])`.

---

## 📊 Performance & Technical Excellence

### Optimized Code Generation

| Metric | How it is measured |
|--------|--------------------|
| Serialization round-trip | recorded `BENCH serialization_roundtrip_us_per_op` |
| Patch operation latency | recorded `BENCH patch_op_ms_per_op` |
| Runtime overhead | zero reflection — all magic at compile time |

Claims without measurements are not made; the harness runs in the
`performance` CI lane (`apps/flutter_example/test/benchmarks_test.dart`).

### Advanced Capabilities
- ✅ **Complex logical operations** - `and()` and `or()`
- ✅ **Array operations** - `arrayContains`, `arrayContainsAny`, `whereIn`
- ✅ **Range queries** - Proper ordering constraints
- ✅ **Nested field access** - Full type safety
- ✅ **Transaction support** - Automatic deferred writes
- ✅ **Query/document streams** - Real-time updates
- ✅ **Error handling** - Meaningful compile-time messages
- ✅ **Testing support** - `fake_cloud_firestore` integration

### Flexible Data Modeling
- **`freezed`** (recommended) - Robust immutable classes
- **`json_serializable`** - Plain Dart classes with full control
- **Plain Dart collections** - Firestore-native `List`, `Map`, and `Set` fields

---

## 🧪 Testing

Perfect integration with `fake_cloud_firestore`:
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user operations work correctly', () async {
    final firestore = FakeFirebaseFirestore();
    final db = FirestoreODM(appSchema, firestore: firestore);

    await db.users.set(User(
      id: 'test',
      name: 'Test User',
      email: 'test@example.com',
      age: 25,
    ));

    final user = await db.users('test').get();
    expect(user?.name, 'Test User');
  });
}
```

---

## 🗺️ Roadmap

**✅ Completed (v5 clean break)**
- [x] Full generic model support
- [x] Honest JsonKey subset + @JsonConverter
- [x] Recorded benchmark harness (no unmeasured perf claims)
- [x] Enum support — string & numeric `@JsonValue`, `orderBy`, defaults *(4.0)*
- [x] Automatic nested-class imports *(4.0)*
- [x] Batch & transaction patch builders *(4.0)*
- [x] Explicit server timestamps through the `patch` operation
- [x] Production-ready stability

**🚀 Next**
- [ ] Validate Enterprise Firestore Pipeline stages before widening the experimental surface
- [ ] Full map field filtering, ordering, and aggregation
- [ ] Nested map support
- [ ] Enhanced documentation

---

## 🤝 Support

[![GitHub Issues](https://img.shields.io/github/issues/SylphxAI/firestore_odm?style=flat-square)](https://github.com/SylphxAI/firestore_odm/issues)
[![pub.dev](https://img.shields.io/pub/v/firestore_odm?style=flat-square)](https://pub.dev/packages/firestore_odm)

- 🐛 [Bug Reports](https://github.com/SylphxAI/firestore_odm/issues)
- 💬 [Discussions](https://github.com/SylphxAI/firestore_odm/discussions)
- 📖 [Full Documentation](https://SylphxAI.github.io/firestore_odm/)
- 📧 [Email](mailto:hi@sylphx.com)

**Show Your Support:**
⭐ Star • 👀 Watch • 🐛 Report bugs • 💡 Suggest features • 🔀 Contribute

---

## 📄 License

MIT © [Sylphx](https://sylphx.com)

---

## 🙏 Credits

Built with:
- [Freezed](https://pub.dev/packages/freezed) - Immutable classes
- [json_serializable](https://pub.dev/packages/json_serializable) - JSON serialization
- [build_runner](https://pub.dev/packages/build_runner) - Code generation

Special thanks to the Flutter and Dart communities ❤️

---

<p align="center">
  <strong>Zero reflection. Type-safe. Production-ready.</strong>
  <br>
  <sub>The Firestore ODM that actually scales</sub>
  <br><br>
  <a href="https://sylphx.com">sylphx.com</a> •
  <a href="https://x.com/SylphxAI">@SylphxAI</a> •
  <a href="mailto:hi@sylphx.com">hi@sylphx.com</a>
</p>
