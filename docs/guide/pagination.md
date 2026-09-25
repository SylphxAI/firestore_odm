# Pagination

Pagination uses the cursor methods of an ordered query. The `orderBy` record
sets the cursor's shape, so a cursor that does not match the ordering is a
compile error.

## Page through results

Use the last model of one page as the cursor for the next:

```dart
final query = odm.users.orderBy(($) => ($.age(), $.documentId()));

final page1 = await query.limit(20).get();

if (page1.isNotEmpty) {
  final page2 = await query.startAfterObject(page1.last).limit(20).get();
}
```

`startAfterObject` reads the ordered fields (here `age` and the document ID)
from the model. Ending the `orderBy` with `$.documentId()` gives every document
a unique position, so no document is skipped or repeated when several share
the same value.

## Cursor methods

With a model:

- `startAtObject(model)`
- `startAfterObject(model)`
- `endAtObject(model)`
- `endBeforeObject(model)`

With values, as a record of the same shape as the `orderBy` record:

- `startAt(values)`
- `startAfter(values)`
- `endAt(values)`
- `endBefore(values)`

```dart
// orderBy returns (int,), so the cursor is an (int,) record
final after1000 = await odm.users
    .orderBy(($) => ($.profile.followers(descending: true),))
    .startAfter((1000,))
    .limit(20)
    .get();

// Two fields: (int, String)
final page = await odm.users
    .orderBy(($) => ($.age(), $.name()))
    .startAfter((30, 'Jane'))
    .get();
```

Cursor methods return an ordered query, so you can still add `where`, `limit`
or `limitToLast`, and call `get`, `stream` or `count`.
