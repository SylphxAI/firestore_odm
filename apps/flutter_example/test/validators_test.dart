/// `@Min`/`@Max` bounds on numeric fields, checked on every write path.
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/validated_movie.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

ValidatedMovie movie({
  String id = 'm1',
  int likes = 10,
  double rating = 50,
  int? runtimeMinutes = 90,
  ValidatedScore? score,
}) => ValidatedMovie(
  id: id,
  likes: likes,
  rating: rating,
  runtimeMinutes: runtimeMinutes,
  score: score,
);

ValidatedScore score({
  String id = 's1',
  int points = 5,
  int penalties = 0,
  int bonus = 50,
}) =>
    ValidatedScore(id: id, points: points, penalties: penalties, bonus: bonus);

void main() {
  group('set', () {
    test('a value below @Min throws and nothing is written', () async {
      final (_, odm) = newDb();

      await expectValidationError(
        () => odm.validatedMovies.set(movie(likes: -1)),
      );

      expect(await odm.validatedMovies('m1').get(), isNull);
    });

    test('a value above @Max throws', () async {
      final (_, odm) = newDb();

      await expectValidationError(
        () => odm.validatedMovies.set(movie(rating: 100.5)),
      );
      expect(await odm.validatedMovies('m1').get(), isNull);
    });

    test(
      'an in-range value, the bounds themselves, and null all pass',
      () async {
        final (_, odm) = newDb();

        await odm.validatedMovies.set(movie());
        await odm.validatedMovies.set(movie(id: 'm2', likes: 0, rating: 100));
        await odm.validatedMovies.set(movie(id: 'm3', runtimeMinutes: 240));
        await odm.validatedMovies.set(movie(id: 'm4', runtimeMinutes: null));

        expect((await odm.validatedMovies('m1').get())?.likes, 10);
        expect((await odm.validatedMovies('m2').get())?.rating, 100);
        expect((await odm.validatedMovies('m3').get())?.runtimeMinutes, 240);
        final unset = await odm.validatedMovies('m4').get();
        expect(unset, isNotNull);
        expect(unset!.runtimeMinutes, isNull);
      },
    );

    test('a bound out of range on an optional-but-set field throws', () async {
      final (_, odm) = newDb();

      await expectValidationError(
        () => odm.validatedMovies.set(movie(runtimeMinutes: 241)),
      );
    });
  });

  group('create', () {
    test('a value above @Max throws', () async {
      final (_, odm) = newDb();

      await expectValidationError(
        () => odm.validatedScores.create(score(points: 11)),
      );
      expect(await odm.validatedScores.get(), isEmpty);
    });

    test('an in-range value is created', () async {
      final (_, odm) = newDb();

      final id = await odm.validatedScores.create(score(points: 10));

      expect((await odm.validatedScores(id).get())?.points, 10);
    });
  });

  group('patch', () {
    test(
      'a field set below @Min throws and the document is unchanged',
      () async {
        final (_, odm) = newDb();
        await odm.validatedMovies.set(movie(likes: 3));

        await expectValidationError(
          () => odm.validatedMovies('m1').patch(($) => [$.likes.set(-1)]),
        );

        expect((await odm.validatedMovies('m1').get())?.likes, 3);
      },
    );

    test('a nested field set out of range throws', () async {
      final (_, odm) = newDb();
      await odm.validatedMovies.set(movie(score: score(points: 5)));

      await expectValidationError(
        () => odm.validatedMovies('m1').patch(($) => [$.score.points.set(-2)]),
      );

      expect((await odm.validatedMovies('m1').get())?.score?.points, 5);
    });

    test('an in-range patch is applied', () async {
      final (_, odm) = newDb();
      await odm.validatedMovies.set(movie(likes: 3));

      await odm.validatedMovies('m1').patch(($) => [$.likes.set(4)]);

      expect((await odm.validatedMovies('m1').get())?.likes, 4);
    });
  });

  group('nested models', () {
    test('a nested value out of range throws on the parent write', () async {
      final (_, odm) = newDb();

      await expectValidationError(
        () => odm.validatedMovies.set(movie(score: score(points: 11))),
      );
      expect(await odm.validatedMovies('m1').get(), isNull);
    });

    test('a nested value in range is stored', () async {
      final (_, odm) = newDb();

      await odm.validatedMovies.set(movie(score: score(points: 7)));

      expect((await odm.validatedMovies('m1').get())?.score?.points, 7);
    });
  });

  group('freezed models', () {
    test('bounds on constructor parameters are checked', () async {
      final (_, odm) = newDb();

      await expectValidationError(
        () => odm.validatedScores.set(score(points: -1)),
      );
      await expectValidationError(
        () => odm.validatedScores.set(score(penalties: -1)),
      );
      expect(await odm.validatedScores('s1').get(), isNull);
    });

    test('an unannotated numeric field has no bound', () async {
      final (_, odm) = newDb();

      await odm.validatedScores.set(score(bonus: 5000));

      expect((await odm.validatedScores('s1').get())?.bonus, 5000);
    });
  });

  test('the error names the field and the bound', () async {
    final (_, odm) = newDb();

    await expectLater(
      odm.validatedMovies.set(movie(likes: -1)),
      throwsA(
        isA<FirestoreODMValidationException>()
            .having((e) => e.field, 'field', 'likes')
            .having((e) => e.code, 'code', 'out_of_range')
            .having((e) => e.message, 'message', contains('at least 0')),
      ),
    );
  });
}
