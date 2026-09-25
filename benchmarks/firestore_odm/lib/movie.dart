import 'package:firestore_odm/firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

/// The benchmark document. json_serializable's `fromJson`/`toJson` serve the
/// raw cloud_firestore `withConverter` path; firestore_odm generates its own.
@JsonSerializable()
@firestoreOdm
class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.likes,
    required this.rating,
    required this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);

  @DocumentIdField()
  final String id;
  final String title;
  final int year;
  final int likes;
  final double rating;
  final List<String> genres;

  Map<String, dynamic> toJson() => _$MovieToJson(this);
}

class MovieSchema extends FirestoreSchema {
  const MovieSchema();
}

@Schema()
@Collection<Movie>('movies')
const movieSchema = MovieSchema();
