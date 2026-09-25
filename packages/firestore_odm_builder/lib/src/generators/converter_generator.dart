/// Serialization code generation.
///
/// Models that provide their own `toJson`/`fromJson` (freezed,
/// json_serializable, or manual) are used as-is; models without them get
/// generated public `XToJson` / `XFromJson` functions. DateTime is a native
/// Timestamp both directions; Duration is an int of microseconds.
library;

import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';
import 'package:json_annotation/json_annotation.dart' show JsonValue;
import 'package:source_gen/source_gen.dart';

import '../utils/model_analyzer.dart';
import '../utils/reference_utils.dart';
import '../utils/type_analyzer.dart';

/// The ODM always generates its own converters. The model's own
/// `toJson`/`fromJson` (freezed/json_serializable) serialize DateTime as ISO
/// strings for JSON interchange; Firestore storage must use native Timestamp
/// (ADR-0002), so storage serialization is always ODM-owned.
bool needsGeneratedConverters(InterfaceType type) => true;

/// A function expression converting a model instance to a document map:
/// `(value) => value.toJson()` when the model provides one, else `XToJson`.
Expression modelToJsonRef(DartType type) {
  if (hasOwnToJson(type as InterfaceType)) {
    return Method(
      (m) => m
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = type.reference,
          ),
        )
        ..body = refer('value').property('toJson').call(const []).code,
    ).closure;
  }
  return refer('${type.element.name}ToJson');
}

/// A function expression converting a document map to a model instance:
/// `X.fromJson` when the model provides one, else `XFromJson`.
Expression modelFromJsonRef(DartType type) {
  if (hasOwnFromJson(type as InterfaceType)) {
    return refer('${type.element.name}.fromJson');
  }
  return refer('${type.element.name}FromJson');
}

/// Serializes a single value of [type] for storage or filter use.
///
/// Every branch is null-tolerant (null-aware operators or nullable-accepting
/// helpers) so no re-evaluation of the source expression is needed — model
/// fields are often getters (freezed) that cannot be promoted.
Expression toJsonValue(
  DartType type,
  Expression value, {
  CustomConverter? customConverter,
  String? modelName,
  Expression? typeParamConverter,
}) {
  if (type is TypeParameterType) {
    if (typeParamConverter == null) return value;
    return typeParamConverter
        .equalTo(literalNull)
        .conditional(value, typeParamConverter.call([value]));
  }

  if (customConverter != null) {
    return value
        .equalTo(literalNull)
        .conditional(literalNull, customConverter.toJson.call([value]));
  }
  if (TypeAnalyzer.isDateTime(type)) {
    // Native Timestamp; the SDK converts DateTime<->Timestamp on the wire.
    return value;
  }
  if (TypeAnalyzer.isDuration(type)) {
    if (type.isNullable) return _nullAware(value, 'inMicroseconds');
    return value.property('inMicroseconds');
  }
  if (TypeAnalyzer.isEnum(type)) {
    final enumName = type.element!.name!;
    return refer(
      '_\$${modelName ?? _requireModelName(type)}$enumName'
      'ToJson',
    ).call([value]);
  }
  if (TypeAnalyzer.isMap(type)) {
    final (_, valueType) = TypeAnalyzer.mapTypes(type);
    if (valueType == null ||
        (!_needsConversion(valueType) && valueType is! TypeParameterType)) {
      return value;
    }
    final v = refer('v');
    final mapped = value.property('map').call([
      Method(
        (m) => m
          ..requiredParameters.addAll([
            Parameter((p) => p..name = 'k'),
            Parameter((p) => p..name = 'v'),
          ])
          ..body = refer('MapEntry').call([
            refer('k'),
            toJsonValue(valueType, v, modelName: modelName),
          ]).code,
      ).closure,
    ]);
    if (type.isNullable) {
      return _nullAware(value, 'map').call([
        Method(
          (m) => m
            ..requiredParameters.addAll([
              Parameter((p) => p..name = 'k'),
              Parameter((p) => p..name = 'v'),
            ])
            ..body = refer('MapEntry').call([
              refer('k'),
              toJsonValue(
                valueType,
                v,
                modelName: modelName,
                typeParamConverter: valueType is TypeParameterType
                    ? typeParamConverter
                    : null,
              ),
            ]).code,
        ).closure,
      ]);
    }
    return mapped;
  }
  if (TypeAnalyzer.isIterable(type)) {
    final elementType = TypeAnalyzer.iterableElementType(type);
    if (!_needsConversion(elementType) && elementType is! TypeParameterType) {
      return value;
    }
    final e = refer('e');
    final mapped = value
        .property('map')
        .call([
          Method(
            (m) => m
              ..requiredParameters.add(Parameter((p) => p..name = 'e'))
              ..body = toJsonValue(
                elementType,
                e,
                modelName: modelName,
                typeParamConverter: elementType is TypeParameterType
                    ? typeParamConverter
                    : null,
              ).code,
          ).closure,
        ])
        .property('toList')
        .call(const []);
    if (type.isNullable) {
      return _nullAware(value, 'map')
          .call([
            Method(
              (m) => m
                ..requiredParameters.add(Parameter((p) => p..name = 'e'))
                ..body = toJsonValue(
                  elementType,
                  e,
                  modelName: modelName,
                  typeParamConverter: elementType is TypeParameterType
                      ? typeParamConverter
                      : null,
                ).code,
            ).closure,
          ])
          .property('toList')
          .call(const []);
    }
    return mapped;
  }
  if (isUserType(type)) {
    return refer('${type.element!.name!}ToJson').call([value]);
  }
  return value;
}

/// Deserializes a single value of [type] from a document map.
Expression fromJsonValue(
  DartType type,
  Expression source, {
  CustomConverter? customConverter,
  String? modelName,
  Expression? typeParamConverter,
}) {
  Expression convert(Expression value) {
    if (customConverter != null) return customConverter.fromJson.call([value]);
    if (type is TypeParameterType) {
      if (typeParamConverter == null) return value.asA(type.reference);
      return typeParamConverter
          .equalTo(literalNull)
          .conditional(value, typeParamConverter.call([value]));
    }

    if (TypeAnalyzer.isDateTime(type)) {
      return refer('dateTimeFromJson').call([value]);
    }
    if (TypeAnalyzer.isDuration(type)) {
      return refer(
        'Duration',
      ).call(const [], {'microseconds': value.asA(TypeReferences.int)});
    }
    if (TypeAnalyzer.isEnum(type)) {
      final enumName = type.element!.name;
      return refer(
        '_\$${modelName ?? _requireModelName(type)}${enumName}FromJson',
      ).call([value]);
    }
    if (TypeAnalyzer.isMap(type)) {
      final (keyType, valueType) = TypeAnalyzer.mapTypes(type);
      final casted = value.asA(refer('Map<String, dynamic>'));
      final keyRef = keyType?.reference ?? refer('String');
      final valueRef = valueType?.reference ?? refer('dynamic');
      if (valueType == null ||
          (!_needsConversion(valueType) && valueType is! TypeParameterType)) {
        return casted.property('cast').call(const [], const {}, [
          keyRef,
          valueRef,
        ]);
      }
      final v = refer('v');
      return casted
          .property('map')
          .call([
            Method(
              (m) => m
                ..requiredParameters.addAll([
                  Parameter((p) => p..name = 'k'),
                  Parameter((p) => p..name = 'v'),
                ])
                ..body = refer(
                  'MapEntry',
                ).call([refer('k'), fromJsonValue(valueType, v)]).code,
            ).closure,
          ])
          .property('cast')
          .call(const [], const {}, [keyRef, valueRef]);
    }
    if (TypeAnalyzer.isIterable(type)) {
      final elementType = TypeAnalyzer.iterableElementType(type);
      final casted = value.asA(refer('List<dynamic>'));
      Expression inner;
      if (_needsConversion(elementType) || elementType is TypeParameterType) {
        final e = refer('e');
        inner = casted
            .property('map')
            .call([
              Method(
                (m) => m
                  ..requiredParameters.add(Parameter((p) => p..name = 'e'))
                  ..body = _body(
                    fromJsonValue(
                      elementType,
                      e,
                      typeParamConverter: elementType is TypeParameterType
                          ? typeParamConverter
                          : null,
                    ),
                  ).code,
              ).closure,
            ])
            .property('toList')
            .call(const []);
      } else {
        inner = casted;
      }
      if (_isSetType(type)) {
        return inner.property('toSet').call(const []).property('cast').call(
          const [],
          const {},
          [elementType.reference],
        );
      }
      return inner.property('cast').call(const [], const {}, [
        elementType.reference,
      ]);
    }
    if (isUserType(type)) {
      return modelFromJsonRef(
        type,
      ).call([value.asA(refer('Map<String, dynamic>'))]);
    }
    return value.asA(type.reference);
  }

  if (!type.isNullable) return convert(source);
  return source.equalTo(literalNull).conditional(literalNull, convert(source));
}

bool _isSetType(DartType type) => type.element?.name == 'Set';

bool _needsConversion(DartType type) {
  if (type is TypeParameterType) return false;
  if (TypeAnalyzer.isDateTime(type) || TypeAnalyzer.isDuration(type)) {
    return true;
  }
  if (TypeAnalyzer.isEnum(type)) return true;
  if (isUserType(type)) return true;
  return false;
}

/// Generates `XToJson`/`XFromJson` for models without their own converters,
/// plus per-model private enum helpers.
List<Spec> generateConverters(InterfaceType type) {
  final specs = <Spec>[];
  final fields = getFields(type);

  {
    final entries = <Expression, Expression>{};
    for (final field in fields.values) {
      // The document ID is INCLUDED in the serialized map: write paths strip
      // it before storage, and `set(model)` reads it back to locate the
      // document (ADR-0002).
      entries[literalString(field.jsonName)] = toJsonValue(
        field.type,
        refer('instance').property(field.parameterName),
        customConverter: field.customConverter,
        modelName: type.element.name,
        typeParamConverter: type.element.typeParameters.isEmpty
            ? null
            : refer('toT'),
      );
    }
    specs.add(
      Method(
        (m) => m
          ..name = '${type.element.name}ToJson'
          ..types.addAll(type.element.typeParameters.map((t) => t.reference))
          ..returns = refer('Map<String, dynamic>?')
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'instance'
                ..type = _nullableReference(type),
            ),
          )
          ..optionalParameters.addAll(_typeParamToJsonParams(type))
          ..body = refer('instance')
              .equalTo(literalNull)
              .conditional(literalNull, literalMap(entries))
              .code,
      ),
    );
  }

  {
    final args = <String, Expression>{};
    for (final field in fields.values) {
      args[field.parameterName] = fromJsonValue(
        field.type,
        refer('json').index(literalString(field.jsonName)),
        customConverter: field.customConverter,
        modelName: type.element.name,
        typeParamConverter: type.element.typeParameters.isEmpty
            ? null
            : refer('fromT'),
      );
    }
    specs.add(
      Method(
        (m) => m
          ..name = '${type.element.name}FromJson'
          ..types.addAll(type.element.typeParameters.map((t) => t.reference))
          ..returns = type.reference
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'json'
                ..type = refer('Map<String, dynamic>'),
            ),
          )
          ..optionalParameters.addAll(_typeParamFromJsonParams(type))
          ..body = refer(type.element.name!).newInstance([], args).code,
      ),
    );
  }

  specs.addAll(generateEnumHelpers(type));
  return specs;
}

String _requireModelName(DartType type) => throw StateError(
  'Enum helper name requires a modelName context for ${type.getDisplayString()}',
);

/// Generates per-model private enum mapping helpers for every enum field.
List<Spec> generateEnumHelpers(InterfaceType type) {
  final specs = <Spec>[];
  final seen = <String>{};
  for (final field in getFields(type).values) {
    final enumType = field.type;
    if (!TypeAnalyzer.isEnum(enumType)) continue;
    final enumName = enumType.element!.name;
    final helperName = '_\$${type.element.name!}$enumName';
    if (!seen.add(helperName)) continue;
    specs.addAll(_enumHelpers(helperName, enumType as InterfaceType));
  }
  return specs;
}

List<Spec> _enumHelpers(String helperName, InterfaceType enumType) {
  final enumName = enumType.element.name;
  final constants = enumType.element.fields
      .where((f) => f.isEnumConstant)
      .toList();

  final toEntries = <Expression, Expression>{};
  final fromEntries = <Expression, Expression>{};
  for (final c in constants) {
    final ann = TypeChecker.typeNamed(JsonValue).firstAnnotationOfExact(c);
    dynamic raw;
    if (ann != null) {
      raw = ConstantReader(ann).read('value').literalValue;
    } else {
      raw = c.name;
    }
    Expression jsonLit;
    if (raw is String) {
      jsonLit = literalString(raw);
    } else if (raw is int) {
      jsonLit = literalNum(raw);
    } else if (raw is double) {
      jsonLit = literalNum(raw);
    } else if (raw is bool) {
      jsonLit = literalBool(raw);
    } else {
      jsonLit = literalString(raw.toString());
    }
    final keyEnum = refer('$enumName.${c.name}');
    toEntries[keyEnum] = jsonLit;
    fromEntries[jsonLit] = keyEnum;
  }

  return [
    Method(
      (m) => m
        ..name = '${helperName}ToJson'
        ..returns = refer('Object?')
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = TypeReference(
                (b) => b
                  ..symbol = enumType.element.name!
                  ..url = enumType.element.library.uri.toString()
                  ..isNullable = true,
              ),
          ),
        )
        ..body = refer('value')
            .equalTo(literalNull)
            .conditional(
              literalNull,
              literalMap(toEntries).index(refer('value')),
            )
            .code,
    ),
    Method(
      (m) => m
        ..name = '${helperName}FromJson'
        ..returns = enumType.reference
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = refer('Object?'),
          ),
        )
        ..body = Code(
          'return switch (value) { ${_enumSwitchCases(fromEntries)} _ => throw ArgumentError("Unknown enum value for $enumName"), };',
        ),
    ),
  ];
}

/// Type references for common built-ins.
abstract final class TypeReferences {
  static final int = TypeReference(
    (b) => b
      ..symbol = 'int'
      ..url = 'dart:core',
  );
}

String _enumSwitchCases(Map<Expression, Expression> fromEntries) {
  final buffer = StringBuffer();
  for (final entry in fromEntries.entries) {
    final literal = entry.key.accept(DartEmitter(useNullSafetySyntax: true));
    final ref = entry.value.accept(DartEmitter(useNullSafetySyntax: true));
    buffer.write('$literal => $ref, ');
  }
  return buffer.toString();
}

/// Renders [expr] as a `return` statement for closure bodies (CodeExpression
/// bodies would otherwise emit as expression statements without `return`).
Expression _body(Expression expr) {
  final emitter = DartEmitter(useNullSafetySyntax: true);
  return CodeExpression(Code('return ${expr.accept(emitter)};'));
}

/// Renders `value?.member` (or `value?.member(args)`) without re-evaluating
/// [value]; required because model fields are often getters that cannot be
/// promoted after a null check.
Expression _nullAware(
  Expression value,
  String member, [
  List<Expression>? args,
]) {
  final emitter = DartEmitter(useNullSafetySyntax: true);
  final receiver = value.accept(emitter);
  if (args == null) return CodeExpression(Code('$receiver?.$member'));
  final renderedArgs = args.map((a) => a.accept(emitter)).join(', ');
  return CodeExpression(Code('$receiver?.$member($renderedArgs)'));
}

TypeReference _nullableReference(InterfaceType type) => TypeReference(
  (b) => b
    ..symbol = type.element.name!
    ..url = type.element.library.uri.toString()
    ..types.addAll(type.typeArguments.map((t) => t.reference))
    ..isNullable = true,
);

/// Optional `dynamic Function(T)? toT` per type parameter (freezed-style
/// genericArgumentFactories pattern for storage serialization).
List<Parameter> _typeParamToJsonParams(InterfaceType type) => [
  for (final t in type.element.typeParameters)
    Parameter(
      (b) => b
        ..name = 'toT'
        ..type = refer('dynamic Function(${t.name})?')
        ..named = true,
    ),
];

List<Parameter> _typeParamFromJsonParams(InterfaceType type) => [
  for (final t in type.element.typeParameters)
    Parameter(
      (b) => b
        ..name = 'fromT'
        ..type = refer('${t.name} Function(dynamic)?')
        ..named = true,
    ),
];
