import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'simple_story.freezed.dart';
part 'simple_story.g.dart';

/// Test model without explicit @DocumentIdField() annotation
/// Should automatically use 'id' field as document ID
@freezed
@firestoreOdm
abstract class SimpleStory with _$SimpleStory {
  const factory SimpleStory({
    required String id, // Should be used as document ID automatically
    required String title,
    required String content,
    required String authorId,
    required DateTime createdAt,
    @Default([]) List<String> tags,
    DateTime? updatedAt,
  }) = _SimpleStory;

  factory SimpleStory.fromJson(Map<String, dynamic> json) =>
      _$SimpleStoryFromJson(json);
}
