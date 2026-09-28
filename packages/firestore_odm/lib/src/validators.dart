/// Runtime checks for the `@Min` and `@Max` field annotations.
///
/// The generated write paths call [validateNumericRange] before a document is
/// written, so an out-of-range value fails with a
/// [FirestoreODMValidationException] instead of reaching Firestore.
library;

import 'exceptions.dart';

/// Throws when [value] is outside the `@Min`/`@Max` bounds of [field].
///
/// Called by the generated serializers with the bounds declared on the model.
/// A null [value] (an unset optional field) and a non-numeric value pass, as
/// in `cloud_firestore_odm`.
void validateNumericRange(
  Object? value, {
  num? min,
  num? max,
  required String field,
}) {
  if (value is! num) return;
  if (min != null && value < min) {
    throw FirestoreODMValidationException(
      '$field must be at least $min, got $value',
      code: 'out_of_range',
      field: field,
    );
  }
  if (max != null && value > max) {
    throw FirestoreODMValidationException(
      '$field must be at most $max, got $value',
      code: 'out_of_range',
      field: field,
    );
  }
}
