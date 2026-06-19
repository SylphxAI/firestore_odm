/// Test model for nullable-input `fromJson` factories on non-nullable fields.
///
/// Regression coverage for GitHub Issue #5:
/// https://github.com/SylphxAI/firestore_odm/issues/5
///
/// A nested class whose `fromJson` factory accepts a **nullable** map parameter
/// (and gracefully returns a default for null) must be deserialized with a
/// **nullable** cast even when the parent field is non-nullable. Otherwise a
/// Firestore document that predates the field crashes with
/// `type 'Null' is not a subtype of type 'Map<String, Object?>' in type cast`.
///
/// The parent (`OrderWithDefault`) deliberately has NO custom `fromJson`/
/// `toJson`, so the firestore_odm builder generates `$OrderWithDefaultFromJson`
/// itself — the function that contained the buggy non-nullable cast.
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'defaulted_nested_test.g.dart';

/// Nested object whose `fromJson` accepts a nullable map and falls back to a
/// default instance when the value is absent — mirrors the issue's `Address`.
@JsonSerializable()
@firestoreOdm
class DefaultedAddress {
  const DefaultedAddress({this.street = '', this.city = ''});

  factory DefaultedAddress.fromJson(Map<String, Object?>? json) => json == null
      ? const DefaultedAddress()
      : _$DefaultedAddressFromJson(json);

  @JsonKey(defaultValue: '')
  final String street;
  @JsonKey(defaultValue: '')
  final String city;

  Map<String, dynamic> toJson() => _$DefaultedAddressToJson(this);
}

/// Parent model with a **non-nullable** nested field that has a default value.
///
/// No custom `fromJson`/`toJson`: the firestore_odm builder generates the
/// converter, exercising the nullable-cast logic for the nested field.
@firestoreOdm
class OrderWithDefault {
  const OrderWithDefault({
    required this.id,
    required this.productId,
    this.shippingAddress = const DefaultedAddress(),
  });

  @DocumentIdField()
  final String id;

  final String productId;

  /// Non-nullable, with a default. The generated `$OrderWithDefaultFromJson`
  /// must use a nullable cast here because `DefaultedAddress.fromJson` accepts
  /// a nullable map.
  final DefaultedAddress shippingAddress;
}
