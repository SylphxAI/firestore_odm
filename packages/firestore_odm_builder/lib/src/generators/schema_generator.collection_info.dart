part of 'schema_generator.dart';

/// Information about a collection annotation extracted from a schema variable
class SchemaCollectionInfo {
  final String path;
  final String modelTypeName;
  final bool isSubcollection;
  final String schemaTypeName;
  final InterfaceType modelType;

  const SchemaCollectionInfo({
    required this.path,
    required this.modelTypeName,
    required this.isSubcollection,
    required this.schemaTypeName,
    required this.modelType,
  });
}
