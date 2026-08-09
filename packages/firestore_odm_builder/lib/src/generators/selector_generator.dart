/// Generates the four per-model selector trees (filter / orderBy / aggregate
/// / pipeline) from one parameterized code path.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';

import '../utils/model_analyzer.dart';
import '../utils/reference_utils.dart';
import '../utils/type_analyzer.dart';
import 'converter_generator.dart';

enum SelectorKind { filter, orderBy, aggregate, pipeline }

/// Generates `<Model><Kind>Builder` (or `PipelineSelector`) for [type].
Class generateSelector(InterfaceType type, SelectorKind kind) {
  final modelName = type.element.name!;
  final typeParams = type.element.typeParameters;
  final isPipeline = kind == SelectorKind.pipeline;

  final className = isPipeline
      ? '${modelName}PipelineSelector'
      : '${modelName}${_kindSuffix(kind)}';

  final fields = <Field>[];
  for (final field in getFields(type).values) {
    // Aggregate selectors are only meaningful for numeric fields (or nested
    // models that may contain them).
    if (kind == SelectorKind.aggregate &&
        !TypeAnalyzer.isNumeric(field.type) &&
        !(isUserType(field.type) && !TypeAnalyzer.isEnum(field.type))) {
      continue;
    }
    fields.add(_generateField(type, kind, field));
  }
  // documentId pseudo-field for filters and orderBy.
  if (kind == SelectorKind.filter || kind == SelectorKind.orderBy) {
    fields.add(
      Field(
        (b) => b
          ..docs.add('/// The document ID pseudo-field.')
          ..name = 'documentId'
          ..modifier = FieldModifier.final$
          ..late = true
          ..type = _leafType(kind, TypeReferences.string)
          ..assignment = _leafInstance(
            kind,
            modelName,
            fieldName: 'documentId',
            isDocumentId: true,
            dartType: stringType(type),
          ).code,
      ),
    );
  }

  // Context field for orderBy/aggregate builders.
  final contextField = switch (kind) {
    SelectorKind.orderBy || SelectorKind.aggregate => Field(
      (b) => b
        ..name = '_context'
        ..modifier = FieldModifier.final$
        ..type = refer(_contextType(kind)),
    ),
    _ => null,
  };

  return Class(
    (b) => b
      ..name = className
      ..types.addAll(typeParams.map((t) => t.reference))
      ..extend = refer(_superName(kind))
      ..constructors.add(_constructor(kind, typeParams))
      ..fields.addAll([if (contextField != null) contextField, ...fields]),
  );
}

String _kindSuffix(SelectorKind kind) => switch (kind) {
  SelectorKind.filter => 'FilterBuilder',
  SelectorKind.orderBy => 'OrderByBuilder',
  SelectorKind.aggregate => 'AggregateBuilder',
  SelectorKind.pipeline => '',
};

String _superName(SelectorKind kind) => switch (kind) {
  SelectorKind.filter => 'FilterBuilderRoot',
  SelectorKind.orderBy => 'OrderByBuilderRoot',
  SelectorKind.aggregate => 'AggregateBuilderRoot',
  SelectorKind.pipeline => 'PipelineFieldNode',
};

String _contextType(SelectorKind kind) => switch (kind) {
  SelectorKind.orderBy => 'OrderByContext',
  SelectorKind.aggregate => 'AggregateContext',
  _ => '',
};

Constructor _constructor(
  SelectorKind kind,
  List<TypeParameterElement> typeParams,
) {
  final optional = <Parameter>[];
  if (kind == SelectorKind.filter) {
    optional.add(
      Parameter(
        (p) => p
          ..name = 'field'
          ..toSuper = true
          ..named = true,
      ),
    );
  } else if (kind == SelectorKind.orderBy || kind == SelectorKind.aggregate) {
    optional.add(
      Parameter(
        (p) => p
          ..name = 'field'
          ..toSuper = true
          ..named = true,
      ),
    );
    optional.add(
      Parameter(
        (p) => p
          ..name = 'context'
          ..type = refer(_contextType(kind))
          ..named = true
          ..required = true,
      ),
    );
  } else {
    optional.add(
      Parameter(
        (p) => p
          ..name = 'components'
          ..toSuper = true
          ..named = true,
      ),
    );
    optional.add(
      Parameter(
        (p) => p
          ..name = 'context'
          ..toSuper = true
          ..named = true,
      ),
    );
  }
  return Constructor(
    (b) => b
      ..constant = typeParams.isEmpty
      ..optionalParameters.addAll(optional)
      ..initializers.addAll(
        kind == SelectorKind.orderBy || kind == SelectorKind.aggregate
            ? [refer('_context').assign(refer('context')).code]
            : const [],
      ),
  );
}

TypeReference _leafType(SelectorKind kind, Reference dartType) =>
    switch (kind) {
      SelectorKind.filter => generic('FilterField', [dartType]),
      SelectorKind.orderBy => generic('OrderByField', [dartType]),
      SelectorKind.aggregate => generic('AggregateField', [dartType]),
      SelectorKind.pipeline => generic('PipelineField', [dartType]),
    };

/// A String DartType for the documentId pseudo-field.
DartType stringType(InterfaceType model) =>
    model.element.library.typeProvider.stringType;

Expression _leafInstance(
  SelectorKind kind,
  String modelName, {
  required String fieldName,
  required DartType dartType,
  bool isDocumentId = false,
  CustomConverter? customConverter,
}) {
  final pathExpr = isDocumentId
      ? refer('DocumentIdNode').constInstance([])
      : refer('append').call([literalString(fieldName)]);
  return switch (kind) {
    SelectorKind.filter => refer('FilterField').newInstance([], {
      'field': pathExpr,
      'toJson': _fieldToJson(modelName, dartType, customConverter),
    }),
    SelectorKind.orderBy => refer('OrderByField').newInstance([], {
      'field': pathExpr,
      'context': refer('_context'),
      if (TypeAnalyzer.isEnum(dartType))
        'defaultValue': refer('${dartType.element!.name!}.values.first'),
    }),
    SelectorKind.aggregate => refer(
      'AggregateField',
    ).newInstance([], {'field': pathExpr, 'context': refer('_context')}),
    SelectorKind.pipeline => refer('PipelineField').newInstance([], {
      'components': isDocumentId
          ? refer('const []')
          : CodeExpression(
              Code('[...components, ${literalString(fieldName)}]'),
            ),
      'context': refer('\$ctx'),
      if (!isDocumentId)
        'toJson': _fieldToJson(modelName, dartType, customConverter),
    }),
  };
}

Expression _fieldToJson(
  String modelName,
  DartType dartType,
  CustomConverter? customConverter,
) {
  return Method(
    (m) => m
      ..requiredParameters.add(Parameter((p) => p..name = 'value'))
      ..body = toJsonValue(
        dartType,
        refer('value'),
        customConverter: customConverter,
        modelName: modelName,
      ).code,
  ).closure;
}

Field _generateField(InterfaceType model, SelectorKind kind, FieldInfo field) {
  final dartType = field.type;
  final isNested =
      isUserType(dartType) &&
      !TypeAnalyzer.isEnum(dartType) &&
      dartType is InterfaceType;

  // Nested model: reference the nested model's selector class.
  if (isNested) {
    final nestedName = '${dartType.element.name!}${_kindSuffix(kind)}';
    final nestedType = generic(
      nestedName,
      dartType.typeArguments.map((t) => t.reference).toList(),
    );
    final args = <String, Expression>{
      if (kind == SelectorKind.filter)
        'field': refer('append').call([literalString(field.jsonName)]),
      if (kind == SelectorKind.orderBy || kind == SelectorKind.aggregate) ...{
        'field': refer('append').call([literalString(field.jsonName)]),
        'context': refer('_context'),
      },
      if (kind == SelectorKind.pipeline) ...{
        'components': CodeExpression(
          Code('[...components, ${literalString(field.jsonName)}]'),
        ),
        'context': refer('\$ctx'),
      },
    };
    return Field(
      (b) => b
        ..docs.add('/// Nested selector for `${field.parameterName}`.')
        ..name = field.parameterName
        ..modifier = FieldModifier.final$
        ..late = true
        ..type = nestedType
        ..assignment = refer(nestedName).newInstance([], args).code,
    );
  }

  return Field(
    (b) => b
      ..docs.add('/// Selector for `${field.parameterName}`.')
      ..name = field.parameterName
      ..modifier = FieldModifier.final$
      ..late = true
      ..type = _leafType(kind, dartType.reference)
      ..assignment = _leafInstance(
        kind,
        model.element.name!,
        fieldName: field.jsonName,
        dartType: dartType,
        customConverter: field.customConverter,
      ).code,
  );
}

/// Type references for common built-ins.
abstract final class TypeReferences {
  static final string = TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core',
  );
}
