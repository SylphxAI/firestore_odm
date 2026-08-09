/// Model analysis: constructor-driven field discovery, document-ID detection,
/// JsonKey/JsonConverter support, and converter-capability detection.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'reference_utils.dart';

/// A custom `@JsonConverter` attached to a field.
class CustomConverter {
  final InterfaceType type;
  final DartType jsonType;

  Expression get toJson => type.reference.constInstance([]).property('toJson');

  Expression get fromJson =>
      type.reference.constInstance([]).property('fromJson');

  CustomConverter({required this.type, required this.jsonType});
}

/// A discovered model field (constructor parameter).
class FieldInfo {
  final String parameterName;
  final String jsonName;
  final DartType type;
  final bool isDocumentId;
  final CustomConverter? customConverter;
  final bool isNullable;

  const FieldInfo({
    required this.parameterName,
    required this.jsonName,
    required this.type,
    required this.isDocumentId,
    required this.customConverter,
    required this.isNullable,
  });
}

/// Types the ODM handles natively (no generated converter needed).
bool isHandledType(DartType type) {
  return isPrimitive(type) ||
      TypeChecker.typeNamed(Iterable).isAssignableFromType(type) ||
      TypeChecker.typeNamed(Map).isAssignableFromType(type) ||
      TypeChecker.typeNamed(DateTime).isExactlyType(type) ||
      TypeChecker.typeNamed(Duration).isExactlyType(type) ||
      (type is InterfaceType && type.element is EnumElement);
}

/// A user-defined model type requiring a converter.
bool isUserType(DartType type) {
  if (type is TypeParameterType) return false;
  return !isHandledType(type);
}

bool isPrimitive(DartType type) {
  return type.isDartCoreBool ||
      type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreString ||
      type.isDartCoreNull ||
      type is DynamicType;
}

/// Discovers fields from the default constructor.
///
/// Throws when the model has no default constructor so misgeneration is
/// impossible (a silent empty field set was a v4 defect).
Map<String, FieldInfo> getFields(InterfaceType type) {
  final constructor = getDefaultConstructor(type);
  if (constructor == null) {
    throw InvalidGenerationSourceError(
      'Model ${type.getDisplayString()} must declare a default (unnamed) '
      'constructor so the ODM can map document fields to it.',
      element: type.element,
    );
  }

  final documentIdParamName = getDocumentIdFieldName(type);
  final fields = <String, FieldInfo>{};

  for (final parameter in constructor.formalParameters) {
    if (parameter.isStatic) continue;
    final paramName = parameter.name!;
    var jsonName = paramName;
    var include = true;

    final jsonKey = TypeChecker.typeNamed(
      JsonKey,
    ).firstAnnotationOfExact(parameter);
    if (jsonKey != null) {
      final reader = ConstantReader(jsonKey);
      jsonName = reader.read('name').literalValue as String? ?? paramName;
      final includeFromJson =
          reader.read('includeFromJson').literalValue as bool? ?? true;
      final includeToJson =
          reader.read('includeToJson').literalValue as bool? ?? true;
      include = includeFromJson && includeToJson;
      if (!include) continue;
    }

    final customConverter =
        TypeChecker.typeNamed(
              JsonConverter,
            ).annotationsOf(parameter).firstOrNull?.type
            as InterfaceType?;

    fields[paramName] = FieldInfo(
      parameterName: paramName,
      jsonName: jsonName,
      type: parameter.type,
      isDocumentId: paramName == documentIdParamName,
      customConverter: customConverter != null
          ? CustomConverter(
              type: customConverter,
              jsonType: customConverter
                  .lookUpMethod('toJson', customConverter.element.library)!
                  .returnType,
            )
          : null,
      isNullable:
          parameter.type.nullabilitySuffix == NullabilitySuffix.question,
    );
  }

  return fields;
}

ConstructorElement? getDefaultConstructor(InterfaceType type) {
  return type.constructors
      .where((c) => c.name == 'new' || (c.name ?? '').isEmpty)
      .firstOrNull;
}

/// The constructor parameter that holds the document ID: the one annotated
/// with `@DocumentIdField`, else a String parameter named `id`, else null.
String? getDocumentIdFieldName(InterfaceType type) {
  final constructor = getDefaultConstructor(type);
  if (constructor == null) return null;

  final annotated = constructor.formalParameters.where(
    (p) => TypeChecker.typeNamed(DocumentIdField).hasAnnotationOf(p),
  );
  if (annotated.length > 1) {
    throw InvalidGenerationSourceError(
      'Multiple @DocumentIdField parameters found in ${type.getDisplayString()}',
      element: type.element,
    );
  }
  if (annotated.length == 1) {
    final param = annotated.single;
    if (!param.type.isDartCoreString) {
      throw InvalidGenerationSourceError(
        '@DocumentIdField must be a String in ${type.getDisplayString()}',
        element: type.element,
      );
    }
    return param.name;
  }

  final idParam = constructor.formalParameters
      .where((p) => p.name == 'id' && p.type.isDartCoreString)
      .firstOrNull;
  return idParam?.name;
}

/// Whether the model provides its own `toJson()` instance method.
bool hasOwnToJson(InterfaceType type) {
  return type.methods.any(
    (m) => m.name == 'toJson' && !m.isStatic && m.returnType.isDartCoreMap,
  );
}

/// Whether the model provides its own `fromJson` factory or static method.
bool hasOwnFromJson(InterfaceType type) {
  if (type.constructors.any((c) => c.name == 'fromJson')) return true;
  return type.methods.any(
    (m) => m.name == 'fromJson' && m.isStatic && m.formalParameters.length == 1,
  );
}
