/// Runtime cost of firestore_odm next to raw cloud_firestore (typed with
/// `withConverter`), on the same in-memory Firestore.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm_benchmark/movie.dart';
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
      'raw-cf6',
      FakeFirebaseFirestore(),
      movie,
      Movie.fromJson,
      (m) => m.toJson(),
    );
  });

  test('firestore_odm', () async {
    final movies = FirestoreODM(
      movieSchema,
      firestore: FakeFirebaseFirestore(),
    ).movies;
    await bench('firestore_odm', 'set', docs, () async {
      for (var i = 0; i < docs; i++) {
        await movies.set(movie(i));
      }
    });
    await bench('firestore_odm', 'get', docs, () async {
      for (var i = 0; i < docs; i++) {
        await movies('m$i').get();
      }
    });
    await bench('firestore_odm', 'query', queries, () async {
      for (var i = 0; i < queries; i++) {
        await movies
            .where(($) => $.year(isGreaterThanOrEqualTo: 2000))
            .orderBy(($) => ($.likes(descending: true),))
            .limit(100)
            .get();
      }
    });
    await bench('firestore_odm', 'update', docs, () async {
      for (var i = 0; i < docs; i++) {
        await movies.patch('m$i', ($) => [$.likes.increment(1)]);
      }
    });
    await bench('firestore_odm', 'mapping', mappings, () async {
      for (var i = 0; i < mappings; i++) {
        MovieFromJson(MovieToJson(movie(i))!);
      }
    });
  });
}
