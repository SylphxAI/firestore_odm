import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm_builder/src/generators/converter_generator.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:source_gen/source_gen.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

class Updater {
  final TypeReference type;
  final Reference initializerRef;
  final Map<String, Expression> arguments;

  Updater({
    required this.type,
    Reference? initializerRef,
    required this.arguments,
  }) : initializerRef = initializerRef ?? type.withoutTypeArguments();
}

/// Generator for update builders and related classes using code_builder
class UpdateGenerator {
  /// Generate field update method for generic types
  static Field generateGenericFieldUpdateField(
    FieldInfo field, {
    Map<DartType, Expression> typeConverters = const {},
  }) {
    final fieldType = field.type;
    final fieldName = field.parameterName;
    final jsonFieldName = field.jsonName;

    // Check if this field is actually a type parameter (like T)
    final isTypeParameter = fieldType is TypeParameterType;
    // For type parameter fields, we need to use the appropriate converter
    // For concrete type fields (like String), use the standard logic
    final updater = field.customConverter != null
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'PatchBuilder'
                ..types.add(fieldType.reference)
                ..types.add(field.customConverter!.jsonType.reference),
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
              'toJson': field.customConverter!.toJson,
            },
          )
        : isTypeParameter
        ? Updater(
            type: TypeReference(
              (b) => b..symbol = '\$${field.type.element3!.name3}',
            ),
            initializerRef: refer(
              '_builderFunc${field.type.element3!.name3!.camelCase()}',
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
            },
          )
        : TypeAnalyzer.isDateTimeType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'DateTimeFieldUpdate'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
            },
          )
        : TypeAnalyzer.isDurationType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'DurationFieldUpdate'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
            },
          )
        : TypeAnalyzer.isNumericType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'NumericFieldUpdate'
                ..types.add(
                  fieldType.reference,
                ), // Use the actual type parameter
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
            },
          )
        : TypeChecker.fromRuntime(IMap).isAssignableFromType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'MapFieldUpdate'
                ..types.addAll([
                  fieldType.reference,
                  TypeAnalyzer.getMapKeyType(fieldType).reference,
                  TypeAnalyzer.getMapValueType(fieldType).reference,
                  getJsonType(type: TypeAnalyzer.getMapValueType(fieldType)),
                ]),
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
              'toJson': ConverterGenerator.getToJsonEnsured(
                type: fieldType,
                typeConverters: typeConverters,
              ),
              'keyToJson': ConverterGenerator.getToJsonEnsured(
                type: TypeAnalyzer.getMapKeyType(fieldType),
                typeConverters: typeConverters,
              ),
              'valueToJson': ConverterGenerator.getToJsonEnsured(
                type: TypeAnalyzer.getMapValueType(fieldType),
                typeConverters: typeConverters,
              ),
            },
          )
        : TypeChecker.fromRuntime(Map).isAssignableFromType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'DartMapFieldUpdate'
                ..types.addAll([
                  fieldType.reference,
                  TypeAnalyzer.getMapKeyType(fieldType).reference,
                  TypeAnalyzer.getMapValueType(fieldType).reference,
                  getJsonType(type: TypeAnalyzer.getMapValueType(fieldType)),
                ]),
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
              'keyToJson': ConverterGenerator.getToJsonEnsured(
                type: TypeAnalyzer.getMapKeyType(fieldType),
                typeConverters: typeConverters,
              ),
              'valueToJson': ConverterGenerator.getToJsonEnsured(
                type: TypeAnalyzer.getMapValueType(fieldType),
                typeConverters: typeConverters,
              ),
            },
          )
        : TypeAnalyzer.isIterableType(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'ListFieldUpdate'
                ..types.addAll([
                  fieldType.reference,
                  TypeAnalyzer.getIterableElementType(fieldType).reference,
                  getJsonType(
                    type: TypeAnalyzer.getIterableElementType(fieldType),
                  ),
                ]), // Use the actual type parameter
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
              'elementToJson': ConverterGenerator.getToJsonEnsured(
                type: TypeAnalyzer.getIterableElementType(fieldType),
                typeConverters: typeConverters,
              ),
            },
          )
        : TypeAnalyzer.isCustomClass(fieldType)
        ? Updater(
            type: TypeReference(
              (b) => b
                ..symbol = '${fieldType.reference.symbol}PatchBuilder'
                ..types.add(
                  fieldType.reference,
                ) // Use the actual type parameter
                ..types.addAll(
                  fieldType.reference.types,
                ), // Use the actual type parameter
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
              'toJson': ConverterGenerator.getToJsonEnsured(
                type: fieldType,
                typeConverters: typeConverters,
              ),
            },
          )
        : Updater(
            type: TypeReference(
              (b) => b
                ..symbol = 'PatchBuilder'
                ..types.add(fieldType.reference)
                ..types.add(getJsonType(type: fieldType)),
            ),
            arguments: {
              'field': refer(
                'path',
              ).property('append').call([literalString(jsonFieldName)]),
              'toJson': ConverterGenerator.getToJsonEnsured(type: fieldType),
            },
          );
    final bodyExpression = updater.initializerRef.newInstance(
      [],
      updater.arguments,
    );

    return Field(
      (b) => b
        ..docs.add('/// Update $fieldName field `${field.type}`')
        ..name = fieldName
        ..type = updater.type
        ..modifier = FieldModifier.final$
        ..late = true
        ..assignment = bodyExpression.code,
    );
  }

  static Set<TypeParameterElement2> computeNeededBuilders({
    required InterfaceType type,
  }) {
    final map = Map.fromIterables(
      type.typeArguments,
      type.element3.typeParameters2,
    );
    final fields = getFields(type);
    final fieldTypes = fields.values.map((field) => field.type).toSet();
    return fieldTypes.map((fieldType) => map[fieldType]).nonNulls.toSet();
  }

  static Iterable<DartType> grepAllGenericTypesRecursively(
    DartType type,
  ) sync* {
    if (type is InterfaceType) {
      yield* type.typeArguments;
      yield* type.typeArguments.expand(grepAllGenericTypesRecursively);
    }
  }

  static Set<TypeParameterElement2> computeNeededToJsons({
    required InterfaceType type,
  }) {
    final map = Map.fromIterables(
      type.typeArguments,
      type.element3.typeParameters2,
    );
    final fields = getFields(type);
    final fieldTypes = fields.values
        .expand((field) => grepAllGenericTypesRecursively(field.type))
        .toSet();
    return fieldTypes
        .map((fieldType) => map[fieldType])
        .where((t) => t != null)
        .nonNulls
        .toSet();
  }

  static Class generateBuilderClass({required InterfaceType type}) {
    final fields = getFields(type);
    final builders = computeNeededBuilders(type: type);
    final toJsons = computeNeededToJsons(type: type);
    return Class(
      (b) => b
        ..docs.add('/// Patch builder for `${type.name}` model')
        ..name = '${type.name}PatchBuilder'
        ..types.add(
          TypeReference(
            (b) => b
              ..symbol = '\$\$T'
              ..bound = type.reference.withNullability(true),
          ),
        )
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = TypeReference(
                      (b) => b
                        ..symbol = 'PatchBuilder'
                        ..types.addAll([t.reference, refer('dynamic')]),
                    ),
                ),
            ],
          ),
        )
        ..extend = TypeReference(
          (b) => b
            ..symbol = 'PatchBuilder'
            ..types.add(TypeReference((b) => b..symbol = '\$\$T'))
            ..types.add(
              TypeReferences.mapOf(
                TypeReferences.string,
                TypeReferences.dynamic,
              ).withNullability(true),
            ),
        )
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Creates a patch builder for `${type.name}`')
              ..optionalParameters.addAll([
                for (final typeParam in builders)
                  Parameter(
                    (b) => b
                      ..name = 'builderFunc${typeParam.name3!.camelCase()}'
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'PatchBuilderFunc'
                          ..types.addAll([
                            refer('${typeParam.name3}'),
                            refer('\$${typeParam.name3}'),
                          ]),
                      )
                      ..named = true
                      ..required = true,
                  ),
                for (final typeParam in toJsons)
                  Parameter(
                    (b) => b
                      ..name = 'toJson${typeParam.name3}'
                      ..type = FunctionType(
                        (b) => b
                          ..returnType = refer('dynamic')
                          ..requiredParameters.add(typeParam.reference),
                      )
                      ..named = true
                      ..required = true,
                  ),
                Parameter(
                  (b) => b
                    ..name = 'toJson'
                    ..required = true
                    ..toSuper = true
                    ..named = true,
                ),
                Parameter(
                  (b) => b
                    ..name = 'field'
                    ..toSuper = true
                    ..named = true,
                ),
              ])
              ..initializers.addAll([
                for (final typeParam in builders)
                  refer('_builderFunc${typeParam.name3!.camelCase()}')
                      .assign(
                        refer('builderFunc${typeParam.name3!.camelCase()}'),
                      )
                      .code,
                for (final typeParam in toJsons)
                  refer(
                    '_toJson${typeParam.name3}',
                  ).assign(refer('toJson${typeParam.name3}')).code,
              ]),
          ),
        )
        ..fields.addAll([
          for (final typeParam in toJsons)
            Field(
              (b) => b
                ..name = '_toJson${typeParam.name3}'
                ..modifier = FieldModifier.final$
                ..type = FunctionType(
                  (b) => b
                    ..returnType = refer('dynamic')
                    ..requiredParameters.add(typeParam.reference),
                ),
            ),
          for (final typeParam in builders)
            Field(
              (b) => b
                ..name = '_builderFunc${typeParam.name3!.camelCase()}'
                ..modifier = FieldModifier.final$
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'PatchBuilderFunc'
                    ..types.addAll([
                      refer('${typeParam.name3}'),
                      refer('\$${typeParam.name3}'),
                    ]),
                ),
            ),
          ...fields.values.map(
            (field) => generateGenericFieldUpdateField(
              field,
              typeConverters: {
                for (var (i, typeParam) in type.typeArguments.indexed)
                  typeParam: refer(
                    '_toJson${type.element3.typeParameters2[i].name3}',
                  ),
              },
            ),
          ),
        ]),
    );
  }

  static List<Spec> generateClasses({required InterfaceType type}) {
    final specs = <Spec>[];

    specs.add(generateBuilderClass(type: type));

    return specs;
  }

  static TypeReference getBuilderType({required DartType type}) {
    if (type is! InterfaceType || !TypeAnalyzer.isCustomClass(type)) {
      if (!TypeChecker.fromRuntime(num).isAssignableFromType(type)) {
        return TypeReference((b) => b..symbol = 'Never');
      }
      return TypeReference(
        (b) => b
          ..symbol = 'PatchBuilder'
          ..types.add(type.reference)
          ..types.add(getJsonType(type: type)),
      );
    }
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element3.thisType);
    return TypeReference(
      (b) => b
        ..symbol = '${type.element3.name3}PatchBuilder'
        ..types.add(type.reference)
        ..types.addAll(
          map.entries.expand(
            (t) => [
              t.value.reference,
              if (builders.contains(t.key)) getBuilderType(type: t.value),
            ],
          ),
        ),
    );
  }

  static Map<String, Expression> getConstructorBuildersParameters({
    required InterfaceType type,
    Map<DartType, Expression> typeConverters = const {},
  }) {
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element3.thisType);
    final toJsons = computeNeededToJsons(type: type.element3.thisType);

    return {
      for (final typeParam in builders)
        'builderFunc${typeParam.name3!.camelCase()}': Method(
          (b) => b
            ..lambda = true
            ..optionalParameters.addAll([
              Parameter(
                (b) => b
                  ..name = 'field'
                  ..required = true
                  ..named = true,
              ),
            ])
            ..body = getBuilderInstanceExpression(
              type: map[typeParam]!,
              field: refer('field'),
              typeConverters: typeConverters,
            ).code,
        ).closure,

      for (final typeParam in toJsons)
        'toJson${typeParam.name3}': ConverterGenerator.getToJsonEnsured(
          type: map[typeParam]!,
          typeConverters: typeConverters,
        ),
    };
  }

  static Expression getBuilderInstanceExpression({
    required DartType type,
    Expression? field,
    Map<DartType, Expression> typeConverters = const {},
  }) {
    if (!isUserType(type) &&
        !TypeChecker.fromRuntime(num).isAssignableFromType(type)) {
      return refer(
        'throw UnsupportedError',
      ).call([literalString('Unsupported type for aggregation')]);
    }
    return getBuilderType(type: type).newInstance([], {
      if (field != null) 'field': field,
      if (type is InterfaceType)
        ...getConstructorBuildersParameters(
          type: type,
          typeConverters: typeConverters,
        ),
      'toJson': ConverterGenerator.getToJsonEnsured(
        type: type,
        typeConverters: typeConverters,
      ),
    });
  }
}
