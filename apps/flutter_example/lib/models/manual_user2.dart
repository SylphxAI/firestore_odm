import 'package:equatable/equatable.dart';
import 'package:firestore_odm/firestore_odm.dart';

part 'manual_user2.g.dart';

@firestoreOdm
class ManualUser2 with EquatableMixin {
  const ManualUser2({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.isPremium = false,
    this.rating = 0.0,
    this.tags = const [],
    this.preferences = const {},
  });
  @DocumentIdField()
  final String id;

  final String name;
  final String email;
  final int age;
  final bool isPremium;
  final double rating;
  final List<String> tags;
  final Map<String, String> preferences;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    age,
    isPremium,
    rating,
    tags,
    preferences,
  ];
}
