# Aggregations

Aggregations run on the Firestore server and return only the result, not the
documents. Firestore bills one read per batch of up to 1,000 index entries
scanned, which costs far less than downloading the documents.

Aggregations are read once. There is no aggregation stream, because
`cloud_firestore` does not offer one. To refresh a count, run it again.

## count

```dart
final total = await odm.users.count();

final active = await odm.users
    .where(($) => $.isActive(isEqualTo: true))
    .count();
```

## sum, average and count together

`aggregate` takes a function that returns a record. Call `.get()` to run it; the
result is a record with the same field names.

```dart
final stats = await odm.users
    .where(($) => $.isActive(isEqualTo: true))
    .aggregate(($) => (
          count: $.count(),
          totalFollowers: $.profile.followers.sum(),
          averageAge: $.age.average(),
        ))
    .get();

print('${stats.count} users, average age ${stats.averageAge}');
```

- `$.count()` returns an `int`.
- `$.field.sum()` returns the field's type (`int` for an `int` field).
- `$.field.average()` returns a `double`, or `double.nan` when no document
  matches.

`sum` and `average` are available on numeric fields, including nested ones.
One query can hold up to 30 aggregations, which is Firestore's limit.
