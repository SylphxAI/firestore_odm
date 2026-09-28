/// Numeric `@Min`/`@Max` bounds, written both ways they are supported.
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'validated_movie.freezed.dart';
part 'validated_movie.g.dart';

/// A plain class: the bounds sit on the fields.
@firestoreOdm
class ValidatedMovie {
  const ValidatedMovie({
    required this.id,
    required this.likes,
    required this.rating,
    this.runtimeMinutes,
    this.score,
  });

  @DocumentIdField()
  final String id;

  /// Only a minimum.
  @Min(0)
  final int likes;

  /// Both bounds.
  @Min(0)
  @Max(100)
  final double rating;

  /// Only a maximum, on a nullable field.
  @Max(240)
  final int? runtimeMinutes;

  /// A nested model: its own bounds are checked when it is written.
  final ValidatedScore? score;
}

/// A freezed class: the bounds sit on the constructor parameters.
@freezed
@firestoreOdm
abstract class ValidatedScore with _$ValidatedScore {
  const factory ValidatedScore({
    @DocumentIdField() required String id,
    @Min(0) @Max(10) required int points,
    @Min(0) @Default(0) int penalties,
    @Default(50) int bonus,
  }) = _ValidatedScore;

  factory ValidatedScore.fromJson(Map<String, dynamic> json) =>
      _$ValidatedScoreFromJson(json);
}
