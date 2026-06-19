<div align="center">

# Firestore ODM 🔥

**Type-safe Firestore ODM for Dart/Flutter - zero reflection, code generation**

[![pub package](https://img.shields.io/pub/v/firestore_odm?style=flat-square)](https://pub.dev/packages/firestore_odm)
[![license](https://img.shields.io/github/license/SylphxAI/firestore_odm?style=flat-square)](https://github.com/SylphxAI/firestore_odm/blob/main/LICENSE)

**20% faster runtime** • **15% less code** • **Zero reflection** • **Full type safety**

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

**Result: Zero reflection, 20% faster runtime, eliminate runtime errors.**

---

## 🎉 New in Version 4.0

Building on 3.0's performance foundation, **4.0 expands type coverage and ergonomics** on top of a fully reworked code generator.

> ℹ️ 4.0 is currently a **pre-release** (`4.0.0-dev`). The current stable line is 3.x.

### New in 4.0
- ✅ **Enum support** - `@JsonValue` with both string *and* numeric values, enums in `orderBy()`, and default-value generation
- ✅ **Automatic nested-class imports** - filter, patch, aggregate, and `orderBy` selectors for nested types need no manual imports
- ✅ **Stronger nullable handling** - nullable `Map` fields, and nested `fromJson` factories that accept nullable input no longer crash when a field is missing
- ✅ **Server timestamps on insert** - not only on updates, and honored inside batches
- ✅ **Batch & transaction patch builders** - atomic patch operations in `runBatch` / `runTransaction`
- ✅ **Reworked code generator** - cleaner filter/patch/aggregate/orderBy builders and converters on a unified `FieldPath` model

### Performance (established in 3.0, retained in 4.0)

| Metric | Improvement | Impact |
|--------|-------------|--------|
| **Runtime Performance** | **20% faster** | Optimized code generation |
| **Generated Code** | **15% smaller** | Extension-based architecture |
| **Compilation Speed** | **<1 second** | Complex schemas compile instantly |
| **Runtime Overhead** | **Zero** | All magic at compile time |

### Carried over from 3.0
- ✅ **Full generic model support** - Generic classes with type-safe patch operations
- ✅ **Complete JsonKey & JsonConverter support** - Full serialization control
- ✅ **Automatic conversion fallbacks** - JsonConverter optional in most cases
- ✅ **Enhanced map operations** - Comprehensive map field support with atomic ops

---

## ⚡ Key Features

### Type Safety Revolution

| Feature | Standard Firestore | Firestore ODM |
|---------|-------------------|---------------|
| **Type Safety** | ❌ Map<String, dynamic> | ✅ Strong types throughout |
| **Query Building** | ❌ String-based, error-prone | ✅ Type-safe with IDE support |
| **Data Updates** | ❌ Manual map construction | ✅ Two powerful strategies |
| **Generic Support** | ❌ No generic handling | ✅ Full generic models |
| **Aggregations** | ❌ Basic count only | ✅ Comprehensive + streaming |
| **Pagination** | ❌ Manual, risky | ✅ Smart Builder, zero risk |
| **Transactions** | ❌ Manual read-before-write | ✅ Automatic deferred writes |
| **Runtime Errors** | ❌ Common | ✅ Eliminated at compile-time |

### Lightning Fast Code Generation

- 🚀 **Inline-first optimized** - Callables and Dart extensions for maximum performance
- 📦 **15% less generated code** - Smart generation without bloating your project
- ⚡ **20% performance improvement** - Optimized runtime execution
- 🔄 **Model reusability** - Same model works in collections and subcollections
- ⏱️ **Sub-second generation** - Complex schemas compile in under 1 second
- 🎯 **Zero runtime overhead** - All magic happens at compile time

### Revolutionary Features

**Smart Builder Pagination** - Eliminates common Firestore pagination bugs:
```dart
// Get first page with ordering
final page1 = await db.users
  .orderBy(($) => ($.followers(descending: true), $.name()))
  .limit(10)
  .get();

// Get next page with perfect type-safety - zero inconsistency risk
final page2 = await db.users
  .orderBy(($) => ($.followers(descending: true), $.name()))
  .startAfterObject(page1.last) // Auto-extracts cursor values
  .limit(10)
  .get();
```

**Streaming Aggregations** - Real-time aggregation subscriptions:
```dart
// Live statistics that update in real-time
db.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (
    count: $.count(),
    averageAge: $.age.average(),
    totalFollowers: $.profile.followers.sum(),
  ))
  .stream
  .listen((stats) {
    print('Live: ${stats.count} users, avg age ${stats.averageAge}');
  });
```

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
  .where(($) => $.and(
    $.isActive(isEqualTo: true),
    $.profile.followers(isGreaterThan: 100),
    $.age(isLessThan: 30),
  ))
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
// ✅ ODM - Two powerful update strategies

// 1. Patch - Explicit atomic operations (Best Performance)
await userDoc.patch(($) => [
  $.profile.followers.increment(1),
  $.tags.add('verified'),              // Add single element
  $.tags.addAll(['premium', 'active']), // Add multiple elements
  $.scores.removeAll([0, -1]),         // Remove multiple elements
  $.lastLogin.serverTimestamp(),
]);

// 2. Modify - Smart atomic detection (Read + Auto-detect operations)
await userDoc.modify((user) => user.copyWith(
  age: user.age + 1,              // Auto-detects -> FieldValue.increment(1)
  tags: [...user.tags, 'expert'], // Auto-detects -> FieldValue.arrayUnion()
  lastLogin: FirestoreODM.serverTimestamp,
));
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

// Create a user with custom ID
await db.users.insert(User(
  id: 'jane',
  name: 'Jane Smith',
  email: 'jane@example.com',
  age: 28,
));

// Create a user with auto-generated ID
await db.users.insert(User(
  id: FirestoreODM.autoGeneratedId,
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
final appSchema = _$AppSchema;

// Access user's posts
final userPosts = db.users('jane').posts;
await userPosts.insert(Post(id: 'post1', title: 'Hello World!'));
```

### Bulk Operations
```dart
// Update all premium users using patch (best performance)
await db.users
  .where(($) => $.isPremium(isEqualTo: true))
  .patch(($) => [$.points.increment(100)]);

// Update all premium users using modify (read + auto-detect atomic)
await db.users
  .where(($) => $.isPremium(isEqualTo: true))
  .modify((user) => user.copyWith(points: user.points + 100));

// Delete inactive users
await db.users
  .where(($) => $.status(isEqualTo: 'inactive'))
  .delete();
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

### Atomic Batch Operations
```dart
// Automatic management - simple and clean
await db.runBatch((batch) {
  batch.users.insert(newUser);
  batch.posts.update(existingPost);
  batch.users('user_id').posts.insert(userPost);
  batch.users('old_user').delete();
});

// Manual management - fine-grained control
final batch = db.batch();
batch.users.insert(user1);
batch.users.insert(user2);
batch.posts.update(post);
await batch.commit();
```

### Server Timestamps & Auto-Generated IDs
```dart
// Server timestamps using patch (best performance)
await userDoc.patch(($) => [$.lastLogin.serverTimestamp()]);

// Server timestamps using modify (read + smart detection)
await userDoc.modify((user) => user.copyWith(
  loginCount: user.loginCount + 1,  // Uses current value + auto-detects increment
  lastLogin: FirestoreODM.serverTimestamp,
));

// Auto-generated document IDs
await db.users.insert(User(
  id: FirestoreODM.autoGeneratedId, // Server generates unique ID
  name: 'John Doe',
  email: 'john@example.com',
));
```

**⚠️ Server Timestamp Warning:** `FirestoreODM.serverTimestamp` must be used exactly as-is. Any arithmetic operations (`+`, `.add()`, etc.) will create a regular `DateTime` instead of a server timestamp. See the [Server Timestamps Guide](https://SylphxAI.github.io/firestore_odm/guide/server-timestamps.html) for alternatives.

---

## 📊 Performance & Technical Excellence

### Optimized Code Generation

| Metric | Value | Benefit |
|--------|-------|---------|
| **Runtime Performance** | **+20%** | Optimized execution paths |
| **Generated Code Size** | **-15%** | Smart generation without bloat |
| **Compilation Time** | **<1 second** | Complex schemas compile instantly |
| **Runtime Overhead** | **Zero** | All magic at compile time |

### Advanced Capabilities
- ✅ **Complex logical operations** - `and()` and `or()`
- ✅ **Array operations** - `arrayContains`, `arrayContainsAny`, `whereIn`
- ✅ **Range queries** - Proper ordering constraints
- ✅ **Nested field access** - Full type safety
- ✅ **Transaction support** - Automatic deferred writes
- ✅ **Streaming subscriptions** - Real-time updates
- ✅ **Error handling** - Meaningful compile-time messages
- ✅ **Testing support** - `fake_cloud_firestore` integration

### Flexible Data Modeling
- **`freezed`** (recommended) - Robust immutable classes
- **`json_serializable`** - Plain Dart classes with full control
- **`fast_immutable_collections`** - High-performance `IList`, `IMap`, `ISet`

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

    await db.users.insert(User(
      id: 'test',
      name: 'Test User',
      email: 'test@example.com',
      age: 25
    ));

    final user = await db.users('test').get();
    expect(user?.name, 'Test User');
  });
}
```

---

## 🗺️ Roadmap

**✅ Completed (3.0 → 4.0)**
- [x] Full generic model support
- [x] Complete JsonKey & JsonConverter support
- [x] 20% runtime performance improvement & 15% smaller generated code
- [x] Enum support — string & numeric `@JsonValue`, `orderBy`, defaults *(4.0)*
- [x] Automatic nested-class imports *(4.0)*
- [x] Batch & transaction patch builders *(4.0)*
- [x] Server timestamps on insert *(4.0)*
- [x] Production-ready stability

**🚀 Next**
- [ ] [Firestore Pipelines support](https://github.com/SylphxAI/firestore_odm/issues/6)
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
