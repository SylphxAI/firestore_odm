import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:firestore_odm_builder/src/generators/aggregate_generator.dart';
import 'package:firestore_odm_builder/src/generators/converter_generator.dart';
import 'package:firestore_odm_builder/src/generators/filter_generator.dart';
import 'package:firestore_odm_builder/src/generators/order_by_generator.dart';
import 'package:firestore_odm_builder/src/generators/pipeline_generator.dart';
import 'package:firestore_odm_builder/src/generators/update_generator.dart';
import 'package:source_gen/source_gen.dart';

class ModelBuilderGenerator extends GeneratorForAnnotation<FirestoreOdm> {
  const ModelBuilderGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    List<Spec> specs = [];

    if (element is! InterfaceElement) {
      throw InvalidGenerationSourceError(
        'Schema annotation can only be applied to classes.',
        element: element,
      );
    }

    specs.addAll(UpdateGenerator.generateClasses(type: element.thisType));

    specs.addAll(FilterGenerator.generateClasses(element.thisType));

    specs.addAll(OrderByGenerator.generateOrderByClasses(element.thisType));

    specs.addAll(AggregateGenerator.generateClasses(element.thisType));

    specs.addAll(PipelineGenerator.generate(type: element.thisType));

    specs.addAll(ConverterGenerator.generate(type: element.thisType));

    return Library(
      (b) => b..body.addAll(specs),
    ).accept(DartEmitter(useNullSafetySyntax: true)).toString();
  }
}
