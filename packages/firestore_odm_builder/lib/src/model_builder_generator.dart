/// Generator for `@FirestoreOdm` model classes: converters, patch builder,
/// filter/orderBy/aggregate selectors, and (for non-generic models) the
/// pipeline selector + `pipeline()` extension.
library;

import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/converter_generator.dart';
import 'generators/patch_generator.dart';
import 'generators/selector_generator.dart';
import 'utils/model_analyzer.dart';
import 'utils/reference_utils.dart';

class ModelBuilderGenerator extends Generator {
  const ModelBuilderGenerator();

  /// A plain [Generator] (not `GeneratorForAnnotation`) for the same reason
  /// as [SchemaGenerator2]: libraries that also carry `@Schema` variables
  /// whose types are only resolvable after codegen would make source_gen's
  /// annotation resolution throw.
  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    final classes = library.element.classes.where(
      (c) => c.metadata.annotations.any(
        (m) => m.computeConstantValue()?.type?.element?.name == 'FirestoreOdm',
      ),
    );
    if (classes.isEmpty) return null;

    final specs = <Spec>[];
    for (final cls in classes) {
      final type = cls.thisType;
      final isGeneric = cls.typeParameters.isNotEmpty;
      specs.addAll([
        ...generateConverters(type),
        generatePatchBuilder(type),
        generateSelector(type, SelectorKind.filter),
        generateSelector(type, SelectorKind.orderBy),
        generateSelector(type, SelectorKind.aggregate),
        if (!isGeneric) ...generatePipelineSurface(type),
      ]);
    }

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
        ..types.add(
          TypeReference(
            (b) => b
              ..symbol = 'S'
              ..bound = refer('FirestoreSchema'),
          ),
        )
        ..methods.add(
          Method(
            (m) => m
              ..name = 'pipeline'
              ..returns = generic('TypedPipeline', [
                type.reference,
                refer('${modelName}PipelineSelector'),
              ])
              ..body = refer('TypedPipeline').newInstance([
                refer('ref')
                    .property('firestore')
                    .property('pipeline')
                    .call(const [])
                    .property('collection')
                    .call([refer('ref').property('path')]),
                _fromJsonRef(type),
                _documentIdFieldLiteral(type),
                Method(
                  (m) => m
                    ..requiredParameters.add(
                      Parameter((p) => p..name = 'context'),
                    )
                    ..body = refer(
                      '${modelName}PipelineSelector',
                    ).newInstance([], {'context': refer('context')}).code,
                ).closure,
              ]).code,
          ),
        ),
    );

    return [selector, extension];
  }

  Expression _fromJsonRef(InterfaceType type) =>
      refer('${type.element.name}FromJson');

  Expression _documentIdFieldLiteral(InterfaceType type) {
    final field = getDocumentIdFieldName(type);
    return field == null ? literalNull : literalString(field);
  }
}
