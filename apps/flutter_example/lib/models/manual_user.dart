import 'package:firestore_odm/firestore_odm.dart';

part 'manual_user.g.dart';

@firestoreOdm
class ManualUser {
  const ManualUser({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.isPremium = false,
    this.rating = 0.0,
    this.tags = const [],
    this.preferences = const {},
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.debugInfo,
  });

  // Manual fromJson implementation
  factory ManualUser.fromJson(Map<String, dynamic> json) {
    return ManualUser(
      id: json['id'] as String,
      name: json['full_name'] as String, // Custom field name
      email: json['contact_email'] as String, // Custom field name
      age: json['user_age'] as int, // Custom field name
      isPremium: json['premium_member'] as bool? ?? false, // Custom field name
      rating:
          (json['user_rating'] as num?)?.toDouble() ?? 0.0, // Custom field name
      tags: (json['user_tags'] as List<dynamic>?)?.cast<String>() ?? [],
      preferences:
          (json['user_preferences'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
      createdAt: json['created_timestamp'] != null
          ? DateTime.parse(json['created_timestamp'] as String)
          : null,
      updatedAt: json['updated_timestamp'] != null
          ? DateTime.parse(json['updated_timestamp'] as String)
          : null,
      isActive: json['active_status'] as bool? ?? true, // Custom field name
      // debugInfo is intentionally not included in fromJson
    );
  }
  @DocumentIdField()
  final String id;

  final String name;
  final String email;
  final int age;
  final bool isPremium;
  final double rating;
  final List<String> tags;
  final Map<String, String> preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  // This field will be ignored in JSON serialization
  final String? debugInfo;

  // Copy with method for immutability
  ManualUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    bool? isPremium,
    double? rating,
    List<String>? tags,
    Map<String, String>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? debugInfo,
  }) {
    return ManualUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      isPremium: isPremium ?? this.isPremium,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      debugInfo: debugInfo ?? this.debugInfo,
    );
  }

  // Manual toJson implementation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name, // Custom field name
      'contact_email': email, // Custom field name
      'user_age': age, // Custom field name
      'premium_member': isPremium, // Custom field name
      'user_rating': rating, // Custom field name
      'user_tags': tags,
      'user_preferences': preferences,
      'created_timestamp': createdAt?.toIso8601String(),
      'updated_timestamp': updatedAt?.toIso8601String(),
      'active_status': isActive, // Custom field name
      // debugInfo is intentionally not included in toJson
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManualUser &&
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
    return 'ManualUser(id: $id, name: $name, email: $email, age: $age, isPremium: $isPremium, rating: $rating, isActive: $isActive)';
  }
}
