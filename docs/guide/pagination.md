# Pagination

The ODM provides a fully type-safe pagination API that eliminates an entire class of common Firestore bugs.

## The Concept

Traditional Firestore pagination is error-prone because the sorting logic (`orderBy`) and the pagination cursor (`startAfter`) are defined separately. If they don't match perfectly in the number, order, and type of fields, you get a runtime error.

This ODM solves this by making the `orderBy` clause the single source of truth. The methods you use for pagination, like `startAfterObject`, use the information from the `orderBy` clause to automatically and safely construct the correct cursor.

## How to Paginate

Here is the standard pagination flow:

1.  **Create an ordered query**: You must use `.orderBy()` to define the sorting for your pagination.
2.  **Fetch the first page**: Use `.limit()` to get the first batch of documents.
3.  **Get the cursor**: The last document of the first page will serve as the cursor for the next page.
4.  **Fetch the next page**: Use a pagination method like `.startAfterObject()` with the cursor document.

```dart
// 1. Create a query, ordered by follower count and the document ID tie-breaker
final query = db.users.orderBy(($) => (
  $.profile.followers(descending: true),
  $.documentId(),
));

// 2. Fetch the first page of 20 users
final firstPage = await query.limit(20).get();

// 3. Get the last user from the first page to use as a cursor
if (firstPage.isNotEmpty) {
  final lastUser = firstPage.last;

  // 4. Fetch the next page of 20 users
  // The ODM automatically and safely extracts the 'followers' value from `lastUser`
  // to use as the cursor.
  final nextPage = await query.startAfterObject(lastUser).limit(20).get();
}
```

## Pagination Methods

### Object-Based Cursors (Recommended)

These methods are the safest and easiest to use. They automatically extract the correct cursor values from a model object you provide.

- `startAtObject(T object)`
- `startAfterObject(T object)`
- `endAtObject(T object)`
- `endBeforeObject(T object)`

### Value-Based Cursors

If you need more control, you can provide the cursor values manually. The ODM will still provide type-safety, ensuring the values you provide match the type signature of your `orderBy` clause.

- `startAt(O cursorValues)`
- `startAfter(O cursorValues)`
- `endAt(O cursorValues)`
- `endBefore(O cursorValues)`

```dart
// Manually providing cursor values. The type signature matches both orderBy
// terms, including the document ID tie-breaker.
final nextPage = await db.users
  .orderBy(($) => ($.profile.followers(descending: true), $.documentId()))
  .startAfter((1000, 'user-123'))
  .limit(20)
  .get();
