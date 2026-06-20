import 'package:analyzer/dart/element/type.dart' hide FunctionType;
import 'package:code_builder/code_builder.dart';
import 'package:firestore_odm_builder/src/utils/reference_utils.dart';
import '../utils/model_analyzer.dart';
import 'converter_generator.dart';

/// Generator for the **experimental** type-safe Firestore Pipelines surface.
///
/// For each (non-generic) model it generates:
/// - `<Model>PipelineSelector` — a field-path selector whose leaves are
///   `PipelineField<T>` (and nested selectors for nested objects), so callers
///   build pipeline stages with `$.field` instead of string `Field('path')`.
/// - a `pipeline()` extension on the model's `FirestoreCollection`, returning a
///   `TypedPipeline<Model, <Model>PipelineSelector>`.
///
/// Generic models are skipped for now (documented in ADR-0001) — pipelines are
/// experimental and generic-model support can follow.
class PipelineGenerator {
  /// Whether a pipeline surface can be generated for [type]. Generic models are
  /// skipped (their collection type — and the selector — would need the type
  /// parameters threaded through, which is deferred).
  static bool isSupported(InterfaceType type) =>
      type.element.typeParameters.isEmpty;

  static List<Spec> generate({required InterfaceType type}) {
    if (!isSupported(type)) return const [];
    return [_selectorClass(type), _pipelineExtension(type)];
  }

  static String selectorName(InterfaceType type) =>
      '${type.element.name}PipelineSelector';

  static Field _leaf(FieldInfo field) {
    final fieldPath = field.isDocumentId
        ? refer('FieldPath.documentId')
        : refer('path').property('append').call([literalString(field.jsonName)]);

    final TypeReference leafType;
    final Expression instance;
    if (isUserType(field.type)) {
      // Nested object -> nested selector.
      leafType = TypeReference(
        (b) => b
          ..symbol = '${field.type.element!.name}PipelineSelector'
          ..types.addAll(field.type.typeArguments.map((t) => t.reference)),
      );
      instance = leafType.newInstance([], {'field': fieldPath});
    } else {
      leafType = TypeReference(
        (b) => b
          ..symbol = 'PipelineField'
          ..types.add(field.type.reference),
      );
      instance = leafType.newInstance([], {
        'field': fieldPath,
        'toJson': ConverterGenerator.getToJsonEnsured(
          type: field.type,
          customConverter: field.customConverter,
        ),
      });
    }

    return Field(
      (b) => b
        ..docs.add('/// Pipeline selector for `${field.parameterName}`')
        ..name = field.parameterName
        ..modifier = FieldModifier.final$
        ..late = true
        ..type = leafType
        ..assignment = instance.code,
    );
  }

  static Class _selectorClass(InterfaceType type) {
    final fields = getFields(type);
    return Class(
      (b) => b
        ..name = selectorName(type)
        ..docs.add('/// Generated pipeline selector for `${type.element.name}`')
        ..extend = refer('PipelineFieldNode')
        ..constructors.add(
          Constructor(
            (b) => b
              ..optionalParameters.add(
                Parameter(
                  (b) => b
                    ..name = 'field'
                    ..toSuper = true
                    ..named = true,
                ),
              ),
          ),
        )
        ..fields.addAll([for (final f in fields.values) _leaf(f)]),
    );
  }

  /// A `pipeline()` extension on the model's collection. The `on` type uses the
  /// type-parameter *bounds* for everything except the model `T`; because
  /// Firestore's collection generics are covariant, the concrete
  /// `db.<collection>` (e.g. `FirestoreCollection<TestSchema, User, ...>`)
  /// is a subtype, so the extension applies and dispatches on the model.
  static Extension _pipelineExtension(InterfaceType type) {
    final modelRef = type.reference;
    final selector = TypeReference((b) => b..symbol = selectorName(type));

    final onType = TypeReference(
      (b) => b
        ..symbol = 'FirestoreCollection'
        ..types.addAll([
          refer('FirestoreSchema'),
          modelRef,
          refer('Record'),
          TypeReference(
            (b) => b
              ..symbol = 'PatchBuilder'
              ..types.addAll([
                modelRef,
                TypeReferences.mapOf(
                  TypeReferences.string,
                  TypeReferences.dynamic,
                ).withNullability(true),
              ]),
          ),
          refer('FilterBuilderRoot'),
          refer('OrderByFieldNode'),
          refer('AggregateBuilderRoot'),
        ]),
    );

    final returnType = TypeReference(
      (b) => b
        ..symbol = 'TypedPipeline'
        ..types.addAll([modelRef, selector]),
    );

    final body = returnType.newInstance([
      refer('query').property('firestore').property('pipeline').call([]).property(
        'collection',
      ).call([refer('query').property('path')]),
      refer('fromJson'),
      refer('documentIdField'),
      selector.newInstance([]),
    ]);

    return Extension(
      (b) => b
        ..name = '${type.element.name}PipelineExtension'
        ..docs.add(
          '/// **Experimental** type-safe Firestore Pipeline for `${type.element.name}`.',
        )
        ..on = onType
        ..methods.add(
          Method(
            (b) => b
              ..name = 'pipeline'
              ..returns = returnType
              ..lambda = true
              ..body = body.code,
          ),
        ),
    );
  }
}
