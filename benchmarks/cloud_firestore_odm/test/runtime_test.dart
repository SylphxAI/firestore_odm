/// Runtime cost of cloud_firestore_odm on the same workload as the
/// firestore_odm benchmark.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_odm_benchmark/movie.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../harness.dart';

Movie movie(int i) => Movie(
  id: 'm$i',
  title: 'Movie $i',
  year: 1950 + i % 70,
  likes: i,
  rating: (i % 50) / 10,
  genres: const ['drama', 'comedy'],
);

void main() {
  test('raw cloud_firestore', () async {
    await rawBaseline(
      'raw-cf5',
      FakeFirebaseFirestore(),
      movie,
      Movie.fromJson,
      (m) => m.toJson(),
    );
  });

  test('cloud_firestore_odm', () async {
    final movies = MovieCollectionReference(FakeFirebaseFirestore());
    await bench('cloud_firestore_odm', 'set', docs, () async {
      for (var i = 0; i < docs; i++) {
        await movies.doc('m$i').reference.set(movie(i));
      }
    });
    await bench('cloud_firestore_odm', 'get', docs, () async {
      for (var i = 0; i < docs; i++) {
        (await movies.doc('m$i').get()).data;
      }
    });
    await bench('cloud_firestore_odm', 'query', queries, () async {
      for (var i = 0; i < queries; i++) {
        final snapshot = await movies
            .whereYear(isGreaterThanOrEqualTo: 2000)
            .orderByLikes(descending: true)
            .limit(100)
            .get();
        snapshot.docs.map((d) => d.data).toList();
      }
    });
    await bench('cloud_firestore_odm', 'update', docs, () async {
      for (var i = 0; i < docs; i++) {
        await movies
            .doc('m$i')
            .update(likesFieldValue: FieldValue.increment(1));
      }
    });
    await bench('cloud_firestore_odm', 'mapping', mappings, () async {
      for (var i = 0; i < mappings; i++) {
        Movie.fromJson(movie(i).toJson());
      }
    });
  });
}
