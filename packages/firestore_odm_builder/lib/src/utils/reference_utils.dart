import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';

extension DartTypeExtension on DartType {
  TypeReference get reference {
    final element = this.element;
    if (element == null) {
      throw ArgumentError('DartType must have a valid element');
    }
    final name = element.name;
    if (name == 'dynamic') {
      return TypeReference((b) => b..symbol = 'dynamic');
    }

    final uri = element.library?.uri.toString();
    final typeArguments = switch (this) {
      InterfaceType type => type.typeArguments.map((t) => t.reference).toList(),
      _ => <TypeReference>[],
    };
    return TypeReference(
      (b) => b
        ..symbol = name
        ..url = uri
        ..types.addAll(typeArguments)
        ..isNullable = nullabilitySuffix == NullabilitySuffix.question
            ? true
            : null,
    );
  }

  List<DartType> get typeArguments {
    if (this is InterfaceType) {
      return (this as InterfaceType).typeArguments;
    }
    return [];
  }

  List<TypeParameterElement> get typeParameters {
    if (this is InterfaceType) {
      return (this as InterfaceType).element.typeParameters;
    }
    return [];
  }

  bool get isNullable {
    return nullabilitySuffix == NullabilitySuffix.question;
  }

  bool get isGeneric {
    if (this is InterfaceType) {
      return (this as InterfaceType).typeArguments.isNotEmpty;
    }
    return false;
  }
}

extension ElementExtension on Element {
  TypeReference get reference {
    final name = this.name;
    if (name == null) {
      throw ArgumentError('Element must have a valid name');
    }
    if (name == 'dynamic') {
      return TypeReference((b) => b..symbol = 'dynamic');
    }
    final library = this.library;
    final uri = library?.uri.toString();
    final typeParameters = switch (this) {
      TypeParameterizedElement e => e.typeParameters.toList(),
      _ => <TypeParameterElement>[],
    };
    return TypeReference(
      (b) => b
        ..symbol = name
        ..url = uri
        ..types.addAll(typeParameters.map((t) => t.reference)),
    );
  }
}

class TypeReferences {
  static final string = TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core',
  );
  static final int = TypeReference(
    (b) => b
      ..symbol = 'int'
      ..url = 'dart:core',
  );
  static final double = TypeReference(
    (b) => b
      ..symbol = 'double'
      ..url = 'dart:core',
  );
  static final bool = TypeReference(
    (b) => b
      ..symbol = 'bool'
      ..url = 'dart:core',
  );
  static final dynamic = TypeReference((b) => b..symbol = 'dynamic');
  static final list = TypeReference(
    (b) => b
      ..symbol = 'List'
      ..url = 'dart:core',
  );
  static final map = TypeReference(
    (b) => b
      ..symbol = 'Map'
      ..url = 'dart:core',
  );
  static final set = TypeReference(
    (b) => b
      ..symbol = 'Set'
      ..url = 'dart:core',
  );
  static final dateTime = TypeReference(
    (b) => b
      ..symbol = 'DateTime'
      ..url = 'dart:core',
  );
  static final duration = TypeReference(
    (b) => b
      ..symbol = 'Duration'
      ..url = 'dart:core',
  );

  static final timestamp = TypeReference(
    (b) => b
      ..symbol = 'Timestamp'
      ..url = 'package:cloud_firestore/cloud_firestore.dart',
  );

  static final geoPoint = TypeReference(
    (b) => b
      ..symbol = 'GeoPoint'
      ..url = 'package:cloud_firestore/cloud_firestore.dart',
  );

  static final documentReference = TypeReference(
    (b) => b
      ..symbol = 'DocumentReference'
      ..url = 'package:cloud_firestore/cloud_firestore.dart',
  );

  static final uint8List = TypeReference(
    (b) => b
      ..symbol = 'Uint8List'
      ..url = 'dart:typed_data',
  );

  static final bytes = TypeReference(
    (b) => b
      ..symbol = 'Bytes'
      ..url = 'package:firebase_storage/firebase_storage.dart',
  );

  static TypeReference listOf(TypeReference type) {
    return list.rebuild((b) => b..types.add(type));
  }

  static TypeReference mapOf(TypeReference key, TypeReference value) {
    return map.rebuild((b) => b..types.addAll([key, value]));
  }

  static TypeReference setOf(TypeReference type) {
    return set.rebuild((b) => b..types.add(type));
  }
}

extension TypeReferenceX on TypeReference {
  TypeReference withNullability(bool isNullable) {
    return rebuild((b) => b..isNullable = isNullable);
  }

  TypeReference withTypeArguments(List<TypeReference> typeArguments) {
    return rebuild((b) => b..types.addAll(typeArguments));
  }

  TypeReference withoutTypeArguments() {
    return rebuild((b) => b..types.clear());
  }

  TypeReference withoutNullability() {
    return rebuild((b) => b..isNullable = null);
  }
}

extension DartTypeIterableX on Iterable<DartType> {
  List<TypeReference> get references => map((t) => t.reference).toList();
}

extension ElementIterableX on Iterable<Element> {
  List<TypeReference> get references => map((e) => e.reference).toList();
}

extension Element2IterableX on Iterable<Element> {
  List<TypeReference> get references => map((e) => e.reference).toList();
}

extension ExpressionnX on Expression {
  /// Converts the expression to a string representation
  Expression debug(String message) {
    return refer('/* $message */ ${accept(DartEmitter())}');
  }
}
