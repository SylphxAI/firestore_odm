/// Generator for `@FirestoreOdm` model classes: converters, patch builder,
/// filter/orderBy/aggregate selectors, and (for non-generic models) the
/// pipeline selector + `pipeline()` extension.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/converter_generator.dart';
import 'generators/patch_generator.dart';
import 'generators/selector_generator.dart';
import 'utils/model_analyzer.dart';
import 'utils/reference_utils.dart';

class ModelBuilderGenerator extends GeneratorForAnnotation<FirestoreOdm> {
  const ModelBuilderGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! InterfaceElement) {
      throw InvalidGenerationSourceError(
        '@FirestoreOdm can only be applied to classes.',
        element: element,
      );
    }
    final type = element.thisType;
    final isGeneric = element.typeParameters.isNotEmpty;

    final specs = <Spec>[
      ...generateConverters(type),
      generatePatchBuilder(type),
      generateSelector(type, SelectorKind.filter),
      generateSelector(type, SelectorKind.orderBy),
      generateSelector(type, SelectorKind.aggregate),
      if (!isGeneric) ...generatePipelineSurface(type),
    ];

    return Library(
      (b) => b..body.addAll(specs),
    ).accept(DartEmitter(useNullSafetySyntax: true)).toString();
  }

  /// Pipeline selector + `pipeline()` extension (experimental, Enterprise).
  List<Spec> generatePipelineSurface(InterfaceType type) {
    final modelName = type.element.name;
    final selector = generateSelector(type, SelectorKind.pipeline);

    final extension = Extension(
      (b) => b
        ..name = '${modelName}PipelineExtension'
        ..on = generic('FirestoreCollection', [
          refer('S'),
          type.reference,
          refer('${modelName}PatchBuilder'),
          refer('${modelName}FilterBuilder'),
          refer('${modelName}OrderByBuilder'),
          refer('${modelName}AggregateBuilder'),
        ])
        ..types.add(refer('S'))
        ..methods.add(
          Method(
            (m) => m
              ..name = 'pipeline'
              ..returns = generic('TypedPipeline', [
                type.reference,
                refer('${modelName}PipelineSelector'),
              ])
              ..body = refer('TypedPipeline').newInstance([], {
                '_pipeline': refer('ref')
                    .property('firestore')
                    .property('pipeline')
                    .call(const [])
                    .property('collection')
                    .call([refer('ref').property('path')]),
                '_fromJson': _fromJsonRef(type),
                '_documentIdField': _documentIdFieldLiteral(type),
                '_selector': Method(
                  (m) => m
                    ..requiredParameters.add(
                      Parameter((p) => p..name = 'context'),
                    )
                    ..body = refer(
                      '${modelName}PipelineSelector',
                    ).newInstance([], {'context': refer('context')}).code,
                ).closure,
              }).code,
          ),
        ),
    );

    return [selector, extension];
  }

  Expression _fromJsonRef(InterfaceType type) {
    if (hasOwnFromJson(type)) {
      return refer('${type.element.name}.fromJson');
    }
    return refer('${type.element.name}FromJson');
  }

  Expression _documentIdFieldLiteral(InterfaceType type) {
    final field = getDocumentIdFieldName(type);
    return field == null ? literalNull : literalString(field);
  }
}
