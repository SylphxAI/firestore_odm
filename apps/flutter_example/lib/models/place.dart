import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';

part 'place.g.dart';

/// A plain class (no json_serializable) whose library also imports
/// cloud_firestore, as models with GeoPoint or DocumentReference fields do.
@firestoreOdm
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    this.owner,
    this.photo,
    this.visitedAt,
  });

  @DocumentIdField()
  final String id;
  final String name;
  final GeoPoint location;
  final int rating;
  final DocumentReference<Map<String, dynamic>>? owner;
  final Blob? photo;
  final Timestamp? visitedAt;
}
