import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' hide FunctionType, RecordType;
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:firestore_odm_builder/src/generators/aggregate_generator.dart';
import 'package:firestore_odm_builder/src/generators/converter_generator.dart';
import 'package:firestore_odm_builder/src/generators/filter_generator.dart';
import 'package:firestore_odm_builder/src/generators/order_by_generator.dart';
import 'package:firestore_odm_builder/src/generators/update_generator.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import 'package:firestore_odm_builder/src/utils/string_utils.dart';
import 'package:source_gen/source_gen.dart';

import '../utils/model_analyzer.dart';

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

final preferInlineAnnotation = refer(
  'pragma',
).call([literalString('vm:prefer-inline')]);
final overrideAnnotation = refer('override');

enum ClassType {
  root('Root'),
  collection('Collection'),
  document('Document'),
  transactionContext('TransactionContext'),
  transactionCollection('TransactionCollection'),
  transactionDocument('TransactionDocument'),
  batchContext('BatchContext'),
  batchCollection('BatchCollection'),
  batchDocument('BatchDocument'),
  patchBuilder('PatchBuilder');

  const ClassType(this.suffix);

  final String suffix;
}

/// Generator for schema-based ODM code using code_builder
class SchemaGenerator {
  /// Generate schema class and extensions from annotated variable (with converters)
  static String generateSchemaCode(
    TopLevelVariableElement variableElement,
    List<SchemaCollectionInfo> collections,
  ) {
    // Create fresh instances for this schema to avoid cache pollution
    validate(collections: collections);

    final library = Library(
      (b) => b.body.addAll(
        generateAllLibraryMembers(
          variableElement: variableElement,
          collections: collections,
        ),
      ),
    );

    final emitter = DartEmitter(useNullSafetySyntax: true);
    return library.accept(emitter).toString();
  }

  /// Extract the assigned value from a variable element (e.g., "_$TestSchema" from "final testSchema = _$TestSchema;")
  static String _extractAssignedValue(TopLevelVariableElement variableElement) {
    try {
      // Try to get the source location and extract the assigned value.
      // analyzer's new element model exposes source via the library fragment.
      final source = variableElement.library.firstFragment.source;
      final name = variableElement.name;
      if (name != null) {
        final contents = source.contents.data;

        // Find the variable declaration line
        final lines = contents.split('\n');
        for (final line in lines) {
          if (line.contains('$name =') && line.contains('_\$')) {
            // Extract the assigned value (everything after '=' and before ';')
            final equalIndex = line.indexOf('$name =');
            if (equalIndex != -1) {
              final afterEqual = line
                  .substring(equalIndex + '$name ='.length)
                  .trim();
              final assignedValue = afterEqual
                  .replaceAll(RegExp(r';.*$'), '')
                  .trim();

              // Validate that it looks like a proper assigned value
              if (assignedValue.isNotEmpty && assignedValue.startsWith('_\$')) {
                return assignedValue;
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors and fall back to convention
    }

    // Fallback: generate from variable name following the convention
    return '_\$${variableElement.name!.upperFirst()}';
  }

  /// Generate document class name from collection path
  /// e.g., "users" -> "UsersDocument", "users2" -> "Users2Document"
  /// e.g., "users/*/posts" -> "UsersCollectionPostsDocument"
  /// e.g., "users/*/posts/*/comments" -> "UsersCollectionPostsCollectionCommentsDocument"
  static String generateClassName({
    required String schemaClassName,
    required ClassType type,
    String collectionPath = '',
    bool private = false,
  }) {
    return (private ? '_' : '') +
        '\$' +
        schemaClassName.upperFirst() +
        _getSegments(collectionPath).join('') +
        type.suffix.upperFirst();
  }

  static List<String> _getSegments(String collectionPath) {
    // Split path and filter out wildcards
    final segments = collectionPath
        .split('/')
        .where((segment) => segment != '*')
        .toList();

    // Convert each segment to PascalCase and join with underscore
    final capitalizedSegments = segments
        .map((segment) => segment.upperFirst())
        .toList();

    return capitalizedSegments;
  }

  static RecordType _getPathRecord(String path) {
    final segments = _getSegments(path);
    return RecordType(
      (b) => b
        ..positionalFieldTypes.addAll(
          segments.map(
            (segment) => TypeReference(
              (b) => b..symbol = '_\$${segment.upperFirst()}Collection',
            ),
          ),
        ),
    );
  }

  /// Get parent collection path from subcollection path
  /// e.g., "users/*/posts" -> "users"
  /// e.g., "posts/*/comments" -> "posts"
  /// e.g., "users/*/posts/*/comments" -> "users/*/posts"
  static String? _getParentCollectionPath(String subcollectionPath) {
    final segments = subcollectionPath.split('/');
    if (segments.length >= 3) {
      // Return all segments except the last one (which is the subcollection name)
      final parentSegments = segments.take(segments.length - 2).toList();
      if (parentSegments.isNotEmpty) {
        return parentSegments.join('/');
      }
    }
    return null;
  }

  /// Get subcollection name from full path (last segment)
  static String _getCollectionName(String path) {
    return path.split('/').last;
  }

  static void validate({required List<SchemaCollectionInfo> collections}) {
    // Ensure all collections have unique paths
    final uniquePaths = <String>{};
    for (final collection in collections) {
      if (!uniquePaths.add(collection.path)) {
        throw ArgumentError(
          'Duplicate collection path found: ${collection.path}',
        );
      }
    }

    // Ensure no subcollection has the same path as a root collection
    final rootPaths = collections
        .where((c) => !c.isSubcollection)
        .map((c) => c.path)
        .toSet();
    for (final collection in collections.where((c) => c.isSubcollection)) {
      if (rootPaths.contains(collection.path)) {
        throw ArgumentError(
          'Subcollection path "${collection.path}" conflicts with root collection',
        );
      }
    }
    const odmTypeChecker = TypeChecker.typeNamed(FirestoreOdm);
    final missingAnnotations = collections
        .expand((c) => scan(c.modelType))
        .where(isUserType)
        .whereType<InterfaceType>()
        .map((t) => t.element.thisType)
        .where((t) => !odmTypeChecker.hasAnnotationOf(t.element));
    if (missingAnnotations.isNotEmpty) {
      throw ArgumentError(
        'The following model types are missing @FirestoreOdm annotation: '
        '${missingAnnotations.map((t) => t.element.name).join(', ')}',
      );
    }
  }

  /// Generate all library members
  static List<Spec> generateAllLibraryMembers({
    required TopLevelVariableElement variableElement,
    required List<SchemaCollectionInfo> collections,
    required,
  }) {
    final specs = <Spec>[];

    specs.addAll(generateCollectionIdentifiers(collections));

    // Use variable name for clean class name (e.g., "schema" -> "Schema", "helloSchema" -> "HelloSchema")
    final variableName = variableElement.name!;
    final schemaClassName = variableName.upperFirst();

    // Extract the assigned value (e.g., "_$TestSchema") for the const name
    final assignedValue = _extractAssignedValue(variableElement);
    final schemaConstName = assignedValue;

    // Generate the schema class and constant
    specs.addAll(
      generateSchemaClassAndConstant(schemaClassName, schemaConstName),
    );

    // specs.addAll(
    //   generateFilterAndOrderBySelectors(
    //     collections,
    //     schemaClassName,
    //     converterFactory: converterFactory,
    //
    //   ),
    // );
    // Generate filter and order by builders for each model type

    // Generate ODM extensions
    specs.add(generateODMExtensions(schemaClassName, collections));

    // Generate transaction context extensions
    specs.add(generateTransactionContext(schemaClassName, collections));
    specs.addAll(generateTransactionDocuments(schemaClassName, collections));

    // Generate batch context extensions

    // Generate unique document classes for each collection path
    specs.addAll(generateUniqueDocumentClasses(schemaClassName, collections));

    // Generate document extensions for subcollections (path-specific)
    // specs.addAll(generateDocumentExtensions(schemaClassName, collections));

    // Generate batch document extensions for subcollections
    final batchExtension = generateBatchContextExtensions(
      schemaClassName,
      collections,
    );
    if (batchExtension != null) specs.add(batchExtension);
    specs.addAll(generateBatchDocumentExtensions(schemaClassName, collections));

    // specs.addAll(converterFactory.specs);

    return specs;
  }

  /// Generate the schema class and constant instance
  static List<Spec> generateSchemaClassAndConstant(
    String schemaClassName,
    String originalVariableName,
  ) {
    final specs = <Spec>[];

    // Generate the schema class
    final schemaClass = Class(
      (b) => b
        ..docs.add(
          '/// Generated schema class - dummy class that only serves as type marker',
        )
        ..name = schemaClassName
        ..extend = refer('FirestoreSchema')
        ..constructors.add(Constructor((b) => b..constant = true)),
    );
    specs.add(schemaClass);

    // Generate the const instance
    final constInstance = Field(
      (b) => b
        ..docs.add('/// Generated schema instance')
        ..modifier = FieldModifier.constant
        ..name = originalVariableName
        ..type = refer(schemaClassName)
        ..assignment = refer(schemaClassName).newInstance([]).code,
    );
    specs.add(constInstance);

    return specs;
  }

  /// Generate ODM extensions for the schema
  static Extension generateODMExtensions(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final collectionName = _getCollectionName(collection.path);
      final collectionType = TypeReference(
        (b) => b
          ..symbol = 'FirestoreCollection'
          ..types.addAll([
            refer(schemaClassName),
            refer(collection.modelTypeName),
            _getPathRecord(collection.path),
            UpdateGenerator.getBuilderType(type: collection.modelType),
            FilterGenerator.getBuilderType(
              type: collection.modelType,

              isRoot: true,
            ),
            OrderByGenerator.getOrderByBuilderType(type: collection.modelType),
            AggregateGenerator.getBuilderType(
              type: collection.modelType,

              isRoot: true,
            ),
          ]),
      );
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..name = collectionName.camelCase().lowerFirst()
            ..returns = collectionType
            ..type = MethodType.getter
            ..annotations.add(preferInlineAnnotation)
            ..body = collectionType
                // to simplify the type arguments
                .rebuild((b) => b..types.replace([]))
                .newInstance([], {
                  'query': refer('firestore').property('collection').call([
                    literalString(collection.path),
                  ]),
                  'toJson': ConverterGenerator.getToJsonEnsured(
                    type: collection.modelType,
                  ),
                  'fromJson': ConverterGenerator.getFromJsonEnsured(
                    type: collection.modelType,
                  ),
                  'documentIdField': literalString(
                    getDocumentIdFieldName(collection.modelType),
                  ),
                  'patchBuilder': UpdateGenerator.getBuilderInstanceExpression(
                    type: collection.modelType,
                  ),
                  'filterBuilder': FilterGenerator.getBuilderInstanceExpression(
                    type: collection.modelType,

                    isRoot: true,
                  ),
                  'orderByBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body =
                          OrderByGenerator.getOrderByBuilderInstanceExpression(
                            type: collection.modelType,
                            context: refer('context'),
                          ).code,
                  ).closure,
                  'aggregateBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body = AggregateGenerator.getBuilderInstanceExpression(
                        type: collection.modelType,
                        context: refer('context'),

                        isRoot: true,
                      ).code,
                  ).closure,
                })
                .code,
        ),
      );
    }

    return Extension(
      (b) => b
        ..docs.add(
          '/// Class to add collections to `FirestoreODM<$schemaClassName>`',
        )
        ..name = '\$${schemaClassName.upperFirst()}ODM'
        ..on = TypeReference(
          (b) => b
            ..symbol = 'FirestoreODM'
            ..types.add(
              refer(
                schemaClassName.isEmpty ? 'FirestoreSchema' : schemaClassName,
              ),
            ),
        )
        ..methods.addAll(methods),
    );
  }

  /// Generate ODM extensions for the schema
  static Class generateODMClass(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final collectionName = _getCollectionName(collection.path);
      final collectionType = TypeReference(
        (b) => b
          ..symbol = 'FirestoreCollection'
          ..types.addAll([
            refer(schemaClassName),
            refer(collection.modelTypeName),
            _getPathRecord(collection.path),
            UpdateGenerator.getBuilderType(type: collection.modelType),
            FilterGenerator.getBuilderType(type: collection.modelType),
            OrderByGenerator.getOrderByBuilderType(type: collection.modelType),
            AggregateGenerator.getBuilderType(
              type: collection.modelType,

              isRoot: true,
            ),
          ]),
      );
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..name = collectionName.camelCase().lowerFirst()
            ..returns = collectionType
            ..type = MethodType.getter
            ..annotations.add(preferInlineAnnotation)
            ..body = collectionType
                // to simplify the type arguments
                .rebuild((b) => b..types.replace([]))
                .newInstance([], {
                  'query': refer('firestore').property('collection').call([
                    literalString(collection.path),
                  ]),
                  'toJson': ConverterGenerator.getToJsonEnsured(
                    type: collection.modelType,
                  ),
                  'fromJson': ConverterGenerator.getFromJsonEnsured(
                    type: collection.modelType,
                  ),
                  'documentIdField': literalString(
                    getDocumentIdFieldName(collection.modelType),
                  ),
                  'patchBuilder': UpdateGenerator.getBuilderInstanceExpression(
                    type: collection.modelType,
                  ),
                  'filterBuilder': FilterGenerator.getBuilderInstanceExpression(
                    type: collection.modelType,

                    isRoot: true,
                  ),
                  'orderByBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body =
                          OrderByGenerator.getOrderByBuilderInstanceExpression(
                            type: collection.modelType,
                            context: refer('context'),
                          ).code,
                  ).closure,
                  'aggregateBuilderFunc': Method(
                    (b) => b
                      ..requiredParameters.add(
                        Parameter((b) => b..name = 'context'),
                      )
                      ..lambda = true
                      ..body = AggregateGenerator.getBuilderInstanceExpression(
                        type: collection.modelType,
                        context: refer('context'),

                        isRoot: true,
                      ).code,
                  ).closure,
                })
                .code,
        ),
      );
    }

    return Class(
      (b) => b
        ..docs.add(
          '/// Class to add collections to `FirestoreODM<$schemaClassName>`',
        )
        ..name = '\$${schemaClassName.upperFirst()}ODM'
        ..extend = TypeReference(
          (b) => b
            ..symbol = 'FirestoreODM'
            ..types.add(
              refer(
                schemaClassName.isEmpty ? 'FirestoreSchema' : schemaClassName,
              ),
            ),
        )
        ..methods.addAll(methods),
    );
  }

  /// Generate transaction context extensions for the schema
  static Extension generateTransactionContext(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final collectionType = TypeReference(
        (b) => b
          ..symbol = 'TransactionCollection'
          ..types.addAll([
            refer(schemaClassName),
            refer(collection.modelTypeName),
            _getPathRecord(collection.path),
            UpdateGenerator.getBuilderType(type: collection.modelType),
          ]),
      );
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..name = collection.path.camelCase().lowerFirst()
            ..annotations.addAll([preferInlineAnnotation])
            ..returns = collectionType
            ..type = MethodType.getter
            ..body = collectionType.newInstance([], {
              'query': refer(
                'ref',
              ).property('collection').call([literalString(collection.path)]),
              'context': refer('this'),
              'toJson': ConverterGenerator.getToJsonEnsured(
                type: collection.modelType,
              ),
              'fromJson': ConverterGenerator.getFromJsonEnsured(
                type: collection.modelType,
              ),
              'documentIdField': literalString(
                getDocumentIdFieldName(collection.modelType),
              ),
              'patchBuilder': UpdateGenerator.getBuilderInstanceExpression(
                type: collection.modelType,
              ),
            }).code,
        ),
      );
    }

    return Extension(
      (b) => b
        ..docs.add(
          '/// Extension to add collections to `TransactionContext<$schemaClassName>`',
        )
        ..name = generateClassName(
          schemaClassName: schemaClassName,
          type: ClassType.transactionContext,
        )
        ..on = TypeReference(
          (b) => b
            ..symbol = 'TransactionContext'
            ..types.add(refer(schemaClassName)),
        )
        ..methods.addAll(methods),
    );
  }

  static List<Spec> generateTransactionDocuments(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
  ) {
    final specs = <Spec>[];

    for (final collection in collections) {
      final documentClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.transactionDocument,
      );

      final modelType = collection.modelTypeName;
      final methods = <Method>[];
      for (final subcol in getSubcollections(collections, collection)) {
        final collectionType = TypeReference(
          (b) => b
            ..symbol = 'TransactionCollection'
            ..types.addAll([
              refer(schemaClassName),
              refer(subcol.modelTypeName),
              _getPathRecord(subcol.path),
              UpdateGenerator.getBuilderType(type: subcol.modelType),
            ]),
        );

        methods.add(
          Method(
            (b) => b
              ..docs.add(
                '/// Access ${_getCollectionName(subcol.path)} subcollection',
              )
              ..annotations.addAll([preferInlineAnnotation])
              ..type = MethodType.getter
              ..name = _getCollectionName(subcol.path).camelCase().lowerFirst()
              ..returns = collectionType
              ..lambda = true
              ..body = collectionType.newInstance([], {
                'query': refer('ref').property('collection').call([
                  literalString(_getCollectionName(subcol.path)),
                ]),
                'context': refer('context'),
                'toJson': ConverterGenerator.getToJsonEnsured(
                  type: subcol.modelType,
                ),
                'fromJson': ConverterGenerator.getFromJsonEnsured(
                  type: subcol.modelType,
                ),
                'documentIdField': literalString(
                  getDocumentIdFieldName(subcol.modelType),
                ),
                'patchBuilder': UpdateGenerator.getBuilderInstanceExpression(
                  type: subcol.modelType,
                ),
              }).code,
          ),
        );
      }

      if (methods.isNotEmpty) {
        final documentClass = Extension(
          (b) => b
            ..docs.add(
              '/// Transaction document class for ${collection.path} collection',
            )
            ..name = documentClassName
            ..on = TypeReference(
              (b) => b
                ..symbol = 'TransactionDocument'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(modelType),
                  _getPathRecord(collection.path),
                  UpdateGenerator.getBuilderType(type: collection.modelType),
                ]),
            )
            ..methods.addAll(methods),
        );

        specs.add(documentClass);
      }
    }
    return specs;
  }

  /// Generate batch context extensions for the schema
  static Extension? generateBatchContextExtensions(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
  ) {
    final rootCollections = collections
        .where((c) => !c.isSubcollection)
        .toList();
    if (rootCollections.isEmpty) return null;

    final methods = <Method>[];

    for (final collection in rootCollections) {
      final documentIdFieldName = getDocumentIdFieldName(collection.modelType);
      methods.add(
        Method(
          (b) => b
            ..docs.add('/// Access ${collection.path} collection')
            ..type = MethodType.getter
            ..name = collection.path.camelCase().lowerFirst()
            ..returns = TypeReference(
              (b) => b
                ..symbol = 'BatchCollection'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(collection.modelTypeName),
                  _getPathRecord(collection.path),
                  UpdateGenerator.getBuilderType(type: collection.modelType),
                ]),
            )
            ..lambda = true
            ..body = TypeReference((b) => b..symbol = 'BatchCollection')
                .newInstance([], {
                  'context': refer('this'),
                  'collection': refer('firestoreInstance')
                      .property('collection')
                      .call([literalString(collection.path)]),
                  'toJson': ConverterGenerator.getToJsonEnsured(
                    type: collection.modelType,
                  ),
                  'fromJson': ConverterGenerator.getFromJsonEnsured(
                    type: collection.modelType,
                  ),
                  'documentIdField': literalString(documentIdFieldName),
                  'patchBuilder': UpdateGenerator.getBuilderInstanceExpression(
                    type: collection.modelType,
                  ),
                })
                .code,
        ),
      );
    }

    return Extension(
      (b) => b
        ..docs.add(
          '/// Extension to add collections to BatchContext<$schemaClassName>',
        )
        ..name = '\$${schemaClassName.upperFirst()}BatchContextExtensions'
        ..on = TypeReference(
          (b) => b
            ..symbol = 'BatchContext'
            ..types.add(refer(schemaClassName)),
        )
        ..methods.addAll(methods),
    );
  }

  /// Generate unique document and collection classes for each collection path
  static List<Spec> generateUniqueDocumentClasses(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
  ) {
    final specs = <Spec>[];

    for (final collection in collections) {
      final documentClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.document,
      );
      final modelTypeName = collection.modelTypeName;

      final methods = <Method>[];

      for (final subcol in getSubcollections(collections, collection)) {
        final subcollectionName = _getCollectionName(subcol.path);
        final getterName = subcollectionName.camelCase().lowerFirst();
        final documentIdFieldName = getDocumentIdFieldName(subcol.modelType);

        final collectionType = TypeReference(
          (b) => b
            ..symbol = 'FirestoreCollection'
            ..types.addAll([
              refer(schemaClassName),
              subcol.modelType.reference,
              _getPathRecord(subcol.path),
              UpdateGenerator.getBuilderType(type: subcol.modelType),
              FilterGenerator.getBuilderType(
                type: subcol.modelType,
                isRoot: true,
              ),
              OrderByGenerator.getOrderByBuilderType(type: subcol.modelType),
              AggregateGenerator.getBuilderType(
                type: subcol.modelType,

                isRoot: true,
              ),
            ]),
        );
        methods.add(
          Method(
            (b) => b
              ..docs.add('/// Access $subcollectionName subcollection')
              ..type = MethodType.getter
              ..name = getterName
              ..returns = collectionType
              ..lambda = true
              ..body = collectionType
                  // to simplify the type arguments
                  .rebuild((b) => b..types.replace([]))
                  .newInstance([], {
                    'query': refer('ref').property('collection').call([
                      literalString(subcollectionName),
                    ]),
                    'toJson': ConverterGenerator.getToJsonEnsured(
                      type: subcol.modelType,
                    ),
                    'fromJson': ConverterGenerator.getFromJsonEnsured(
                      type: subcol.modelType,
                    ),
                    'documentIdField': literalString(documentIdFieldName),
                    'patchBuilder':
                        UpdateGenerator.getBuilderInstanceExpression(
                          type: subcol.modelType,
                        ),
                    'filterBuilder':
                        FilterGenerator.getBuilderInstanceExpression(
                          type: subcol.modelType,

                          isRoot: true,
                        ),
                    'orderByBuilderFunc': Method(
                      (b) => b
                        ..requiredParameters.add(
                          Parameter((b) => b..name = 'context'),
                        )
                        ..lambda = true
                        ..body =
                            OrderByGenerator.getOrderByBuilderInstanceExpression(
                              type: subcol.modelType,
                              context: refer('context'),
                            ).code,
                    ).closure,
                    'aggregateBuilderFunc': Method(
                      (b) => b
                        ..requiredParameters.add(
                          Parameter((b) => b..name = 'context'),
                        )
                        ..lambda = true
                        ..body =
                            AggregateGenerator.getBuilderInstanceExpression(
                              type: subcol.modelType,
                              context: refer('context'),
                              isRoot: true,
                            ).code,
                    ).closure,
                  })
                  .code,
          ),
        );
      }

      // Generate document class
      if (methods.isNotEmpty) {
        final documentClass = Extension(
          (b) => b
            ..docs.add('/// Document class for ${collection.path} collection')
            ..name = documentClassName
            ..on = TypeReference(
              (b) => b
                ..symbol = 'FirestoreDocument'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(modelTypeName),
                  _getPathRecord(collection.path),
                  UpdateGenerator.getBuilderType(type: collection.modelType),
                ]),
            )
            ..methods.addAll(methods),
        );
        specs.add(documentClass);
      }
    }

    return specs;
  }

  /// Generate document extensions for subcollections
  static List<Spec> generateCollectionIdentifiers(
    List<SchemaCollectionInfo> collections,
  ) {
    return [
      Code('''
/// Identifiers for all Firestore collections in the schema
/// Used to map collection paths to their respective collection classes
/// By combining collection classes (e.g., as tuple types),
/// we can use extension methods with record types to reduce boilerplate
/// Example: (_\$UsersCollection, _\$PostsCollection)
      '''),
      ...collections.map((c) => _getCollectionName(c.path)).toSet().map((c) {
        return Class(
          (b) => b
            ..name = '_\$${c.upperFirst()}Collection'
            ..modifier = ClassModifier.final$,
        );
      }),
    ];
  }

  static List<SchemaCollectionInfo> getSubcollections(
    List<SchemaCollectionInfo> collections,
    SchemaCollectionInfo parentCollection,
  ) {
    return collections.where((c) {
      final parentPath = _getParentCollectionPath(c.path);
      return c.isSubcollection && parentPath == parentCollection.path;
    }).toList();
  }

  /// Generate batch document extensions for subcollections
  static List<Spec> generateBatchDocumentExtensions(
    String schemaClassName,
    List<SchemaCollectionInfo> collections,
  ) {
    final specs = <Spec>[];

    for (final collection in collections) {
      final documentClassName = generateClassName(
        schemaClassName: schemaClassName,
        collectionPath: collection.path,
        type: ClassType.batchDocument,
      );

      final modelType = collection.modelTypeName;
      final methods = <Method>[];
      for (final subcol in getSubcollections(collections, collection)) {
        final collectionType = TypeReference(
          (b) => b
            ..symbol = 'BatchCollection'
            ..types.addAll([
              refer(schemaClassName),
              refer(subcol.modelTypeName),
              _getPathRecord(subcol.path),
              UpdateGenerator.getBuilderType(type: subcol.modelType),
            ]),
        );

        methods.add(
          Method(
            (b) => b
              ..docs.add(
                '/// Access ${_getCollectionName(subcol.path)} subcollection',
              )
              ..annotations.addAll([preferInlineAnnotation])
              ..type = MethodType.getter
              ..name = _getCollectionName(subcol.path).camelCase().lowerFirst()
              ..returns = collectionType
              ..lambda = true
              ..body = refer('getBatchCollection').call([], {
                'parent': refer('this'),
                'name': literalString(_getCollectionName(subcol.path)),
                'toJson': ConverterGenerator.getToJsonEnsured(
                  type: subcol.modelType,
                ),
                'fromJson': ConverterGenerator.getFromJsonEnsured(
                  type: subcol.modelType,
                ),
                'documentIdField': literalString(
                  getDocumentIdFieldName(subcol.modelType),
                ),
                'patchBuilder': UpdateGenerator.getBuilderInstanceExpression(
                  type: subcol.modelType,
                ),
              }).code,
          ),
        );
      }

      if (methods.isNotEmpty) {
        final documentClass = Extension(
          (b) => b
            ..docs.add(
              '/// Batch document class for ${collection.path} collection',
            )
            ..name = documentClassName
            ..on = TypeReference(
              (b) => b
                ..symbol = 'BatchDocument'
                ..types.addAll([
                  refer(schemaClassName),
                  refer(modelType),
                  _getPathRecord(collection.path),
                  UpdateGenerator.getBuilderType(type: collection.modelType),
                ]),
            )
            ..methods.addAll(methods),
        );

        specs.add(documentClass);
      }
    }
    return specs;
  }

  static Iterable<DartType> scan(
    DartType type, [
    Element? annotatedElement,
  ]) sync* {
    yield type;

    if (type is! InterfaceType) return;

    final fields = getFields(type);
    // Recursively find all nested InterfaceTypes in the fields of this type
    for (final field in fields.values) {
      yield* scan(field.type, field.element);
    }

    // If this is a ParameterizedType, analyze its type arguments as well
    for (final arg in type.typeArguments) {
      yield* scan(arg);
    }
  }
}
