import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_odm/cloud_firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

/// The benchmark document, as cloud_firestore_odm declares it.
@JsonSerializable()
class Movie {
  Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.likes,
    required this.rating,
    required this.genres,
  });

  factory Movie.fromJson(Map<String, Object?> json) => _$MovieFromJson(json);

  @Id()
  final String id;
  final String title;
  final int year;
  final int likes;
  final double rating;
  final List<String> genres;

  Map<String, Object?> toJson() => _$MovieToJson(this);
}

@Collection<Movie>('movies')
final moviesRef = MovieCollectionReference();
