---
layout: home
title: firestore_odm
titleTemplate: Type-safe Firestore ODM for Flutter and Dart

hero:
  name: firestore_odm
  text: Type-safe Firestore for Flutter
  tagline: Describe your documents once and get typed queries, updates, aggregates, transactions and streams. A misspelled field is a compile error, not a production bug. The maintained successor to cloud_firestore_odm.
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
install: flutter pub add firestore_odm cloud_firestore firebase_core dev:firestore_odm_builder dev:build_runner
proof:
  - value: "1.5 s"
    label: rebuild after editing a model, 20 models (cloud_firestore_odm 17.3 s)
    link: /guide/benchmarks
  - value: "160/160"
    label: pub points on pub.dev
    link: https://pub.dev/packages/firestore_odm/score
  - value: "cloud_firestore 6"
    label: and firebase_core 4, freezed 3, analyzer 9 to 14
    link: /guide/getting-started

features:
  - title: Typed queries
    details: "<code>where(($) => $.age(isGreaterThan: 18) | $.tags(arrayContains: 'vip'))</code>, nested fields, ordering with record-typed cursors. A misspelled field is a compile error."
  - title: Typed updates
    details: "<code>patch(($) => [$.likes.increment(1), $.tags.arrayUnion(['new'])])</code>, plus <code>patchAll</code> and <code>deleteAll</code> over a query."
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
