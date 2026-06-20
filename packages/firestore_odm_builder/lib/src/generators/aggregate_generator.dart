import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:firestore_odm_builder/src/utils/type_definition.dart';
import 'package:source_gen/source_gen.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for aggregate field selectors using code_builder
class AggregateGenerator {
  static TypeDefinition getTypeDefinition(FieldInfo field) {
    final args = {
      'field': field.isDocumentId
          ? refer('FieldPath.documentId')
          : refer(
              'path',
            ).property('append').call([literalString(field.jsonName)]),
      'context': refer('\$context'),
    };
    if (field.type is TypeParameterType) {
      return TypeDefinition(
        type: TypeReference((b) => b..symbol = '\$${field.type.element!.name}'),
        instance: refer('_builderFunc${field.type.element!.name!.camelCase()}'),
        namedArguments: args,
      );
    }

    if (isUserType(field.type)) {
      return TypeDefinition(
        type: TypeReference(
          (b) => b
            ..symbol = '${field.type.element!.name}AggregateFieldSelector'
            ..types.addAll(field.type.typeArguments.map((e) => e.reference)),
        ),
        namedArguments: args,
      );
    }

    return TypeDefinition(
      type: TypeReference(
        (b) => b
          ..symbol = 'AggregateField'
          ..types.add(field.type.reference),
      ),
      namedArguments: args,
    );
  }

  /// Generate numeric field accessor method for aggregation
  static Field _generateNumericFieldAccessor(FieldInfo field) {
    final typeDef = getTypeDefinition(field);
    return Field(
      (b) => b
        ..docs.add('/// ${field.parameterName} field for aggregation')
        ..name = field.parameterName
        ..modifier = FieldModifier.final$
        ..late = true
        ..type = typeDef.type
        ..assignment = typeDef.instance
            .newInstance([], typeDef.namedArguments)
            .code,
    );
  }

  static List<Spec> generateClasses(InterfaceType type) {
    final specs = <Spec>[];

    // Generate OrderByFieldSelector class
    specs.add(generateAggregateClass(type));

    specs.add(generateAggregateRootClass(type));

    return specs;
  }

  static Set<TypeParameterElement> computeNeededBuilders({
    required InterfaceType type,
  }) {
    final map = Map.fromIterables(
      type.typeArguments,
      type.element.typeParameters,
    );
    final fields = getFields(type);
    final fieldTypes = fields.values.map((field) => field.type).toSet();
    return fieldTypes.map((fieldType) => map[fieldType]).nonNulls.toSet();
  }

  static Class generateAggregateRootClass(InterfaceType type) {
    final className = type.element.name;
    final builders = computeNeededBuilders(type: type.element.thisType);
    return Class(
      (b) => b
        ..name = '${className}AggregateBuilderRoot'
        ..types.addAll(
          type.element.typeParameters.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name}'
                    ..bound = refer('AggregateFieldNode'),
                ),
            ],
          ),
        )
        ..extend = TypeReference(
          (b) => b
            ..symbol = '${className}AggregateFieldSelector'
            ..types.addAll(
              type.element.typeParameters.expand(
                (t) => [
                  t.reference,
                  if (builders.contains(t))
                    TypeReference((b) => b..symbol = '\$${t.name}'),
                ],
              ),
            ),
        )
        ..docs.add('/// Generated AggregateFieldSelector for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Constructor for AggregateFieldSelector')
              ..optionalParameters.addAll([
                Parameter(
                  (b) => b
                    ..name = 'context'
                    ..toSuper = true
                    ..required = true
                    ..named = true,
                ),
                for (final typeParam in computeNeededBuilders(
                  type: type.element.thisType,
                ))
                  Parameter(
                    (b) => b
                      ..name = 'builderFunc${typeParam.name!.camelCase()}'
                      ..toSuper = true
                      ..named = true
                      ..required = true,
                  ),
                Parameter(
                  (b) => b
                    ..name = 'field'
                    ..toSuper = true,
                ),
              ]),
          ),
        )
        ..mixins.add(refer('AggregateRootMixin'))
        ..implements.add(refer('AggregateBuilderRoot')),
    );
  }

  static Class generateAggregateClass(InterfaceType type) {
    final className = type.element.name;

    final builders = computeNeededBuilders(type: type);

    // Generate methods for all aggregatable fields
    final fields = <Field>[];
    for (final field in getFields(type).values) {
      if (field.isDocumentId) continue;

      final fieldType = field.type;

      if (TypeAnalyzer.isNumericType(fieldType) || isUserType(fieldType)) {
        fields.add(_generateNumericFieldAccessor(field));
      }
    }

    return Class(
      (b) => b
        ..name = '${className}AggregateFieldSelector'
        ..types.addAll(
          type.element.typeParameters.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name}'
                    ..bound = refer('AggregateFieldNode'),
                ),
            ],
          ),
        )
        ..extend = refer('AggregateFieldNode')
        ..docs.add('/// Generated AggregateFieldSelector for `$type`')
        ..constructors.addAll([
          Constructor(
            (b) => b
              ..docs.add('/// Constructor for AggregateFieldSelector')
              ..optionalParameters.addAll([
                Parameter(
                  (b) => b
                    ..name = 'context'
                    ..toSuper = true
                    ..required = true
                    ..named = true,
                ),
                for (final typeParam in builders)
                  Parameter(
                    (b) => b
                      ..name = 'builderFunc${typeParam.name!.camelCase()}'
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'AggregateBuilderFunc'
                          ..types.add(refer('\$${typeParam.name}')),
                      )
                      ..named = true
                      ..required = true,
                  ),
                Parameter(
                  (b) => b
                    ..name = 'field'
                    ..toSuper = true,
                ),
              ])
              ..initializers.addAll([
                for (final typeParam in builders)
                  refer('_builderFunc${typeParam.name!.camelCase()}')
                      .assign(
                        refer('builderFunc${typeParam.name!.camelCase()}'),
                      )
                      .code,
              ]),
          ),
        ])
        ..fields.addAll([
          for (final typeParam in builders)
            Field(
              (b) => b
                ..name = '_builderFunc${typeParam.name!.camelCase()}'
                ..modifier = FieldModifier.final$
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'AggregateBuilderFunc'
                    ..types.add(refer('\$${typeParam.name}')),
                ),
            ),
        ])
        ..fields.addAll(fields),
    );
  }

  static TypeReference getBuilderType({
    required DartType type,
    bool isRoot = false,
  }) {
    if (type is! InterfaceType || !TypeAnalyzer.isCustomClass(type)) {
      if (!TypeChecker.typeNamed(num).isAssignableFromType(type)) {
        return TypeReference((b) => b..symbol = 'Never');
      }
      return TypeReference(
        (b) => b
          ..symbol = 'AggregateField'
          ..types.add(type.reference),
      );
    }
    final map = Map.fromIterables(
      type.element.typeParameters,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element.thisType);
    return TypeReference(
      (b) => b
        ..symbol = isRoot
            ? '${type.element.name}AggregateBuilderRoot'
            : '${type.element.name}AggregateFieldSelector'
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
  }) {
    final map = Map.fromIterables(
      type.element.typeParameters,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element.thisType);

    return Map.fromEntries(
      map.entries
          .where((entry) => builders.contains(entry.key))
          .map(
            (entry) => MapEntry(
              'builderFunc${entry.key.name!.camelCase()}',
              Method(
                (b) => b
                  ..lambda = true
                  ..optionalParameters.addAll([
                    Parameter(
                      (b) => b
                        ..name = 'context'
                        ..required = true
                        ..named = true,
                    ),
                    Parameter(
                      (b) => b
                        ..name = 'field'
                        ..required = true
                        ..named = true,
                    ),
                  ])
                  ..body = getBuilderInstanceExpression(
                    type: entry.value,
                    context: refer('context'),
                    field: refer('field'),
                  ).code,
              ).closure,
            ),
          ),
    );
  }

  static Expression getBuilderInstanceExpression({
    required DartType type,
    required Expression context,
    Expression? field,
    bool isRoot = false,
  }) {
    if (!isUserType(type) &&
        !TypeChecker.typeNamed(num).isAssignableFromType(type)) {
      return refer(
        'throw UnsupportedError',
      ).call([literalString('Unsupported type for aggregation')]);
    }
    return getBuilderType(type: type, isRoot: isRoot).newInstance([], {
      'context': context,
      if (field != null) 'field': field,
      if (type is InterfaceType)
        ...getConstructorBuildersParameters(type: type),
    });
  }
}
