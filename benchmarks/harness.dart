/// Timing and the raw cloud_firestore baseline, shared by the runtime
/// benchmarks of both projects (each runs the baseline on its own
/// cloud_firestore major and in-memory Firestore).
library;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Rounds per measurement; the median is reported.
const rounds = 7;

/// Documents written, read and updated per round.
const docs = 500;

/// Queries per round.
const queries = 20;

/// Model-to-map-to-model conversions per round.
const mappings = 20000;

/// Runs [body] ([ops] operations) [rounds] times after one warm-up round and
/// prints `BENCH <variant> <name> <median microseconds per operation>`.
Future<void> bench(
  String variant,
  String name,
  int ops,
  Future<void> Function() body,
) async {
  await body();
  final perOp = <double>[];
  for (var i = 0; i < rounds; i++) {
    final watch = Stopwatch()..start();
    await body();
    perOp.add(watch.elapsedMicroseconds / ops);
  }
  perOp.sort();
  stdout.writeln(
    'BENCH $variant $name ${perOp[rounds ~/ 2].toStringAsFixed(2)}',
  );
}

/// The same workload through raw cloud_firestore, typed with
/// `withConverter` and the model's json_serializable functions.
Future<void> rawBaseline<M>(
  String variant,
  FirebaseFirestore firestore,
  M Function(int i) movie,
  M Function(Map<String, dynamic> json) fromJson,
  Map<String, dynamic> Function(M movie) toJson,
) async {
  final movies = firestore
      .collection('movies')
      .withConverter<M>(
        fromFirestore: (s, _) => fromJson({...s.data()!, 'id': s.id}),
        toFirestore: (m, _) => toJson(m)..remove('id'),
      );
  await bench(variant, 'set', docs, () async {
    for (var i = 0; i < docs; i++) {
      await movies.doc('m$i').set(movie(i));
    }
  });
  await bench(variant, 'get', docs, () async {
    for (var i = 0; i < docs; i++) {
      (await movies.doc('m$i').get()).data();
    }
  });
  await bench(variant, 'query', queries, () async {
    for (var i = 0; i < queries; i++) {
      final snapshot = await movies
          .where('year', isGreaterThanOrEqualTo: 2000)
          .orderBy('likes', descending: true)
          .limit(100)
          .get();
      snapshot.docs.map((d) => d.data()).toList();
    }
  });
  await bench(variant, 'update', docs, () async {
    for (var i = 0; i < docs; i++) {
      await movies.doc('m$i').update({'likes': FieldValue.increment(1)});
    }
  });
  await bench(variant, 'mapping', mappings, () async {
    for (var i = 0; i < mappings; i++) {
      fromJson(toJson(movie(i)));
    }
  });
}
