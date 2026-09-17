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
| **Data Updates** | ❌ Manual map construction | ✅ Two powerful update strategies |
| **Generic Support** | ❌ No generic handling | ✅ Full generic model support (3.0) |
| **Aggregations** | ❌ Basic count only | ✅ Comprehensive + streaming |
| **Pagination** | ❌ Manual, inconsistency risks | ✅ Smart Builder, zero risk |
| **Transactions** | ❌ Manual read-before-write | ✅ Automatic deferred writes |
| **Code Generation** | ❌ None | ✅ Inline-optimized, 15% smaller (3.0) |
| **Model Reusability** | ❌ N/A | ✅ Same model, multiple collections |
| **Runtime Errors** | ❌ Common | ✅ Eliminated at compile-time |
| **Developer Experience** | ❌ Frustrating | ✅ Productive and enjoyable |

## Dart and Flutter, not Firebase Admin

Firestore ODM wraps the client SDK: it generates code on top of
[`cloud_firestore`](https://pub.dev/packages/cloud_firestore) and its model
converter runs wherever that package runs. `firestore_odm` and
`firestore_odm_builder` declare `flutter` in `topics`, the runtime package
declares `environment: flutter`, and its tests are `flutter_test` suites, so the
packages are published as Flutter packages and consumed by Flutter/Dart apps.

That means the ODM is **not** a server-side library today:

- **Cloud Run / Cloud Functions (Firebase Admin SDK)**. The Admin SDK exposes
  `firebase_admin` (Dart) / `firebase-admin` (Node, Python, Go, Java), which
  talks to Firestore with an admin credential rather than a client app. The ODM
  does not generate against that surface, so the same annotations are not
  currently usable from a Cloud Run service or a Node function.
- **Pure Dart (no Flutter SDK)**. The generated code itself is plain Dart; the
  constraint is the package's own `flutter` dependency and `flutter_test` dev
  dependency, which a pure-Dart (server/CLI) consumer would have to pull in.

Supporting the Admin SDK or pure Dart is a product-direction decision, not a
mechanical refactor: it changes the declared platform, the tested surface, and
the packages' "Flutter package" identity. Firestore ODM is in the Maintain
lifecycle ([company register](https://github.com/SylphxAI/owner/blob/main/PORTFOLIO.md)),
which responds to concrete requests rather than manufacturing improvement work;
a request to add a server-side generation target is tracked as
[issue #44](https://github.com/SylphxAI/firestore_odm/issues/44) and stays open
until that direction is decided.

Dart/Flutter code that runs in a server context today can still use the ODM by
talking to Firestore through a client credential, or by keeping the ODM on the
client and calling a server API in front of Firestore.

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

Firestore ODM transforms Firestore from a source of frustration into a powerful, type-safe database layer that enhances your Flutter development experience.
