# Subcollections

## Declare a subcollection

Add a `@Collection` whose path uses `*` for each parent document ID:

```dart
@Schema()
@Collection<User>('users')
@Collection<Post>('users/*/posts')
@Collection<Comment>('users/*/posts/*/comments')
const appSchema = AppSchema();
```

## Access a subcollection

Each subcollection gets a method on the ODM. Its name joins the path's
collection names, and it takes one argument per `*`, in path order:

| Path | Accessor |
|---|---|
| `users/*/posts` | `odm.usersPosts(userId)` |
| `users/*/posts/*/comments` | `odm.usersPostsComments(userId, postId)` |

```dart
final janePosts = odm.usersPosts('jane');

// Everything a root collection offers works here
await janePosts.set(post);
final hello = await janePosts('hello-world').get();
final recent = await janePosts
    .orderBy(($) => ($.createdAt(descending: true),))
    .limit(10)
    .get();

final comments = odm.usersPostsComments('jane', 'hello-world');
final count = await comments.count();
```

Subcollections also work in batches and transactions:

```dart
await odm.runBatch((batch) {
  odm.usersPosts('jane').inBatch(batch).delete('draft');
});
```

## One model, many collections

The same model can be used in any number of collections, for example `Post`
in both `posts` and `users/*/posts`. Its generated code exists once.

## Notes

- Always pass every parent ID. Passing `null` or leaving an argument out
  targets a path that contains the text `null`.
- Deleting a parent document does not delete its subcollections.
- Queries across all subcollections with the same name (collection group
  queries) are not available through the ODM. Use
  `odm.firestore.collectionGroup('posts')` from `cloud_firestore` for those.
