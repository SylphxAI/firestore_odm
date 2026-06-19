import 'package:firestore_odm/firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dart_immutable_user.g.dart';

@JsonSerializable()
@firestoreOdm
class DartImmutableUser {
  const DartImmutableUser({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.isPremium = false,
    this.rating = 0.0,
    this.skills = const [],
    this.metadata = const {},
    this.createdAt,
    this.internalNotes,
    this.isActive = true,
  });

  factory DartImmutableUser.fromJson(Map<String, dynamic> json) =>
      _$DartImmutableUserFromJson(json);
  @DocumentIdField()
  final String id;

  final String name;

  @JsonKey(name: 'user_email')
  final String email;

  final int age;

  @JsonKey(name: 'premium_status')
  final bool isPremium;

  final double rating;

  @JsonKey(name: 'skill_tags')
  final List<String> skills;

  @JsonKey(name: 'user_metadata')
  final Map<String, dynamic> metadata;

  @JsonKey(name: 'creation_date')
  final DateTime? createdAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? internalNotes;

  final bool isActive;

  // Copy with method for immutability
  DartImmutableUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    bool? isPremium,
    double? rating,
    List<String>? skills,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    String? internalNotes,
    bool? isActive,
  }) {
    return DartImmutableUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      isPremium: isPremium ?? this.isPremium,
      rating: rating ?? this.rating,
      skills: skills ?? this.skills,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      internalNotes: internalNotes ?? this.internalNotes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => _$DartImmutableUserToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DartImmutableUser &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.age == age &&
        other.isPremium == isPremium &&
        other.rating == rating &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, email, age, isPremium, rating, isActive);
  }

  @override
  String toString() {
    return 'DartImmutableUser(id: $id, name: $name, email: $email, age: $age, isPremium: $isPremium, rating: $rating, isActive: $isActive)';
  }
}
