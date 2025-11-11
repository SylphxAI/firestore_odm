# Firestore ODM for Dart/Flutter

**Stop fighting with Firestore queries. Start building amazing apps.**

Transform your Firestore development experience with type-safe, intuitive database operations that feel natural and productive.

[![pub package](https://img.shields.io/pub/v/firestore_odm.svg)](https://pub.dev/packages/firestore_odm)
[![GitHub](https://img.shields.io/github/license/SylphxAI/firestore_odm)](https://github.com/SylphxAI/firestore_odm/blob/main/LICENSE)

## 🎉 New in Version 3.0!

**The most stable and feature-complete release yet** - over 90% of planned features are now complete!

### ⚡ Major Performance Improvements
- **20% faster runtime performance** with optimized code generation
- **15% less generated code** through smart extension-based architecture
- **Lightning-fast generation** - complex schemas compile in under 1 second
- **Inline-first approach** for maximum efficiency

### 🚀 New Features & Capabilities
- **Full generic model support** - Generic classes with type-safe patch operations
- **Complete JsonKey & JsonConverter support** - Full control over serialization
- **Automatic conversion fallbacks** - JsonConverter no longer required in most cases
- **Enhanced map operations** - Comprehensive map field support with atomic operations

### 🛡️ Stability & Quality
- **100+ new test cases** added for comprehensive coverage
- **Major bug fixes** including map clear, map set, and nested operations
- **Production-ready stability** with rigorous testing

### 📋 Known Limitations (3.0)
- Map fields don't support nested maps or special symbols in keys
- Batch collection operations (coming soon)
- Map field filtering, ordering, and aggregation (planned)

##  Complete Documentation

**[📚 Read the Full Documentation](https://SylphxAI.github.io/firestore_odm/)** - Comprehensive guides, examples, and API reference

## 📋 Table of Contents

- [Why Firestore ODM?](#-why-firestore-odm)
- [Before vs After](#-before-vs-after)
- [Key Features](#-key-features)
- [Quick Start](#-quick-start)
- [Advanced Features](#-advanced-features)
- [Performance & Technical Excellence](#-performance--technical-excellence)
- [Testing](#-testing)
- [Comparison with Standard Firestore](#-comparison-with-standard-firestore)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 Why Firestore ODM?

If you've worked with Flutter and Firestore, you know the pain:

- **No Type Safety** - String-based field paths that break at runtime, not compile time
- **Manual Serialization** - Converting `DocumentSnapshot` to models and back is tedious and error-prone
- **Complex Queries** - Writing nested logical queries is difficult and hard to read
- **Runtime Errors** - Typos in field names cause crashes in production
- **Incomplete Solutions** - Other ODMs are often incomplete or not actively maintained

We built Firestore ODM to solve these problems with:
- ✅ **Complete type safety** throughout your entire data layer
- ✅ **Lightning-fast code generation** using callables and Dart extensions
- ✅ **Minimal generated code** that doesn't bloat your project
- ✅ **Model reusability** across collections and subcollections
- ✅ **Revolutionary features** like Smart Builder pagination and streaming aggregations
- ✅ **Zero runtime overhead** - all magic happens at compile time

## 🔥 Before vs After

### Type Safety Revolution
```dart
// ❌ Standard cloud_firestore - Runtime errors waiting to happen
DocumentSnapshot doc = await FirebaseFirestore.instance
  .collection('users')
  .doc('user123')
  .get();

Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
String name = data?['name']; // Runtime error if field doesn't exist
int age = data?['profile']['age']; // Nested access is fragile
```

```dart
// ✅ Firestore ODM - Compile-time safety
User? user = await db.users('user123').get();
String name = user.name; // IDE autocomplete, compile-time checking
int age = user.profile.age; // Type-safe nested access
```

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

## ⚡ Key Features

### 🛡️ Complete Type Safety
- **No `Map<String, dynamic>`** anywhere in your code
- **Compile-time field validation** - typos become build errors, not runtime crashes
- **IDE autocomplete** for all database operations
- **Strong typing** for nested objects, generics, and complex data structures

### 🚀 Lightning Fast Code Generation (3.0 Enhanced)
- **Inline-first optimized** generated code using callables and Dart extensions
- **15% less generated code** - smart generation without bloating your project
- **20% performance improvement** - optimized runtime execution
- **Model reusability** - same model works in collections and subcollections
- **Sub-second generation** - complex schemas compile in under 1 second
- **Zero runtime overhead** - all magic happens at compile time

### 🧬 Advanced Generic Support (New in 3.0)
- **Full generic model support** - Type-safe generic classes and nested types
- **Generic patch operations** - Atomic operations that respect generic type constraints
- **JsonKey & JsonConverter support** - Complete control over field serialization
- **Automatic conversion fallbacks** - Smart type conversion when converters aren't defined

### 🧠 Revolutionary Pagination
Our **Smart Builder** eliminates the most common Firestore pagination bugs:
```dart
// Get first page with ordering
final page1 = await db.users
  .orderBy(($) => ($.followers(descending: true), $.name()))
  .limit(10)
  .get();

// Get next page with perfect type-safety - zero inconsistency risk
// The same orderBy ensures cursor consistency automatically
final page2 = await db.users
  .orderBy(($) => ($.followers(descending: true), $.name()))
  .startAfterObject(page1.last) // Auto-extracts cursor values
  .limit(10)
  .get();
```

### 📊 Streaming Aggregations (Unique Feature!)
Real-time aggregation subscriptions that Firestore doesn't support natively:
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

### 🏦 Smart Transactions
Automatic **deferred writes** handle Firestore's read-before-write rule:
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

### ⚡ Atomic Batch Operations
Perform multiple writes atomically with two convenient approaches:
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

### 🔗 Flexible Data Modeling
Support for multiple modeling approaches:
- **`freezed`** (recommended) - Robust immutable classes
- **`json_serializable`** - Plain Dart classes with full control
- **`fast_immutable_collections`** - High-performance `IList`, `IMap`, `ISet`

### 🏗️ Schema-Based Architecture
- **Multiple ODM instances** for different app modules
- **Compile-time validation** of collection paths and relationships
- **Automatic subcollection detection** and type-safe access
- **Clean separation** of database concerns

## 🚀 Quick Start

### 1. Installation

Install Firestore ODM:

```bash
dart pub add firestore_odm
dart pub add dev:firestore_odm_builder
dart pub add dev:build_runner
```

You'll also need a JSON serialization solution:

```bash
# If using Freezed
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

### 3. Define Your Model
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

### 4. Define Your Schema
```dart
// lib/schema.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'models/user.dart';

part 'schema.odm.dart';

@Schema()
@Collection<User>("users")
final appSchema = _$AppSchema;
```

### 5. Generate Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 6. Start Using
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

### Server Timestamps & Auto-Generated IDs
```dart
// Server timestamps using patch (best performance)
await userDoc.patch(($) => [$.lastLogin.serverTimestamp()]);

// Server timestamps using modify (read + smart detection)
await userDoc.modify((user) => user.copyWith(
  loginCount: user.loginCount + 1,  // Uses current value + auto-detects increment
  lastLogin: FirestoreODM.serverTimestamp,
));

// ⚠️ IMPORTANT: Server timestamp arithmetic doesn't work
// ❌ This creates a regular DateTime, NOT a server timestamp:
// FirestoreODM.serverTimestamp + Duration(days: 1)

// Auto-generated document IDs
await db.users.insert(User(
  id: FirestoreODM.autoGeneratedId, // Server generates unique ID
  name: 'John Doe',
  email: 'john@example.com',
));
```

**⚠️ Server Timestamp Warning:** `FirestoreODM.serverTimestamp` must be used exactly as-is. Any arithmetic operations (`+`, `.add()`, etc.) will create a regular `DateTime` instead of a server timestamp. See the [Server Timestamps Guide](https://SylphxAI.github.io/firestore_odm/guide/server-timestamps.html) for alternatives.

## 📊 Performance & Technical Excellence (3.0 Enhanced)

### Optimized Code Generation
- **Inline-first architecture** with callables and Dart extensions for maximum performance
- **15% reduction in generated code** - smart generation without project bloat
- **20% runtime performance improvement** - optimized execution paths
- **Sub-second compilation** - complex schemas generate in under 1 second
- **Zero runtime overhead** - all magic happens at compile time

### Advanced Query Capabilities
- **Complex logical operations** with `and()` and `or()`
- **Array operations** - `arrayContains`, `arrayContainsAny`, `whereIn`
- **Range queries** with proper ordering constraints
- **Nested field access** with full type safety

### Real-world Ready
- **Transaction support** with automatic deferred writes
- **Streaming subscriptions** for real-time updates
- **Error handling** with meaningful compile-time messages
- **Testing support** with `fake_cloud_firestore` integration

## 🧪 Testing

Perfect integration with `fake_cloud_firestore`:
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user operations work correctly', () async {
    final firestore = FakeFirebaseFirestore();
    final db = FirestoreODM(appSchema, firestore: firestore);

    await db.users.insert(User(id: 'test', name: 'Test User', email: 'test@example.com', age: 25));

    final user = await db.users('test').get();
    expect(user?.name, 'Test User');
  });
}
```

## 📈 Comparison with Standard Firestore

| Feature | Standard cloud_firestore | Firestore ODM |
|---------|-------------------------|---------------|
| **Type Safety** | ❌ Map<String, dynamic> everywhere | ✅ Strong types throughout |
| **Query Building** | ❌ String-based, error-prone | ✅ Type-safe with IDE support |
| **Data Updates** | ❌ Manual map construction | ✅ Two powerful update strategies |
| **Generic Support** | ❌ No generic handling | ✅ Full generic model support |
| **Aggregations** | ❌ Basic count only | ✅ Comprehensive + streaming |
| **Pagination** | ❌ Manual, inconsistency risks | ✅ Smart Builder, zero risk |
| **Transactions** | ❌ Manual read-before-write | ✅ Automatic deferred writes |
| **Code Generation** | ❌ None | ✅ Inline-optimized, 15% smaller |
| **Model Reusability** | ❌ N/A | ✅ Same model, multiple collections |
| **Runtime Errors** | ❌ Common | ✅ Eliminated at compile-time |
| **Developer Experience** | ❌ Frustrating | ✅ Productive and enjoyable |

## 🤝 Contributing

We love contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to transform your Firestore experience?** 

🔗 **[Get Started Now](https://SylphxAI.github.io/firestore_odm/guide/getting-started.html)** | 📚 **[Full Documentation](https://SylphxAI.github.io/firestore_odm/)** | 🐛 **[Report Issues](https://github.com/SylphxAI/firestore_odm/issues)**

Build type-safe, maintainable Flutter apps with the power of Firestore ODM! 🚀