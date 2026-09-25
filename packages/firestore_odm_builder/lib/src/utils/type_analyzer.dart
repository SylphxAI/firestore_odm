/// Static type analysis helpers for code generation.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'reference_utils.dart' show DartTypeExtension;

/// Utility class for analyzing Dart types during ODM generation.
class TypeAnalyzer {
  static const TypeChecker _string = TypeChecker.typeNamed(String);
  static const TypeChecker _int = TypeChecker.typeNamed(int);
  static const TypeChecker _double = TypeChecker.typeNamed(double);
  static const TypeChecker _num = TypeChecker.typeNamed(num);
  static const TypeChecker _bool = TypeChecker.typeNamed(bool);
  static const TypeChecker _dateTime = TypeChecker.typeNamed(DateTime);
  static const TypeChecker _duration = TypeChecker.typeNamed(Duration);
  static const TypeChecker _iterable = TypeChecker.typeNamed(Iterable);
  static const TypeChecker _map = TypeChecker.typeNamed(Map);

  static bool isString(DartType type) => _string.isExactlyType(type);

  static bool isBool(DartType type) => _bool.isExactlyType(type);

  static bool isNumeric(DartType type) => _num.isAssignableFromType(type);

  static bool isInt(DartType type) => _int.isExactlyType(type);

  static bool isDouble(DartType type) => _double.isExactlyType(type);

  static bool isDateTime(DartType type) =>
      _dateTime.isExactlyType(type) || isTimestamp(type);

  /// Detects cloud_firestore's Timestamp type by display name (the analyzer
  /// TypeChecker cannot be constructed for it by string in source_gen 4.x).
  static bool isTimestamp(DartType type) {
    final name = type.getDisplayString();
    return name == 'Timestamp' || name.endsWith('.Timestamp');
  }

  static bool isDuration(DartType type) => _duration.isExactlyType(type);

  static bool isEnum(DartType type) =>
      type is InterfaceType && type.element is EnumElement;

  static bool isIterable(DartType type) => _iterable.isAssignableFromType(type);

  static bool isMap(DartType type) => _map.isAssignableFromType(type);

  static bool isNullable(DartType type) => type.isNullable;

  /// Element type of an iterable.
  static DartType iterableElementType(DartType type) {
    if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
      return type.typeArguments.first;
    }
    throw ArgumentError('Type $type is not a parameterized iterable');
  }

  /// Key/value types of a map (null when not parameterized).
  static (DartType?, DartType?) mapTypes(DartType type) {
    if (type is ParameterizedType && type.typeArguments.length >= 2) {
      return (type.typeArguments[0], type.typeArguments[1]);
    }
    return (null, null);
  }
}
