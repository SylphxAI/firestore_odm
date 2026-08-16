# Subcollections

Declare subcollections with a wildcard path. The same model and generated
surface can be reused at the root and below a parent document:

```dart
@Schema()
@Collection<User>('users')
@Collection<Post>('users/*/posts')
@Collection<Comment>('users/*/posts/*/comments')
const appSchema = AppSchema();
```

The generator names subcollection accessors from the full path. Parent IDs are
arguments, so there is no hidden document-handle compatibility layer:

```dart
final posts = db.usersPosts('user-1');
await posts.set(Post(id: 'post-1', title: 'Hello'));

final comments = db.usersPostsComments('user-1', 'post-1');
await comments.create(Comment(id: '', body: 'Welcome'));
```

The same accessors work with batches and transactions:

```dart
await db.runBatch((batch) {
  db.usersPosts('user-1').inBatch(batch).set(post);
});
```

Each collection still exposes the normal v5 `get`, `stream`, `where`,
`orderBy`, `create`, `set`, `patch`, `delete`, `patchAll`, and `deleteAll`
operations.
