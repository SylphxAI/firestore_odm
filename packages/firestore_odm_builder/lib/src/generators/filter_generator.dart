import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/generators/converter_generator.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:firestore_odm_builder/src/utils/type_definition.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for filter builders and filter classes using code_builder
class FilterGenerator {
  /// Generate field getter method based on field type
  static Field _generateFieldGetter({required FieldInfo field}) {
    final typeDef = getBuilderDef(
      type: field.type,
      customConverter: field.customConverter,
    );

    final String fieldName = field.jsonName;

    return Field(
      (b) => b
        ..docs.add('/// Filter by ${field.parameterName}')
        ..name = field.parameterName
        ..modifier = FieldModifier.final$
        ..late = true
        ..type = typeDef.type
        ..assignment = typeDef.instance.newInstance([], {
          'field': field.isDocumentId
              ? refer('FieldPath.documentId')
              : refer(
                  'path',
                ).property('append').call([literalString(fieldName)]),
          ...typeDef.namedArguments,
        }).code,
    );
  }

  static Class generateFilterSelectorClass(InterfaceType type) {
    final className = type.element.name;

    final builders = computeNeededBuilders(type: type);

    // Generate methods for all fields
    final fields = getFields(
      type,
    ).values.map((field) => _generateFieldGetter(field: field)).toList();

    // Create extension
    return Class(
      (b) => b
        ..name = '${className}FilterBuilder'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('FilterBuilderNode'),
                ),
            ],
          ),
        )
        ..extend = refer('FilterBuilderNode')
        ..docs.add('/// Generated FilterBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Creates a filter selector for `$className`')
              ..optionalParameters.addAll([
                for (final typeParam in builders)
                  Parameter(
                    (b) => b
                      ..name = 'builderFunc${typeParam.name3!.camelCase()}'
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'FilterBuilderFunc'
                          ..types.add(refer('\$${typeParam.name3}')),
                      )
                      ..named = true
                      ..required = true,
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
              ]),
          ),
        )
        ..fields.addAll([
          for (final typeParam in builders)
            Field(
              (b) => b
                ..name = '_builderFunc${typeParam.name3!.camelCase()}'
                ..modifier = FieldModifier.final$
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'FilterBuilderFunc'
                    ..types.add(refer('\$${typeParam.name3}')),
                ),
            ),
        ])
        ..fields.addAll(fields),
    );
  }

  static Class generateRootFilterSelectorClass(InterfaceType type) {
    final className = type.element3.name3;
    final builders = computeNeededBuilders(type: type.element3.thisType);
    // Create extension
    return Class(
      (b) => b
        ..name = '${className}FilterBuilderRoot'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('FilterBuilderNode'),
                ),
            ],
          ),
        )
        ..extend = TypeReference(
          (b) => b
            ..symbol = '${className}FilterBuilder'
            ..types.addAll(
              type.element3.typeParameters2.expand(
                (t) => [
                  t.reference,
                  if (builders.contains(t))
                    TypeReference((b) => b..symbol = '\$${t.name3}'),
                ],
              ),
            ),
        )
        ..mixins.add(refer('FilterBuilderRoot'))
        ..docs.add('/// Generated RootFilterBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Creates a root filter selector for `$className`')
              ..optionalParameters.addAll([
                for (final typeParam in computeNeededBuilders(
                  type: type.element3.thisType,
                ))
                  Parameter(
                    (b) => b
                      ..name = 'builderFunc${typeParam.name3!.camelCase()}'
                      ..toSuper = true
                      ..named = true
                      ..required = true,
                  ),
              ]),
          ),
        ),
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

  static List<Spec> generateClasses(InterfaceType type) {
    final specs = <Spec>[];

    // Generate FilterSelector class
    specs.add(generateFilterSelectorClass(type));

    // Generate RootFilterSelector class
    specs.add(generateRootFilterSelectorClass(type));

    return specs;
  }

  static TypeReference getBuilderType({
    required DartType type,
    CustomConverter? customConverter,
    bool isRoot = false,
  }) {
    return getBuilderDef(
      type: type,
      customConverter: customConverter,
      isRoot: isRoot,
    ).type;
  }

  static TypeDefinition getBuilderDef({
    required DartType type,
    CustomConverter? customConverter,
    bool isRoot = false,
  }) {
    if (type is TypeParameterType) {
      return TypeDefinition(
        type: TypeReference((b) => b..symbol = '\$${type.element3.name3}'),
        instance: refer('_builderFunc${type.element3.name3!.camelCase()}'),
        // namedArguments: {
        //   'toJson': ConverterGenerator.getToJsonEnsured(
        //     type: field.type,
        //     customConverter: field.customConverter,
        //   ),
        // },
      );
    }

    final jsonType =
        customConverter?.jsonType.reference ?? getJsonType(type: type);

    if (jsonType.symbol == 'int' ||
        jsonType.symbol == 'double' ||
        jsonType.symbol == 'String' ||
        jsonType == TypeReferences.timestamp) {
      return TypeDefinition(
        type: TypeReference(
          (b) => b
            ..symbol = 'ComparableFilterField'
            ..types.add(type.reference),
        ),
        namedArguments: {
          'toJson': ConverterGenerator.getToJsonEnsured(
            type: type,
            customConverter: customConverter,
          ),
        },
      );
    }

    if (jsonType.symbol == 'Map') {
      if (type is InterfaceType && TypeAnalyzer.isCustomClass(type)) {
        final map = Map.fromIterables(
          type.element3.typeParameters2,
          type.typeArguments,
        );
        final builders = computeNeededBuilders(type: type.element3.thisType);
        return TypeDefinition(
          type: TypeReference(
            (b) => b
              ..symbol = isRoot
                  ? '${type.element3.name3}FilterBuilderRoot'
                  : '${type.element3.name3}FilterBuilder'
              ..types.addAll(
                map.entries.expand(
                  (t) => [
                    t.value.reference,
                    if (builders.contains(t.key))
                      getBuilderDef(type: t.value).type,
                  ],
                ),
              ),
          ),
          namedArguments: {
            // 'toJson': ConverterGenerator.getToJsonEnsured(
            //   type: type,
            //   customConverter: customConverter,
            // ),
          },
        );
      }
      final valueJsonType = jsonType.types.last;
      return TypeDefinition(
        type: TypeReference(
          (b) => b
            ..symbol = 'MapFilterField'
            ..types.add(type.reference)
            // original type is Map<K, V>
            ..types.add(type.typeArguments.first.reference)
            ..types.add(type.typeArguments.last.reference)
            // json type is Map<String, V>
            ..types.add(valueJsonType),
        ),
        namedArguments: {
          'toJson': ConverterGenerator.getToJsonEnsured(
            type: type,
            customConverter: customConverter,
          ),
          'keyToJson': ConverterGenerator.getToJsonEnsured(
            type: TypeAnalyzer.getMapKeyType(type),
          ),
          'valueToJson': ConverterGenerator.getToJsonEnsured(
            type: TypeAnalyzer.getMapValueType(type),
          ),
        },
      );
    }

    if (jsonType.symbol == 'List') {
      final elementJsonType = jsonType.types.first;
      return TypeDefinition(
        type: TypeReference(
          (b) => b
            ..symbol = 'ArrayFilterField'
            ..types.add(type.reference)
            // original type is List<T>
            ..types.add(type.typeArguments.first.reference)
            // json type is List<T>
            ..types.add(elementJsonType),
        ),
        namedArguments: {
          'toJson': ConverterGenerator.getToJsonEnsured(
            type: type,
            customConverter: customConverter,
          ),
          'elementToJson': ConverterGenerator.getToJsonEnsured(
            type: type.typeArguments.first,
          ),
        },
      );
    }

    return TypeDefinition(
      type: TypeReference(
        (b) => b
          ..symbol = 'FilterField'
          ..types.add(type.reference)
          ..types.add(jsonType),
      ),
      namedArguments: {
        'toJson': ConverterGenerator.getToJsonEnsured(
          type: type,
          customConverter: customConverter,
        ),
      },
    );
  }

  static TypeReference getRootFilterBuilderType(InterfaceType type) {
    return TypeReference(
      (b) => b
        ..symbol = type.element.name + 'FilterBuilderRoot'
        ..types.addAll(type.typeArguments.map((t) => t.reference)),
    );
  }

  static Map<String, Expression> getConstructorBuildersParameters({
    required InterfaceType type,
  }) {
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element3.thisType);

    return Map.fromEntries(
      map.entries
          .where((entry) => builders.contains(entry.key))
          .map(
            (entry) => MapEntry(
              'builderFunc${entry.key.name3!.camelCase()}',
              Method(
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
                    type: entry.value,
                    field: refer('field'),
                  ).code,
              ).closure,
            ),
          ),
    );
  }

  static Expression getBuilderInstanceExpression({
    required DartType type,
    Expression? field,
    bool isRoot = false,
  }) {
    final typeDef = getBuilderDef(type: type, isRoot: isRoot);
    return typeDef.instance.newInstance([], {
      if (field != null) 'field': field,
      if (type is InterfaceType)
        ...getConstructorBuildersParameters(type: type),
      ...typeDef.namedArguments,
    });
  }
}
