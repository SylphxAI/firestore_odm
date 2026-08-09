# Migration Guide: From cloud_firestore to Firestore ODM

This comprehensive guide will walk you through migrating from the standard `cloud_firestore` package to Firestore ODM, feature by feature. Each section includes detailed comparisons, benefits, and step-by-step migration instructions.

## Overview: Why Migrate?

The standard `cloud_firestore` package has several fundamental limitations:
- **No type safety** - Everything is `Map<String, dynamic>`
- **Runtime errors** - Field name typos cause crashes in production
- **Manual serialization** - Tedious and error-prone data conversion
- **Complex queries** - Difficult to write and maintain
- **Limited features** - No type-safe one-shot aggregations, smart pagination, or atomic update helpers

Firestore ODM solves all these problems while maintaining full compatibility with your existing Firestore database.

## 1. Basic Setup Migration

### Before (cloud_firestore)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;
final usersCollection = firestore.collection('users');
```

### After (Firestore ODM)
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart'; // Your schema file

final firestore = FirebaseFirestore.instance;
final db = FirestoreODM(appSchema, firestore: firestore);
final usersCollection = db.users; // Type-safe collection reference
```

### Migration Steps:
1. **Install Firestore ODM** packages
2. **Create your data models** using freezed or json_serializable
3. **Define your schema** with `@Schema()` and `@Collection<T>()` annotations
4. **Run code generation** with `dart run build_runner build`
5. **Replace collection references** with ODM instances

### Benefits After Migration:
- ✅ **Type-safe collection access** - `db.users` instead of `firestore.collection('users')`
- ✅ **Compile-time validation** - Typos become build errors, not runtime crashes
- ✅ **IDE autocomplete** - Full IntelliSense support for all operations

## 2. Data Models Migration

### Before (Manual Map Handling)
```dart
// No data model - working directly with maps
Map<String, dynamic> userData = {
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30,
  'isActive': true,
};

// Manual serialization from DocumentSnapshot
DocumentSnapshot doc = await usersCollection.doc('user123').get();
Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
String name = data?['name'] ?? ''; // Unsafe, can cause runtime errors
```

### After (Type-Safe Models)
```dart
// Strong typed model with automatic serialization
@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    required bool isActive,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Type-safe operations
User? user = await db.users('user123').get();
String name = user?.name ?? ''; // Compile-time safe
```

### Migration Steps:
1. **Analyze your existing data structure** in Firestore
2. **Create freezed or json_serializable models** matching your data
3. **Add `@DocumentIdField()` annotation** to your ID field
4. **Generate code** with build_runner
5. **Replace manual map operations** with model operations

### Benefits After Migration:
- ✅ **Complete type safety** - No more `Map<String, dynamic>`
- ✅ **Automatic serialization** - No manual `fromJson`/`toJson` calls
- ✅ **IDE support** - Autocomplete for all model fields
- ✅ **Compile-time validation** - Field access errors caught at build time

## 3. Reading Documents Migration

### Before (Manual DocumentSnapshot Handling)
```dart
// Get a single document
DocumentSnapshot doc = await usersCollection.doc('user123').get();
if (doc.exists) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  String name = data['name']; // Unsafe - can throw if field missing
  int age = data['age']; // No type checking
}

// Stream a document
Stream<DocumentSnapshot> stream = usersCollection.doc('user123').snapshots();
stream.listen((doc) {
  if (doc.exists) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // Manual data extraction every time
  }
});
```

### After (Type-Safe Document Operations)
```dart
// Get a single document - fully type-safe
User? user = await db.users('user123').get();
if (user != null) {
  String name = user.name; // Compile-time safe
  int age = user.age; // Strongly typed
}

// Stream a document - automatic deserialization
Stream<User?> stream = db.users('user123').stream;
stream.listen((user) {
  if (user != null) {
    // Direct access to typed fields
    print('User: ${user.name}, Age: ${user.age}');
  }
});
```

### Migration Steps:
1. **Replace `DocumentSnapshot` operations** with ODM document references
2. **Remove manual data extraction** - ODM handles serialization automatically
3. **Update stream handling** - Use typed streams instead of `DocumentSnapshot` streams
4. **Remove null safety boilerplate** - ODM provides clean nullable types

### Benefits After Migration:
- ✅ **Automatic deserialization** - No manual data extraction
- ✅ **Type-safe field access** - Compile-time validation of all fields
- ✅ **Cleaner code** - Less boilerplate, more readable
- ✅ **Better error handling** - Null safety built-in

## 4. Writing Documents Migration

### Before (Manual Map Construction)
```dart
// Create a document
await usersCollection.doc('user123').set({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30,
  'isActive': true,
  'createdAt': FieldValue.serverTimestamp(),
});

// Update a document
await usersCollection.doc('user123').update({
  'age': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['premium']),
  'lastLogin': FieldValue.serverTimestamp(),
});
```

### After (Type-Safe Operations)
```dart
// Create a document - type-safe model
await db.users.insert(User(
  id: 'user123',
  name: 'John Doe',
  email: 'john@example.com',
  age: 30,
  isActive: true,
));

// Update with two powerful strategies:

// 1. Patch - Explicit atomic operations
await db.users('user123').patch(($) => [
  $.age.increment(1),
  $.tags.add('premium'),
  $.lastLogin.serverTimestamp(),
]);

// 2. Modify - Smart atomic detection (reads then applies optimized updates)
await db.users('user123').modify((user) => user.copyWith(
  age: user.age + 1, // Auto-detects -> FieldValue.increment(1)
  tags: [...user.tags, 'premium'], // Auto-detects -> FieldValue.arrayUnion()
  lastLogin: FirestoreODM.serverTimestamp,
));
```

### Migration Steps:
1. **Replace `set()` operations** with `insert()` or `upsert()`
2. **Convert manual maps** to typed model instances
3. **Choose update strategy**:
   - Use `patch()` for explicit atomic operations
   - Use `modify()` for smart automatic detection (reads current values first)
4. **Replace `FieldValue` operations** with ODM equivalents

### Benefits After Migration:
- ✅ **Two powerful update strategies** - Choose the best approach for each use case
- ✅ **Automatic atomic operations** - `modify` detects and optimizes updates
- ✅ **Type-safe field updates** - No more string-based field names
- ✅ **Server timestamp helpers** - Easy server timestamp handling

## 5. Batch Operations Migration

### Before (Manual WriteBatch Handling)
```dart
// Manual batch creation and management
WriteBatch batch = FirebaseFirestore.instance.batch();

// Manual map construction for each operation
batch.set(usersCollection.doc('user1'), {
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 30,
});

batch.update(usersCollection.doc('user2'), {
  'age': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['premium']),
});

batch.delete(usersCollection.doc('user3'));

// Manual commit
await batch.commit();

// No subcollection support in batch
// No type safety
// Manual error handling for batch limits
```

### After (Type-Safe Batch Operations)
```dart
// Automatic batch management - simple and clean
await db.runBatch((batch) {
  // Type-safe operations with models
  batch.users.insert(User(
    id: 'user1',
    name: 'John Doe',
    email: 'john@example.com',
    age: 30,
  ));
  
  // Atomic operations with type safety
  batch.users('user2').patch(($) => [
    $.age.increment(1),
    $.tags.add('premium'),
  ]);
  
  // Delete operations
  batch.users('user3').delete();
  
  // Subcollection support
  batch.users('user1').posts.insert(Post(
    id: 'post1',
    title: 'My First Post',
    content: 'Hello world!',
  ));
});

// Manual batch management for fine-grained control
final batch = db.batch();
batch.users.insert(user1);
batch.users.insert(user2);
batch.posts.update(post);
await batch.commit();
```

### Migration Steps:
1. **Replace `WriteBatch` creation** with ODM batch methods
2. **Convert manual maps** to typed model operations
3. **Use type-safe field operations** instead of `FieldValue` maps
4. **Choose batch approach**:
   - Use `runBatch()` for automatic management
   - Use `batch()` for manual control
5. **Add subcollection operations** where needed
6. **Remove manual batch limit checking** - ODM handles this

### Benefits After Migration:
- ✅ **Two convenient approaches** - Automatic and manual batch management
- ✅ **Complete type safety** - No more manual map construction
- ✅ **Subcollection support** - Full nested document operations
- ✅ **Atomic operations** - Type-safe patch operations
- ✅ **Automatic limit handling** - Built-in 500 operation limit management
- ✅ **Better error handling** - Clear error messages for batch failures

## 6. Querying Migration

### Before (String-Based Queries)
```dart
// Simple query
QuerySnapshot snapshot = await usersCollection
  .where('isActive', isEqualTo: true)
  .where('age', isGreaterThan: 18)
  .get();

List<Map<String, dynamic>> users = snapshot.docs
  .map((doc) => doc.data() as Map<String, dynamic>)
  .toList();

// Complex query with nested fields
QuerySnapshot complexSnapshot = await usersCollection
  .where('profile.followers', isGreaterThan: 1000)
  .where('settings.theme', isEqualTo: 'dark')
  .get();
```

### After (Type-Safe Queries)
```dart
// Simple query - fully type-safe
List<User> users = await db.users
  .where(($) => $.and(
    $.isActive(isEqualTo: true),
    $.age(isGreaterThan: 18),
  ))
  .get();

// Complex query with nested fields - IDE autocomplete
List<User> complexUsers = await db.users
  .where(($) => $.and(
    $.profile.followers(isGreaterThan: 1000),
    $.settings.theme(isEqualTo: 'dark'),
  ))
  .get();

// Advanced logical queries
List<User> engagedUsers = await db.users
  .where(($) => $.and(
    $.isActive(isEqualTo: true),
    $.or(
      $.isPremium(isEqualTo: true),
      $.profile.followers(isGreaterThan: 1000),
    ),
  ))
  .get();
```

### Migration Steps:
1. **Replace string field names** with type-safe field accessors
2. **Use query builder syntax** - `where(($) => $.field(operator: value))`
3. **Combine conditions** with `$.and()` and `$.or()` for complex logic
4. **Remove manual deserialization** - ODM returns typed objects directly

### Benefits After Migration:
- ✅ **Type-safe field access** - No more string-based field names
- ✅ **Complex logical queries** - Easy `and`/`or` combinations
- ✅ **Nested field support** - Full autocomplete for nested objects
- ✅ **Automatic deserialization** - Direct typed results

## 7. Pagination Migration

### Before (Error-Prone Manual Cursors)
```dart
// First page
Query query = usersCollection
  .orderBy('createdAt', descending: true)
  .limit(10);

QuerySnapshot firstPage = await query.get();
List<QueryDocumentSnapshot> docs = firstPage.docs;

// Next page - manual cursor management (error-prone!)
if (docs.isNotEmpty) {
  DocumentSnapshot lastDoc = docs.last;
  Query nextQuery = usersCollection
    .orderBy('createdAt', descending: true) // Must match exactly!
    .startAfterDocument(lastDoc)
    .limit(10);
  
  QuerySnapshot nextPage = await nextQuery.get();
}
```

### After (Smart Builder Pagination)
```dart
// First page with Smart Builder
List<User> firstPage = await db.users
  .orderBy(($) => $.createdAt(descending: true))
  .limit(10)
  .get();

// Next page - zero inconsistency risk!
if (firstPage.isNotEmpty) {
  List<User> nextPage = await db.users
    .orderBy(($) => $.createdAt(descending: true)) // Same orderBy
    .startAfterObject(firstPage.last) // Auto-extracts cursor
    .limit(10)
    .get();
}

// Multi-field ordering with type safety
List<User> complexPage = await db.users
  .orderBy(($) => (
    $.profile.followers(descending: true),
    $.name(), // ascending
  ))
  .limit(10)
  .get();
```

### Migration Steps:
1. **Replace `orderBy` strings** with type-safe field accessors
2. **Use Smart Builder syntax** - `orderBy(($) => $.field())`
3. **Replace manual cursor management** with `startAfterObject()`
4. **Ensure consistent ordering** - Same `orderBy` for all pages

### Benefits After Migration:
- ✅ **Zero inconsistency risk** - Smart Builder ensures cursor consistency
- ✅ **Type-safe ordering** - Compile-time validation of sort fields
- ✅ **Multi-field sorting** - Easy tuple-based ordering
- ✅ **Automatic cursor extraction** - No manual document cursor management

## 8. Aggregations Migration

### Before (Limited Basic Aggregations)
```dart
// Only basic count available
AggregateQuerySnapshot countSnapshot = await usersCollection
  .where('isActive', isEqualTo: true)
  .count()
  .get();

int count = countSnapshot.count;

// No sum/average support
// No streaming aggregations
// Manual calculation required for complex stats
```

### After (Comprehensive Aggregations)
```dart
// Multiple aggregations in one request
final stats = await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (
    count: $.count(),
    averageAge: $.age.average(),
    totalFollowers: $.profile.followers.sum(),
  ))
  .get();

print('Count: ${stats.count}');
print('Average age: ${stats.averageAge}');
print('Total followers: ${stats.totalFollowers}');

// One-shot server-side aggregation (ADR-0002)
final result = await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .aggregate(($) => (count: $.count()))
  .get();
print('Count: ${result.count}');
```

### Migration Steps:
1. **Replace basic `count()` calls** with ODM aggregate syntax
2. **Combine multiple aggregations** in single requests for efficiency
3. **Use one-shot server-side aggregates** (no client-side streaming)
4. **Use typed aggregate results** instead of manual calculations

### Benefits After Migration:
- ✅ **Multiple aggregations** - count, sum, average in one request
- ✅ **One-shot aggregations** - server-side count/sum/average
- ✅ **Type-safe results** - Strongly typed aggregate responses
- ✅ **Efficient queries** - Server-side calculations

## 9. Transactions Migration

### Before (Manual Read-Before-Write)
```dart
await FirebaseFirestore.instance.runTransaction((transaction) async {
  // Must manually ensure all reads happen before writes
  DocumentSnapshot userDoc = await transaction.get(
    usersCollection.doc('user1')
  );
  DocumentSnapshot receiverDoc = await transaction.get(
    usersCollection.doc('user2')
  );
  
  // Manual data extraction
  Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
  Map<String, dynamic> receiverData = receiverDoc.data() as Map<String, dynamic>;
  
  int userBalance = userData['balance'];
  int receiverBalance = receiverData['balance'];
  
  // Manual map updates
  transaction.update(usersCollection.doc('user1'), {
    'balance': userBalance - 100,
  });
  transaction.update(usersCollection.doc('user2'), {
    'balance': receiverBalance + 100,
  });
});
```

### After (Automatic Deferred Writes)
```dart
await db.runTransaction((tx) async {
  // Reads happen automatically first
  User? sender = await tx.users('user1').get();
  User? receiver = await tx.users('user2').get();
  
  if (sender == null || receiver == null) {
    throw Exception('User not found');
  }
  
  if (sender.balance < 100) {
    throw Exception('Insufficient funds');
  }
  
  // Writes are automatically deferred until the end
  await tx.users('user1').modify((user) => user.copyWith(
    balance: user.balance - 100, // Becomes atomic decrement
  ));
  
  await tx.users('user2').modify((user) => user.copyWith(
    balance: user.balance + 100, // Becomes atomic increment
  ));
});
```

### Migration Steps:
1. **Replace manual transaction handling** with ODM transaction context
2. **Remove read-before-write logic** - ODM handles this automatically
3. **Use typed models** instead of manual map operations
4. **Leverage deferred writes** - Write operations are queued automatically

### Benefits After Migration:
- ✅ **Automatic deferred writes** - No manual read-before-write management
- ✅ **Type-safe operations** - Strongly typed transaction operations
- ✅ **Cleaner code** - Less boilerplate, more readable
- ✅ **Error prevention** - Compile-time validation of transaction logic

## 10. Subcollections Migration

### Before (Manual Path Construction)
```dart
// Manual subcollection access
CollectionReference userPosts = usersCollection
  .doc('user123')
  .collection('posts');

// Manual path construction for nested subcollections
CollectionReference postComments = usersCollection
  .doc('user123')
  .collection('posts')
  .doc('post456')
  .collection('comments');

// No type safety, manual serialization
QuerySnapshot postsSnapshot = await userPosts.get();
List<Map<String, dynamic>> posts = postsSnapshot.docs
  .map((doc) => doc.data() as Map<String, dynamic>)
  .toList();
```

### After (Type-Safe Subcollection Access)
```dart
// Schema definition with subcollections
@Schema()
@Collection<User>("users")
@Collection<Post>("users/*/posts")
@Collection<Comment>("users/*/posts/*/comments")
final appSchema = _$AppSchema;

// Type-safe subcollection access
final userPosts = db.users('user123').posts;
final postComments = db.users('user123').posts('post456').comments;

// Fully typed operations
List<Post> posts = await userPosts.get();
await userPosts.insert(Post(
  id: 'new-post',
  title: 'My New Post',
  content: 'Post content...',
));
```

### Migration Steps:
1. **Define subcollections in schema** using wildcard paths (`users/*/posts`)
2. **Create models for subcollection data** (can reuse same model types)
3. **Replace manual path construction** with chained property access
4. **Use type-safe operations** on subcollections

### Benefits After Migration:
- ✅ **Type-safe subcollection access** - Chained property navigation
- ✅ **Model reusability** - Same model works in multiple collection contexts
- ✅ **Automatic path construction** - No manual path building
- ✅ **Full feature support** - All ODM features work on subcollections

## 11. Error Handling Migration

### Before (Runtime Error Prone)
```dart
try {
  DocumentSnapshot doc = await usersCollection.doc('user123').get();
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  
  // Runtime errors waiting to happen:
  String name = data['name']; // Throws if field missing
  int age = data['age']; // Throws if wrong type
  String email = data['profile']['email']; // Throws if nested field missing
  
} catch (e) {
  // Generic error handling for various runtime issues
  print('Error: $e');
}
```

### After (Compile-Time Safety)
```dart
try {
  User? user = await db.users('user123').get();
  
  if (user != null) {
    // Compile-time safe - these can't throw:
    String name = user.name; // Guaranteed to exist and be String
    int age = user.age; // Guaranteed to be int
    String email = user.profile.email; // Type-safe nested access
  }
  
} catch (e) {
  // Only network/permission errors possible
  print('Network/permission error: $e');
}
```

### Migration Steps:
1. **Replace runtime type checking** with compile-time model validation
2. **Use nullable types** for optional fields in your models
3. **Leverage null safety** - handle missing documents cleanly
4. **Focus error handling** on network/permission issues only

### Benefits After Migration:
- ✅ **Compile-time error prevention** - Field access errors caught at build time
- ✅ **Cleaner error handling** - Only handle actual runtime errors
- ✅ **Better debugging** - Clear error messages for type mismatches
- ✅ **Null safety** - Built-in handling for missing data

## Migration Checklist

### Phase 1: Setup
- [ ] Install Firestore ODM packages
- [ ] Create data models with freezed/json_serializable
- [ ] Define schema with collections
- [ ] Run code generation
- [ ] Test basic operations

### Phase 2: Core Operations
- [ ] Migrate document reading operations
- [ ] Migrate document writing operations
- [ ] Migrate batch operations
- [ ] Migrate basic queries
- [ ] Update error handling

### Phase 3: Advanced Features
- [ ] Migrate complex queries
- [ ] Implement pagination with Smart Builder
- [ ] Add aggregation operations
- [ ] Migrate transaction logic

### Phase 4: Optimization
- [ ] Add subcollections support
- [ ] Implement streaming aggregations
- [ ] Optimize update strategies
- [ ] Add comprehensive testing

## Best Practices for Migration

1. **Migrate incrementally** - Start with one collection at a time
2. **Keep existing code working** - Run both systems in parallel during migration
3. **Test thoroughly** - Verify data integrity after each migration step
4. **Use type-safe models** - Take full advantage of compile-time validation
5. **Leverage new features** - Use streaming aggregations and smart pagination
6. **Optimize updates** - Choose the right update strategy for each use case

## Conclusion

Migrating from standard `cloud_firestore` to Firestore ODM provides significant benefits:

- **Complete type safety** eliminates runtime errors
- **Better developer experience** with IDE support and autocomplete
- **Advanced features** like streaming aggregations and smart pagination
- **Cleaner, more maintainable code** with less boilerplate
- **Better performance** with optimized update strategies

The migration process is straightforward and can be done incrementally, allowing you to gradually adopt Firestore ODM's powerful features while maintaining your existing functionality.