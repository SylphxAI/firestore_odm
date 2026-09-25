/// Models may import cloud_firestore and use its value types directly.
library;

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_example/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('DocumentReference, Blob and Timestamp fields round-trip', () async {
    final (fake, odm) = newDb();
    final owner = fake.doc('users/alice');
    final visitedAt = Timestamp.fromMillisecondsSinceEpoch(1700000000000);
    await odm.places.set(
      Place(
        id: 'hk',
        name: 'Hong Kong',
        location: const GeoPoint(22.3, 114.2),
        rating: 5,
        owner: owner,
        photo: Blob(Uint8List.fromList([1, 2, 3])),
        visitedAt: visitedAt,
      ),
    );
    final place = await odm.places('hk').get();
    expect(place?.owner?.path, 'users/alice');
    expect(place?.photo?.bytes, [1, 2, 3]);
    expect(place?.visitedAt, visitedAt);
  });

  test('GeoPoint round-trips and aggregates work on the model', () async {
    final (_, odm) = newDb();
    await odm.places.set(
      const Place(
        id: 'hk',
        name: 'Hong Kong',
        location: GeoPoint(22.3, 114.2),
        rating: 5,
      ),
    );
    await odm.places.set(
      const Place(
        id: 'tpe',
        name: 'Taipei',
        location: GeoPoint(25, 121.5),
        rating: 3,
      ),
    );

    expect(
      (await odm.places('hk').get())?.location,
      const GeoPoint(22.3, 114.2),
    );
    final stats = await odm.places
        .aggregate(($) => (count: $.count(), total: $.rating.sum()))
        .get();
    expect(stats.count, 2);
    expect(stats.total, 8);
  });
}
