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
import 'package:source_gen/source_gen.dart';

import 'utils/model_analyzer.dart';
import 'utils/type_analyzer.dart';
import 'utils/reference_utils.dart';
import 'utils/string_utils.dart';

/// Generator for `@Schema` top-level variables.
///
/// Implemented as a plain [Generator] (not `GeneratorForAnnotation`) because
/// the schema variable's declared type references the generated schema class
/// (`const TestSchema testSchema = _$TestSchema;`) and is therefore
/// `InvalidType` before codegen — source_gen's annotation resolution would
/// fail on it. We find the annotated variable through its metadata instead.
class SchemaGenerator2 extends Generator {
  const SchemaGenerator2();

  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    for (final variable in library.element.topLevelVariables) {
      final isSchema = variable.metadata.annotations.any(
        (m) => m.computeConstantValue()?.type?.element?.name == 'Schema',
      );
      if (isSchema) {
        return _generateForSchema(variable);
      }
    }
    return null;
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
    final schemaName = schemaType.element.name!;
    final collections = _extractCollections(element);
    _validate(collections);

    final byName = <String, List<SchemaCollectionInfo>>{};
    for (final c in collections) {
      byName.putIfAbsent(_accessorName(c), () => []).add(c);
    }

    final specs = <Spec>[];
    final methods = <Method>[];
    for (final entry in byName.entries) {
      methods.addAll(_accessors(schemaType, entry.key, entry.value));
    }

    final extension = Extension(
      (b) => b
        ..name = '${schemaName}FirestoreODMExtension'
        ..on = generic('FirestoreODM', [schemaType.reference])
        ..methods.addAll(methods),
    );
    specs.add(extension);

    // The schema class is declared by the user (ADR-0002) so the schema
    // variable's type is resolvable before codegen; the generator only emits
    // the extension.
    return Library(
      (b) => b.body.addAll(specs),
    ).accept(DartEmitter(useNullSafetySyntax: true)).toString();
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
      // Root collection: a getter returning FirestoreCollection; documents are
      // reached through its callable `call(id)` (e.g. `db.users('id')`).
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

    if (subs.isEmpty) return methods;

    // Subcollections: one method per distinct subcollection path, named from
    // the full path (e.g. 'users/*/posts' -> `usersPosts(String userId)`).
    for (final sub in subs) {
      final subName = _subAccessorName(sub.path);
      final wildcards = _wildcards(sub.path);
      methods.add(
        Method(
          (m) => m
            ..name = subName
            ..returns = _collectionType(schemaType, sub)
            ..optionalParameters.addAll([
              for (var i = 0; i < wildcards.length; i++)
                Parameter(
                  (p) => p
                    ..name = 'p${i + 1}'
                    ..type = TypeReferences.nullableString,
                ),
            ])
            ..body = _collectionInstance(
              schemaType,
              sub,
              _literalPath(sub.path),
              pathOverride: _interpolate(sub.path),
            ).code,
        ),
      );
    }
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
    // The ODM always owns storage serialization (native Timestamp, ADR-0002).
    // Generated converters are null-tolerant; the ODM always has a full model.
    final name = '${modelType.element.name}ToJson';
    final args = modelType.typeArguments.isEmpty
        ? ''
        : ', toT: ${_toJsonArgConverter(modelType.typeArguments.first)}';
    return Method(
      (m) => m
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'value'
              ..type = modelType.reference,
          ),
        )
        ..body = Code('return $name(value$args) ?? const <String, dynamic>{};'),
    ).closure;
  }

  Expression _fromJsonRef(InterfaceType modelType) {
    final name = '${modelType.element.name}FromJson';
    if (modelType.typeArguments.isEmpty) return refer(name);
    final args = _fromJsonArgConverter(modelType.typeArguments.first);
    final typeArgs = modelType.typeArguments
        .map((t) => t.getDisplayString())
        .join(', ');
    return Method(
      (m) => m
        ..requiredParameters.add(
          Parameter(
            (p) => p
              ..name = 'json'
              ..type = refer('Map<String, dynamic>'),
          ),
        )
        ..body = Code('return $name<$typeArgs>(json, fromT: $args);'),
    ).closure;
  }

  /// A converter expression for a concrete type argument (toJson side).
  String _toJsonArgConverter(DartType arg) {
    if (arg.isDartCoreString ||
        arg.isDartCoreInt ||
        arg.isDartCoreDouble ||
        arg.isDartCoreBool ||
        TypeAnalyzer.isDateTime(arg)) {
      return 'identity';
    }
    if (TypeAnalyzer.isDuration(arg)) return 'durationToJson';
    if (arg is InterfaceType) {
      final name = arg.element.name;
      if (TypeAnalyzer.isEnum(arg)) {
        throw InvalidGenerationSourceError(
          'Enum-typed generic type arguments are not supported by the ODM '
          'storage converter: $name',
        );
      }
      if (arg.typeArguments.isNotEmpty) {
        return '(value) => $name'
            'ToJson<${_typeArgList(arg)}>('
            'value, toT: ${_toJsonArgConverter(arg.typeArguments.first)})';
      }
      return '$name'
          'ToJson';
    }
    return 'identity';
  }

  /// A converter expression for a concrete type argument (fromJson side).
  String _fromJsonArgConverter(DartType arg) {
    if (arg.isDartCoreString) return '(value) => value as String';
    if (arg.isDartCoreInt) return '(value) => value as int';
    if (arg.isDartCoreDouble) return '(value) => value as double';
    if (arg.isDartCoreBool) return '(value) => value as bool';
    if (TypeAnalyzer.isDateTime(arg)) return 'dateTimeFromJson';
    if (TypeAnalyzer.isDuration(arg)) return 'durationFromJson';
    if (arg is InterfaceType) {
      final name = arg.element.name;
      if (TypeAnalyzer.isEnum(arg)) {
        throw InvalidGenerationSourceError(
          'Enum-typed generic type arguments are not supported by the ODM '
          'storage converter: $name',
        );
      }
      if (arg.typeArguments.isNotEmpty) {
        return '(value) => $name'
            'FromJson<${_typeArgList(arg)}>('
            'value as Map<String, dynamic>, '
            'fromT: ${_fromJsonArgConverter(arg.typeArguments.first)})';
      }
      // Wrap in a cast closure: `Book Function(Map)` is not assignable to
      // `Book Function(dynamic)`.
      return '(value) => $name'
          'FromJson(value as Map<String, dynamic>)';
    }
    return '(value) => value';
  }

  String _typeArgList(InterfaceType type) =>
      type.typeArguments.map((t) => t.getDisplayString()).join(', ');

  TypeReference _collectionType(
    InterfaceType schemaType,
    SchemaCollectionInfo c,
  ) {
    final modelName = c.modelType.element.name;
    final typeArgs = c.modelType.typeArguments.map((t) => t.reference).toList();
    return generic('FirestoreCollection', [
      schemaType.reference,
      c.modelType.reference,
      generic('${modelName}PatchBuilder', typeArgs),
      generic('${modelName}FilterBuilder', typeArgs),
      generic('${modelName}OrderByBuilder', typeArgs),
      generic('${modelName}AggregateBuilder', typeArgs),
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
    final names = <String>{};
    for (final c in collections) {
      if (!paths.add(c.path)) {
        throw InvalidGenerationSourceError(
          'Duplicate @Collection path: ${c.path}',
        );
      }
      final name = _accessorName(c);
      if (c.isSubcollection && !names.add(name)) {
        throw InvalidGenerationSourceError(
          'Subcollection accessor name collision: $name (${c.path})',
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

  String _accessorName(SchemaCollectionInfo c) => c.isSubcollection
      ? _subAccessorName(c.path)
      : c.path.split('/').last.camelCase().lowerFirst();

  /// Subcollection accessor name from the full path:
  /// 'users/*/posts' -> 'usersPosts'; 'users/*/posts/*/comments' ->
  /// 'usersPostsComments'.
  String _subAccessorName(String path) {
    final segments = path
        .split('/')
        .where((s) => s != '*')
        .map((s) => s.camelCase())
        .toList();
    return segments.join('').lowerFirst();
  }
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

  /// Nullable String (`String?`).
  static final nullableString = TypeReference(
    (b) => b
      ..symbol = 'String'
      ..url = 'dart:core'
      ..isNullable = true,
  );
}
