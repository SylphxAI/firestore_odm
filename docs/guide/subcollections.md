> **5.0 note:** this guide documents the v4 API surface. See
> [migration-guide-5](./migration-guide-5) and [getting-started](./getting-started)
> for the current 5.0 API (create/set/patch/delete, no sentinels, no modify).
>
# Subcollections

The ODM provides a fluent, type-safe API for defining and accessing subcollections. One of the key advantages is that **the same model can be reused in both collections and subcollections without generating additional code**, keeping your build output minimal and efficient.

## Defining Subcollections

You define subcollections in your schema file alongside your root-level collections. The key is to use a path with a wildcard (`*`) to represent the parent document's ID.

In this example, we define a `posts` subcollection that lives under each `user` document.

```dart
// lib/schema.dart

@Schema()
// Root-level collection
@Collection<User>("users")
// Subcollection of users. The '*' is a wildcard for the user ID.
@Collection<Post>("users/*/posts")
final appSchema = _$AppSchema;
```

The generator will automatically detect this relationship and create the necessary accessors.

## Accessing Subcollections

Once defined, you can access a subcollection by chaining a property accessor onto a document reference. The ODM automatically handles inserting the correct document ID into the path.

```dart
// Get a reference to a specific user document
final userDoc = db.users('jane-doe');

// Access the 'posts' subcollection for that user
final postsCollection = userDoc.posts;

// Now you can perform any standard collection operation on it
final allPosts = await postsCollection.get();

await postsCollection.insert(
  Post(id: 'my-first-post', title: 'Hello from a subcollection!'),
);
```

You can chain these calls to access deeply nested subcollections as well, as long as they are defined in your schema.

```dart
// Example of accessing a nested sub-subcollection
// This would require a "users/*/posts/*/comments" definition in the schema.
```

## Model Reusability

A major advantage of Firestore ODM is that **the same model can be used in both root collections and subcollections without duplicating generated code**. This keeps your build output minimal and efficient.

```dart
// The same Post model works in both contexts:

// As a root collection
@Collection<Post>("posts")

// As a subcollection under users
@Collection<Post>("users/*/posts")

// As a subcollection under categories
@Collection<Post>("categories/*/posts")
```

The ODM's smart code generation ensures that:
- **No duplicate code** is generated for the same model
- **Build times remain fast** regardless of how many collections use the same model
- **Generated code stays minimal** using highly optimized callables and Dart extensions

This approach allows you to organize your data flexibly without worrying about code bloat or performance impact.
final comments = db.users('jane-doe').posts('my-first-post').comments;