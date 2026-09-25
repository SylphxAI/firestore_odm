/// Value conversion typedefs used by generated converters and selectors.
library;

/// Serializes a model instance into the Firestore document map.
typedef JsonSerializer<T> = Map<String, dynamic> Function(T value);

/// Deserializes a Firestore document map into a model instance.
typedef JsonDeserializer<T> = T Function(Map<String, dynamic> json);

/// Converts a single field value to its Firestore wire representation.
typedef FieldToJson<T> = dynamic Function(T value);

/// Converts a single Firestore wire value to the Dart field type.
typedef FieldFromJson<T> = T Function(dynamic value);
