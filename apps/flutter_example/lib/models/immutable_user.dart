import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'immutable_user.freezed.dart';
part 'immutable_user.g.dart';

@freezed
@firestoreOdm
abstract class ImmutableUser with _$ImmutableUser {
  const factory ImmutableUser({
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    @Default(IListConst([])) IList<String> tags,
    @Default(IListConst([])) IList<int> scores,
    @Default(IMapConst({})) IMap<String, String> settings,
    @Default(ISetConst({})) ISet<String> categories,
    @Default(0.0) double rating,
    @Default(false) bool isActive,
    DateTime? createdAt,
  }) = _ImmutableUser;
  const ImmutableUser._();

  factory ImmutableUser.fromJson(Map<String, dynamic> json) =>
      _$ImmutableUserFromJson(json);
}
