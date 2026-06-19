import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:firestore_odm_builder/src/utils/type_definition.dart';
import '../utils/type_analyzer.dart';
import '../utils/model_analyzer.dart';

/// Generator for order by builders using code_builder
class OrderByGenerator {
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
        type: TypeReference(
          (b) => b..symbol = '\$${field.type.element3!.name3}',
        ),
        instance: refer(
          '_orderByBuilderFunc${field.type.element3!.name3!.camelCase()}',
        ),
        namedArguments: args,
      );
    }

    if (isUserType(field.type)) {
      // If the field is a user-defined type, we need to create a nested OrderByBuilder
      return TypeDefinition(
        type: TypeReference(
          (b) => b
            ..symbol = '${field.type.element3!.name3}OrderByBuilder'
            ..types.addAll(field.type.typeArguments.map((e) => e.reference)),
        ),
        namedArguments: args,
      );
    }

    // Check if the field is an enum type
    final type = field.type;
    if (type is InterfaceType && type.element is EnumElement) {
      // For enum types, use the first enum value as default (value doesn't matter, just for typing)
      final enumElement = type.element as EnumElement;
      final firstEnumValue = enumElement.fields
          .where((f) => f.isEnumConstant)
          .firstOrNull;

      if (firstEnumValue != null) {
        final enumDefaultValue = '${enumElement.name}.${firstEnumValue.name}';
        return TypeDefinition(
          type: TypeReference(
            (b) => b
              ..symbol = 'OrderByField'
              ..types.add(field.type.reference),
          ),
          namedArguments: {...args, 'defaultValue': refer(enumDefaultValue)},
        );
      }
    }

    return TypeDefinition(
      type: TypeReference(
        (b) => b
          ..symbol = 'OrderByField'
          ..types.add(field.type.reference),
      ),
      namedArguments: args,
    );
  }

  /// Generate OrderBy field selector nested getter
  static Field _generateOrderByField(FieldInfo field) {
    final typeDef = getTypeDefinition(field);
    return Field(
      (b) => b
        ..docs.add('/// Access nested ${field.parameterName} for ordering')
        ..name = field.parameterName
        ..modifier = FieldModifier.final$
        ..late = true
        ..type = typeDef.type
        ..assignment = typeDef.instance
            .newInstance([], typeDef.namedArguments)
            .code,
    );
  }

  static Map<TypeParameterElement2, InterfaceType> matchedBuilders({
    required InterfaceType type,
  }) {
    final builders = computeNeededBuilders(type: type);
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    return Map.fromEntries(
      map.entries
          .where((entry) => builders.contains(entry.key))
          .whereType<MapEntry<TypeParameterElement2, InterfaceType>>(),
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
              'orderByBuilderFunc${entry.key.name3!.camelCase()}',
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
                  ..body = getOrderByBuilderInstanceExpression(
                    type: entry.value,
                    context: refer('context'),
                    field: refer('field'),
                  ).code,
              ).closure,
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

  static Class generateOrderByClass(InterfaceType type) {
    final fields = getFields(type);
    final methods = <Field>[];
    final builders = computeNeededBuilders(type: type);
    for (final field in fields.values) {
      methods.add(_generateOrderByField(field));
    }

    final className = type.element.name;

    // Create extension
    return Class(
      (b) => b
        ..name = '${className}OrderByBuilder'
        ..types.addAll(
          type.element3.typeParameters2.expand(
            (t) => [
              t.reference,
              if (builders.contains(t))
                TypeReference(
                  (b) => b
                    ..symbol = '\$${t.name3}'
                    ..bound = refer('OrderByFieldNode'),
                ),
            ],
          ),
        )
        ..extend = TypeReference((b) => b..symbol = 'OrderByFieldNode')
        ..docs.add('/// Generated OrderByBuilder for `$type`')
        ..constructors.add(
          Constructor(
            (b) => b
              ..docs.add('/// Constructor for OrderByBuilder')
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
                      ..name =
                          'orderByBuilderFunc${typeParam.name3!.camelCase()}'
                      ..type = TypeReference(
                        (b) => b
                          ..symbol = 'OrderByBuilderFunc'
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
                  refer('_orderByBuilderFunc${typeParam.name3!.camelCase()}')
                      .assign(
                        refer(
                          'orderByBuilderFunc${typeParam.name3!.camelCase()}',
                        ),
                      )
                      .code,
              ]),
          ),
        )
        ..fields.addAll([
          for (final typeParam in builders)
            Field(
              (b) => b
                ..name = '_orderByBuilderFunc${typeParam.name3!.camelCase()}'
                ..modifier = FieldModifier.final$
                ..type = TypeReference(
                  (b) => b
                    ..symbol = 'OrderByBuilderFunc'
                    ..types.add(refer('\$${typeParam.name3}')),
                ),
            ),
          ...methods,
        ]),
    );
  }

  static List<Spec> generateOrderByClasses(InterfaceType type) {
    final specs = <Spec>[];

    // Generate OrderByFieldSelector class
    specs.add(generateOrderByClass(type));

    return specs;
  }

  static TypeReference getOrderByBuilderType({required DartType type}) {
    if (type is! InterfaceType || !TypeAnalyzer.isCustomClass(type)) {
      return TypeReference(
        (b) => b
          ..symbol = 'OrderByField'
          ..types.add(type.reference),
      );
    }
    final map = Map.fromIterables(
      type.element3.typeParameters2,
      type.typeArguments,
    );
    final builders = computeNeededBuilders(type: type.element3.thisType);
    return TypeReference(
      (b) => b
        ..symbol = '${type.element3.name3}OrderByBuilder'
        ..types.addAll(
          map.entries.expand(
            (t) => [
              t.value.reference,
              if (builders.contains(t.key))
                getOrderByBuilderType(type: t.value),
            ],
          ),
        ),
    );
  }

  static Expression getOrderByBuilderInstanceExpression({
    required DartType type,
    required Expression context,
    Expression? field,
  }) {
    if (type is! InterfaceType) {
      return TypeReference(
        (b) => b
          ..symbol = 'OrderByField'
          ..types.add(type.reference),
      ).newInstance([], {
        'context': context,
        if (field != null) 'field': field,
      });
    }
    return getOrderByBuilderType(type: type).newInstance([], {
      'context': context,
      if (field != null) 'field': field,
      ...getConstructorBuildersParameters(type: type),
    });
  }
}
