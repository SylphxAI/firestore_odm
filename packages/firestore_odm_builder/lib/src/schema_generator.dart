/// Generates the `FirestoreODM` extension for a `@Schema` variable: one
/// accessor per `@Collection` entry.
///
/// Accessor semantics (ADR-0002):
/// - Root collection `users`      -> getter `users` (collection) and method
///   `users(String id)` (document).
/// - Subcollection `users/*/posts` -> method `posts(String userId)` (collection).
/// - A name used for both root and sub collections -> getter for the root
///   collection plus one method with optional parent args for subcollections.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/model_analyzer.dart';
import 'utils/reference_utils.dart';
import 'utils/string_utils.dart';

/// Generator for `@Schema` top-level variables.
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
        '@Schema can only be applied to top-level variables.',
        element: element,
      );
    }
    return _generateForSchema(element);
  }

  String _generateForSchema(TopLevelVariableElement element) {
    final schemaType = element.type;
    if (schemaType is! InterfaceType) {
      throw InvalidGenerationSourceError(
        '@Schema variable must have an interface type, found '
        '${schemaType.getDisplayString()}',
        element: element,
      );
    }
    final schemaName = schemaType.element.name;
    final collections = _extractCollections(element);
    _validate(collections);

    final byName = <String, List<SchemaCollectionInfo>>{};
    for (final c in collections) {
      byName.putIfAbsent(_accessorName(c.path), () => []).add(c);
    }

    final specs = <Spec>[];
    final methods = <Method>[];
    for (final entry in byName.entries) {
      final helpers = _pathHelpers(entry.key, entry.value);
      specs.addAll(helpers);
      methods.addAll(_accessors(schemaType, entry.key, entry.value));
    }

    final extension = Extension(
      (b) => b
        ..name = '${schemaName}FirestoreODMExtension'
        ..on = generic('FirestoreODM', [schemaType.reference])
        ..methods.addAll(methods),
    );
    specs.add(extension);

    return Library(
      (b) => b.body.addAll(specs),
    ).accept(DartEmitter(useNullSafetySyntax: true)).toString();
  }

  /// Generates `String _<name>Path([String? p1, ...])` helpers dispatching by
  /// arity for subcollection groups.
  List<Spec> _pathHelpers(String name, List<SchemaCollectionInfo> collections) {
    final subs = collections.where((c) => c.isSubcollection).toList()
      ..sort(
        (a, b) =>
            _wildcards(a.path).length.compareTo(_wildcards(b.path).length),
      );
    if (subs.isEmpty) return const [];

    final maxWildcards = _wildcards(subs.last.path).length;
    // Ternary chain from deepest (most wildcards) down to the root literal.
    Expression pathExpr = subs.any((c) => !c.isSubcollection)
        ? literalString(_firstRoot(collections).path)
        : literalNull;
    for (final sub in subs.reversed) {
      final argsCheck = _wildcards(sub.path)
          .asMap()
          .entries
          .map((e) => refer('p${e.key + 1}').notEqualTo(literalNull))
          .fold<Expression>(literalBool(true), (acc, e) => acc.and(e));
      pathExpr = argsCheck.conditional(_interpolate(sub.path), pathExpr);
    }

    return [
      Method(
        (m) => m
          ..name = '_${name}Path'
          ..returns = refer('String')
          ..optionalParameters.addAll([
            for (var i = 0; i < maxWildcards; i++)
              Parameter(
                (p) => p
                  ..name = 'p${i + 1}'
                  ..type = TypeReferences.string,
              ),
          ])
          ..body = pathExpr.code,
      ),
    ];
  }

  List<Method> _accessors(
    InterfaceType schemaType,
    String name,
    List<SchemaCollectionInfo> collections,
  ) {
    final methods = <Method>[];
    final hasRoot = collections.any((c) => !c.isSubcollection);
    final subs = collections.where((c) => c.isSubcollection).toList()
      ..sort(
        (a, b) =>
            _wildcards(a.path).length.compareTo(_wildcards(b.path).length),
      );

    if (hasRoot) {
      final root = _firstRoot(collections);
      methods.add(
        Method(
          (m) => m
            ..type = MethodType.getter
            ..name = name
            ..returns = _collectionType(schemaType, root)
            ..body = _collectionInstance(
              schemaType,
              root,
              _literalPath(root.path),
            ).code,
        ),
      );
    }

    if (subs.isEmpty && hasRoot) {
      // Root document accessor: users(String id).
      final root = _firstRoot(collections);
      methods.add(
        Method(
          (m) => m
            ..name = name
            ..returns = _documentType(schemaType, root)
            ..requiredParameters.add(
              Parameter(
                (p) => p
                  ..name = 'id'
                  ..type = TypeReferences.string,
              ),
            )
            ..body = _collectionInstance(
              schemaType,
              root,
              _literalPath(root.path),
            ).property('doc').call([refer('id')]).code,
        ),
      );
      return methods;
    }

    if (subs.isEmpty) return methods;

    final maxWildcards = _wildcards(subs.last.path).length;
    methods.add(
      Method(
        (m) => m
          ..name = name
          ..returns = _collectionType(schemaType, subs.first)
          ..optionalParameters.addAll([
            for (var i = 0; i < maxWildcards; i++)
              Parameter(
                (p) => p
                  ..name = 'p${i + 1}'
                  ..type = TypeReferences.string,
              ),
          ])
          ..body = _collectionInstance(
            schemaType,
            subs.first,
            _literalPath(subs.first.path),
            pathOverride: refer(
              '_${name}Path',
            ).call([for (var i = 0; i < maxWildcards; i++) refer('p${i + 1}')]),
          ).code,
      ),
    );
    return methods;
  }

  Expression _collectionInstance(
    InterfaceType schemaType,
    SchemaCollectionInfo c,
    Expression pathExpr, {
    Expression? pathOverride,
  }) {
    final modelType = c.modelType;
    final modelName = modelType.element.name;
    final documentIdField = getDocumentIdFieldName(modelType);
    final finalPath = pathOverride ?? pathExpr;

    return refer('FirestoreCollection').newInstance([], {
      'ref': refer('firestore').property('collection').call([finalPath]),
      'toJson': _toJsonRef(modelType),
      'fromJson': _fromJsonRef(modelType),
      'documentIdField': documentIdField == null
          ? literalNull
          : literalString(documentIdField),
      'patchBuilderFactory': Method(
        (m) => m
          ..body = refer(
            '${modelName}PatchBuilder',
          ).newInstance([], const {}, const []).code,
      ).closure,
      'filterBuilder': refer(
        '${modelName}FilterBuilder',
      ).newInstance([], const {}, const []),
      'orderByBuilderFunc': Method(
        (m) => m
          ..requiredParameters.add(Parameter((p) => p..name = 'context'))
          ..body = refer(
            '${modelName}OrderByBuilder',
          ).newInstance([], {'context': refer('context')}).code,
      ).closure,
      'aggregateBuilderFunc': Method(
        (m) => m
          ..requiredParameters.add(Parameter((p) => p..name = 'context'))
          ..body = refer(
            '${modelName}AggregateBuilder',
          ).newInstance([], {'context': refer('context')}).code,
      ).closure,
    });
  }

  Expression _toJsonRef(InterfaceType modelType) {
    if (hasOwnToJson(modelType)) {
      return Method(
        (m) => m
          ..requiredParameters.add(
            Parameter(
              (p) => p
                ..name = 'value'
                ..type = modelType.reference,
            ),
          )
          ..body = refer('value').property('toJson').call(const []).code,
      ).closure;
    }
    return refer('${modelType.element.name}ToJson');
  }

  Expression _fromJsonRef(InterfaceType modelType) {
    if (hasOwnFromJson(modelType)) {
      return refer('${modelType.element.name}.fromJson');
    }
    return refer('${modelType.element.name}FromJson');
  }

  TypeReference _collectionType(
    InterfaceType schemaType,
    SchemaCollectionInfo c,
  ) {
    final modelName = c.modelType.element.name;
    return generic('FirestoreCollection', [
      schemaType.reference,
      c.modelType.reference,
      refer('${modelName}PatchBuilder'),
      refer('${modelName}FilterBuilder'),
      refer('${modelName}OrderByBuilder'),
      refer('${modelName}AggregateBuilder'),
    ]);
  }

  TypeReference _documentType(
    InterfaceType schemaType,
    SchemaCollectionInfo c,
  ) {
    final modelName = c.modelType.element.name;
    return generic('FirestoreDocument', [
      schemaType.reference,
      c.modelType.reference,
      refer('${modelName}PatchBuilder'),
    ]);
  }

  Expression _literalPath(String path) => literalString(path);

  Expression _interpolate(String path) {
    final parts = path.split('*');
    final buf = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      buf.write(parts[i]);
      if (i < parts.length - 1) buf.write('\${p${i + 1}}');
    }
    return CodeExpression(Code('"${buf.toString()}"'));
  }

  SchemaCollectionInfo _firstRoot(List<SchemaCollectionInfo> collections) =>
      collections.firstWhere((c) => !c.isSubcollection);

  List<SchemaCollectionInfo> _extractCollections(
    TopLevelVariableElement element,
  ) {
    final collections = <SchemaCollectionInfo>[];
    for (final annotation in element.metadata.annotations) {
      final value = annotation.computeConstantValue();
      if (value?.type?.element?.name != 'Collection') continue;
      final path = value!.getField('path')!.toStringValue()!;
      final collectionType = value.type!;
      if (collectionType is ParameterizedType &&
          collectionType.typeArguments.isNotEmpty) {
        final modelType = collectionType.typeArguments.first;
        if (modelType is! InterfaceType) {
          throw InvalidGenerationSourceError(
            'Model type must be an interface type for @Collection, found '
            '${modelType.getDisplayString()}',
            element: element,
          );
        }
        collections.add(
          SchemaCollectionInfo(
            path: path,
            modelType: modelType,
            isSubcollection: path.contains('*'),
          ),
        );
      }
    }
    if (collections.isEmpty) {
      throw InvalidGenerationSourceError(
        '@Schema variable declares no @Collection annotations.',
        element: element,
      );
    }
    return collections;
  }

  void _validate(List<SchemaCollectionInfo> collections) {
    final paths = <String>{};
    for (final c in collections) {
      if (!paths.add(c.path)) {
        throw InvalidGenerationSourceError(
          'Duplicate @Collection path: ${c.path}',
        );
      }
      if (!_isValidPath(c.path)) {
        throw InvalidGenerationSourceError(
          'Invalid collection path: ${c.path}. Wildcards must be whole '
          'segments (e.g. "users/*/posts").',
        );
      }
    }
  }

  bool _isValidPath(String path) {
    final segments = path.split('/');
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s == '*') {
        if (i == 0 || i == segments.length - 1) return false;
      } else if (s.isEmpty) {
        return false;
      }
    }
    return true;
  }

  List<String> _wildcards(String path) =>
      path.split('/').where((s) => s == '*').toList();

  String _accessorName(String path) =>
      path.split('/').last.camelCase().lowerFirst();
}

/// Collection metadata extracted from a `@Collection` annotation.
class SchemaCollectionInfo {
  final String path;
  final InterfaceType modelType;
  final bool isSubcollection;

  const SchemaCollectionInfo({
    required this.path,
    required this.modelType,
    required this.isSubcollection,
  });
}

/// Type references for common built-ins.
abstract final class TypeReferences {
  static final string = TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core',
  );
}
