/// Generates the per-model `PatchBuilder` with typed field-update handles.
///
/// Field handles map 1:1 to the six patch operations: set/delete
/// on every field; increment on numerics; serverTimestamp on DateTime;
/// arrayUnion/arrayRemove on lists.
library;

import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';

import '../utils/model_analyzer.dart';
import '../utils/reference_utils.dart';
import '../utils/type_analyzer.dart';
import 'converter_generator.dart';

Expression _body(Expression expr) {
  final emitter = DartEmitter(useNullSafetySyntax: true);
  return CodeExpression(Code('return ${expr.accept(emitter)};'));
}

/// Generates `<Model>PatchBuilder` for [type].
Class generatePatchBuilder(InterfaceType type) {
  final modelName = type.element.name;
  final typeParams = type.element.typeParameters;

  final fields = <Field>[];
  for (final field in getFields(type).values) {
    if (field.isDocumentId) continue;
    fields.add(_generateField(type, field));
  }

  // A non-generic model can be patched as a nested field: `$.profile.set(p)`
  // replaces it and `$.profile.delete()` removes it.
  final methods = typeParams.isNotEmpty
      ? const <Method>[]
      : [
          Method(
            (m) => m
              ..docs.add('/// Replaces the whole `$modelName` at [field].')
              ..name = 'set'
              ..returns = refer('SetOperation')
              ..requiredParameters.add(
                Parameter(
                  (p) => p
                    ..name = 'value'
                    ..type = type.element.thisType.reference,
                ),
              )
              ..lambda = true
              ..body = refer('SetOperation').newInstance([
                refer('field'),
                toJsonValue(
                  type.element.thisType,
                  refer('value'),
                  modelName: modelName,
                ),
              ]).code,
          ),
          Method(
            (m) => m
              ..docs.add('/// Deletes the field at [field].')
              ..name = 'delete'
              ..returns = refer('DeleteOperation')
              ..lambda = true
              ..body = refer(
                'DeleteOperation',
              ).newInstance([refer('field')]).code,
          ),
        ];

  final builder = Class(
    (b) => b
      ..name = '${modelName}PatchBuilder'
      ..types.addAll(typeParams.map((t) => t.reference))
      ..extend = generic('PatchBuilder', [type.element.thisType.reference])
      ..constructors.add(
        Constructor(
          (b) => b
            ..docs.add('/// Creates a patch builder for `$modelName`.')
            ..optionalParameters.add(
              Parameter(
                (p) => p
                  ..name = 'field'
                  ..toSuper = true
                  ..named = true,
              ),
            ),
        ),
      )
      ..methods.addAll(methods)
      ..fields.addAll(fields),
  );

  return builder;
}

Field _generateField(InterfaceType model, FieldInfo field) {
  final type = field.type;
  final name = field.parameterName;
  final jsonName = field.jsonName;
  Expression fieldNode = refer('field');
  for (final c in jsonName.split('.')) {
    fieldNode = fieldNode.property('append').call([literalString(c)]);
  }

  // A nested non-generic model gets its own builder at this path.
  if (isUserType(type) &&
      !TypeAnalyzer.isEnum(type) &&
      type is InterfaceType &&
      type.typeArguments.isEmpty &&
      field.customConverter == null) {
    final nestedBuilder = '${type.element.name}PatchBuilder';
    return Field(
      (b) => b
        ..docs.add(
          '/// Patch handles for `$name` (document field `$jsonName`).',
        )
        ..name = name
        ..modifier = FieldModifier.final$
        ..late = true
        ..type = refer(nestedBuilder)
        ..assignment = refer(
          nestedBuilder,
        ).newInstance([], {'field': fieldNode}).code,
    );
  }

  final Expression toJson = toJsonValue(
    type,
    refer('value'),
    customConverter: field.customConverter,
    modelName: model.element.name,
  );

  final String updateType;
  TypeReference? listElementType;
  final Map<String, Expression> args = {
    'field': fieldNode,
    'toJson': Method(
      (m) => m
        ..requiredParameters.add(Parameter((p) => p..name = 'value'))
        ..body = _body(toJson).code,
    ).closure,
  };

  final needsElementConverter =
      TypeAnalyzer.isIterable(type) &&
      !TypeAnalyzer.isMap(type) &&
      !type.isNullable;

  if (TypeAnalyzer.isDateTime(type) && !_isTimestamp(type)) {
    updateType = 'DateTimeFieldUpdate';
  } else if (TypeAnalyzer.isNumeric(type) && !type.isNullable) {
    updateType = 'NumericFieldUpdate';
  } else if (needsElementConverter) {
    updateType = 'ListFieldUpdate';
    final elementType = TypeAnalyzer.iterableElementType(type);
    args['elementToJson'] = Method(
      (m) => m
        ..requiredParameters.add(Parameter((p) => p..name = 'value'))
        ..body = _body(
          toJsonValue(
            elementType,
            refer('value'),
            modelName: model.element.name,
          ),
        ).code,
    ).closure;
    listElementType = elementType.reference;
  } else {
    updateType = 'FieldUpdate';
  }

  return Field(
    (b) => b
      ..docs.add('/// Patch handle for `$name` (document field `$jsonName`).')
      ..name = name
      ..modifier = FieldModifier.final$
      ..late = true
      ..type = switch (updateType) {
        'DateTimeFieldUpdate' => refer(updateType),
        'ListFieldUpdate' => generic(updateType, [listElementType!]),
        _ => generic(updateType, [type.reference]),
      }
      ..assignment = refer(updateType).newInstance([], args).code,
  );
}

bool _isTimestamp(DartType type) => type.element?.name == 'Timestamp';
