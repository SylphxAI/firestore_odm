import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_odm_builder/src/generators/schema_generator.dart';

/// Generator for Firestore ODM using source_gen
class SchemaGenerator2 extends GeneratorForAnnotation<Schema> {
  const SchemaGenerator2();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        'Schema annotation can only be applied to top-level variables.',
        element: element,
      );
    }

    return _generateForSchema(element, buildStep.resolver);
  }

  String _generateForSchema(
    TopLevelVariableElement element,
    Resolver resolver,
  ) {
    // 1. Extract all @Collection annotations from this schema variable
    final collections = _extractCollectionAnnotations(element);

    print('Found ${collections.length} collections in schema');

    // 3. Generate schema code with all types
    return SchemaGenerator.generateSchemaCode(element, collections);
  }

  /// Extract @Collection annotations from a schema variable
  List<SchemaCollectionInfo> _extractCollectionAnnotations(
    TopLevelVariableElement element,
  ) {
    final collections = <SchemaCollectionInfo>[];

    for (final annotation in element.metadata.annotations) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue?.type?.element?.name == 'Collection') {
        // Extract path from @Collection("path")
        final path = annotationValue!.getField('path')!.toStringValue()!;

        // Extract model type from @Collection<ModelType>
        final collectionType = annotationValue.type!;
        if (collectionType is ParameterizedType &&
            collectionType.typeArguments.isNotEmpty) {
          final modelType = collectionType.typeArguments.first;
          final modelTypeName = modelType.getDisplayString();
          final isSubcollection = path.contains('*');

          if (modelType is! InterfaceType) {
            throw InvalidGenerationSourceError(
              'Model type must be an InterfaceType for @Collection annotation.',
              element: element,
            );
          }

          collections.add(
            SchemaCollectionInfo(
              modelTypeName: modelTypeName,
              path: path,
              isSubcollection: isSubcollection,
              schemaTypeName: element.name!.upperFirst(),
              modelType: modelType, // Store the actual DartType
            ),
          );
        }
      }
    }

    return collections;
  }
}
