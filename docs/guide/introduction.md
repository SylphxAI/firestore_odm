# What is Firestore ODM?

This project is a type-safe Object Document Mapper (ODM) for [Cloud Firestore](https://firebase.google.com/docs/firestore) on Dart and Flutter. It's designed from the ground up to solve the common frustrations of working with Firestore in a type-safe language, allowing you to build amazing apps faster and with fewer runtime errors.

## Why We Built This

If you've worked with the standard `cloud_firestore` package, you know the pain:

-   **No Type Safety**: You refer to fields using strings (`'isActive'`, `'profile.followers'`), which the compiler can't check. A simple typo can lead to a runtime error that's hard to find.
-   **Manual Serialization**: You have to manually convert `DocumentSnapshot` objects to your data models and back again, which is tedious and error-prone.
-   **Complex Queries**: Writing complex queries with nested logic can be difficult and hard to read.
-   **Incomplete Solutions**: Other ODMs for Flutter are often incomplete or not actively maintained.

We wanted a solution that provides:
✅ Complete, end-to-end type safety.
✅ Intuitive, readable, and chainable APIs.
✅ Automatic, seamless serialization.
✅ Powerful features that solve real-world problems.
✅ Active maintenance and a focus on the Flutter ecosystem.

## Firestore ODM vs Standard cloud_firestore

| Feature | Standard cloud_firestore | Firestore ODM |
|---------|-------------------------|---------------|
| **Type Safety** | ❌ `Map<String, dynamic>` everywhere | ✅ Strong types throughout |
| **Query Building** | ❌ String-based, error-prone | ✅ Type-safe with IDE support |
| **Data Updates** | ❌ Manual map construction | ✅ Explicit typed Firestore primitives |
| **Generic Support** | ❌ No generic handling | ✅ Full generic model support (3.0) |
| **Aggregations** | ❌ Basic count only | ✅ One-shot count, sum, and average |
| **Pagination** | ❌ Manual, inconsistency risks | ✅ Smart Builder, zero risk |
| **Transactions** | ❌ Manual read-before-write | ✅ Automatic deferred writes |
| **Code Generation** | ❌ None | ✅ Unified generated converters and selectors |
| **Model Reusability** | ❌ N/A | ✅ Same model, multiple collections |
| **Runtime Errors** | ❌ Common | ✅ Eliminated at compile-time |
| **Developer Experience** | ❌ Frustrating | ✅ Productive and enjoyable |

## Ready to Migrate?

If you're currently using the standard `cloud_firestore` package and want to experience these benefits, check out our comprehensive **[Migration Guide](/guide/migration-guide)** that walks you through migrating every feature step-by-step with detailed before/after examples.

## Quick Example

Here's a taste of what Firestore ODM looks like in action:

**Before (cloud_firestore):**
```dart
// String-based, error-prone
final snapshot = await FirebaseFirestore.instance
  .collection('users')
  .where('isActive', isEqualTo: true)
  .where('age', isGreaterThan: 18)
  .get();

List<Map<String, dynamic>> users = snapshot.docs
  .map((doc) => doc.data())
  .toList();
```

**After (Firestore ODM):**
```dart
// Type-safe, IDE-supported
List<User> users = await db.users
  .where(($) => $.and(
    $.isActive(isEqualTo: true),
    $.age(isGreaterThan: 18),
  ))
  .get();
```

Firestore ODM transforms Firestore from a source of frustration into a
powerful, type-safe database layer. Version 5 is a clean break: it uses native
Firestore semantics and does not retain a v4 API compatibility lane.
