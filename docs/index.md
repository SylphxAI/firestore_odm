---
layout: home
title: firestore_odm
titleTemplate: Type-safe Firestore ODM for Flutter and Dart

hero:
  name: firestore_odm
  text: Type-safe Firestore for Flutter
  tagline: Type-safe Firestore ODM for Flutter and Dart — the maintained successor to cloud_firestore_odm.
  actions:
    - theme: brand
      text: Get started
      link: /guide/getting-started
    - theme: alt
      text: Migrate from cloud_firestore_odm
      link: /guide/migrate-from-cloud-firestore-odm
    - theme: alt
      text: GitHub
      link: https://github.com/SylphxAI/firestore_odm

features:
  - title: Typed queries
    details: "where(($) => $.age(isGreaterThan: 18) | $.tags(arrayContains: 'vip')), nested fields, ordering with record-typed cursors. A misspelled field is a compile error."
  - title: Typed updates
    details: "patch(($) => [$.likes.increment(1), $.tags.arrayUnion(['new']), $.updatedAt.serverTimestamp()]), plus patchAll and deleteAll over a query."
  - title: Aggregates, transactions, batches
    details: "Server-side count, sum and average as a typed record; transactions with reads before deferred writes; typed batches."
  - title: Current Firebase
    details: "Built for cloud_firestore 6 and firebase_core 4, analyzer 9 to 14, freezed 3. Stable releases."
  - title: Any model style
    details: "Plain Dart classes, freezed or json_serializable. DateTime is stored as a Timestamp; GeoPoint, DocumentReference and Blob fields are stored natively."
  - title: One-command migration
    details: "A codemod moves a cloud_firestore_odm project over and lists anything left to finish by hand. Your data does not change."
---

```dart
final adults = await db.users
    .where(($) => $.age(isGreaterThanOrEqualTo: 18))
    .orderBy(($) => ($.age(descending: true), $.name()))
    .limit(20)
    .get(); // List<User>

await db.users('kim').patch(($) => [$.age.increment(1), $.lastLogin.serverTimestamp()]);

final stats = await db.users
    .aggregate(($) => (count: $.count(), averageAge: $.age.average()))
    .get(); // ({int count, double averageAge})
```
