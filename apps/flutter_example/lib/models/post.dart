import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

/// Represents a blog post in the Firestore database.
@freezed
@firestoreOdm
abstract class Post with _$Post {
  /// Creates a new Post instance.
  const factory Post({
    @DocumentIdField() required String id,
    required String title,
    required String content,
    required String authorId,
    required List<String> tags,
    required Map<String, dynamic> metadata,
    required DateTime createdAt,
    @Default(0) int likes,
    @Default(0) int views,
    @Default(false) bool published,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) = _Post;

  /// Creates a Post instance from a JSON map.
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}
