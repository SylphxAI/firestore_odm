import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'simple_generic.freezed.dart';
part 'simple_generic.g.dart';

@Freezed(genericArgumentFactories: true)
@firestoreOdm
abstract class SimpleGeneric<T> with _$SimpleGeneric<T> {
  const factory SimpleGeneric({
    required String id,
    required T value,
    required String type,
  }) = _SimpleGeneric<T>;

  factory SimpleGeneric.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$SimpleGenericFromJson(json, fromJsonT);
}

// Typedef for concrete usage in schema
typedef StringGeneric = SimpleGeneric<String>;
typedef IntGeneric = SimpleGeneric<int>;
