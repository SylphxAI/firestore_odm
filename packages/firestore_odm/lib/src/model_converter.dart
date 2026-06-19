import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonDeserializer<T> = T Function(Map<String, dynamic>);
typedef JsonSerializer<T> = Map<String, dynamic> Function(T);

/// Base interface for Firestore field converters
/// T: Dart type, F: Firestore type
abstract interface class FirestoreConverter<T, F> {
  T fromJson(F data);
  F toJson(T data);

  factory FirestoreConverter.create({
    required T Function(F data) fromJson,
    required F Function(T data) toJson,
  }) => _FirestoreConverterImpl(fromJson: fromJson, toJson: toJson);
}

/// Converter for primitive types that need no conversion
class PrimitiveConverter<T> implements FirestoreConverter<T, T> {
  const PrimitiveConverter();

  @override
  T fromJson(T data) => data;

  @override
  T toJson(T data) => data;
}

class MapConverter<K, V>
    implements FirestoreConverter<Map<K, V>, Map<String, dynamic>> {
  final FirestoreConverter<K, dynamic> keyConverter;
  final FirestoreConverter<V, dynamic> valueConverter;

  const MapConverter(this.keyConverter, this.valueConverter);

  @override
  Map<K, V> fromJson(Map<String, dynamic> data) {
    return data.map(
      (key, value) =>
          MapEntry(keyConverter.fromJson(key), valueConverter.fromJson(value)),
    );
  }

  @override
  Map<String, dynamic> toJson(Map<K, V> data) {
    return data.map(
      (key, value) =>
          MapEntry(keyConverter.toJson(key), valueConverter.toJson(value)),
    );
  }
}

class IterableConverter<T>
    implements FirestoreConverter<Iterable<T>, List<dynamic>> {
  final FirestoreConverter<T, dynamic> elementConverter;

  const IterableConverter(this.elementConverter);

  @override
  Iterable<T> fromJson(List<dynamic> data) {
    return data.map((item) => elementConverter.fromJson(item));
  }

  @override
  List<dynamic> toJson(Iterable<T> data) {
    return data.map((item) => elementConverter.toJson(item)).toList();
  }
}

Map<String, R> mapToJson<K, V, R>(
  Map<K, V> data,
  String Function(K) keyToJson,
  R Function(V) valueToJson,
) {
  return data.map((key, value) {
    return MapEntry(keyToJson(key), valueToJson(value));
  });
}

Map<K, V> mapFromJson<K, V, R>(
  Map<String, R> data,
  K Function(String) keyFromJson,
  V Function(R) valueFromJson,
) {
  return data.map((key, value) {
    return MapEntry(keyFromJson(key), valueFromJson(value));
  });
}

List<R> listToJson<T, R>(Iterable<T> data, R Function(T) elementToJson) {
  return data.map((item) => elementToJson(item)).toList();
}

List<T> listFromJson<R, T>(List<R> data, T Function(R) elementFromJson) {
  return data.map((item) => elementFromJson(item)).toList();
}

class ListConverter<T, R> implements FirestoreConverter<List<T>, List<R>> {
  final FirestoreConverter<T, R> elementConverter;
  const ListConverter(this.elementConverter);

  @override
  List<T> fromJson(List<R> data) =>
      data.map((item) => elementConverter.fromJson(item)).toList();

  @override
  List<R> toJson(Iterable<T> data) => listToJson(data, elementConverter.toJson);
}

class SetConverter<T> extends IterableConverter<T> {
  const SetConverter(super.elementConverter);

  @override
  Set<T> fromJson(List<dynamic> data) => super.fromJson(data).toSet();
}

/// Converter for DateTime using ISO8601 string representation
class DateTimeConverter implements FirestoreConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String data) {
    return DateTime.parse(data);
  }

  @override
  String toJson(DateTime data) {
    return data.toIso8601String();
  }
}

/// Converter for Duration <-> int (microseconds)
class DurationConverter implements FirestoreConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int data) {
    return Duration(microseconds: data);
  }

  @override
  int toJson(Duration data) {
    return data.inMicroseconds;
  }
}

class NullableConverter<T, F> implements FirestoreConverter<T?, F?> {
  final FirestoreConverter<T, F> innerConverter;

  const NullableConverter(this.innerConverter);

  @override
  T? fromJson(F? data) {
    if (data == null) return null;
    return innerConverter.fromJson(data);
  }

  @override
  F? toJson(T? data) {
    if (data == null) return null;
    return innerConverter.toJson(data);
  }
}

/// Converter for Uint8List <-> Blob
class BytesConverter implements FirestoreConverter<Uint8List, Blob> {
  const BytesConverter();

  @override
  Uint8List fromJson(Blob data) => data.bytes;

  @override
  Blob toJson(Uint8List data) => Blob(data);
}

/// Converter for GeoPoint (no conversion needed, but provides consistency)
class GeoPointConverter implements FirestoreConverter<GeoPoint, GeoPoint> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(GeoPoint data) => data;

  @override
  GeoPoint toJson(GeoPoint data) => data;
}

/// Converter for DocumentReference (no conversion needed, but provides consistency)
class DocumentReferenceConverter
    implements FirestoreConverter<DocumentReference, DocumentReference> {
  const DocumentReferenceConverter();

  @override
  DocumentReference fromJson(DocumentReference data) => data;

  @override
  DocumentReference toJson(DocumentReference data) => data;
}

/// Generic converter for custom objects using fromJson/toJson functions
class _FirestoreConverterImpl<T, F> implements FirestoreConverter<T, F> {
  final F Function(T data) _toJson;
  final T Function(F data) _fromJson;

  const _FirestoreConverterImpl({
    required T Function(F data) fromJson,
    required F Function(T data) toJson,
  }) : _fromJson = fromJson,
       _toJson = toJson;

  @override
  T fromJson(F data) => _fromJson(data);

  @override
  F toJson(T data) => _toJson(data);
}

/// Predefined converter instances for common types
class FirestoreConverters {
  static const dateTime = DateTimeConverter();
  static const duration = DurationConverter();
  static const bytes = BytesConverter();
  static const geoPoint = GeoPointConverter();
  static const documentReference = DocumentReferenceConverter();
}
