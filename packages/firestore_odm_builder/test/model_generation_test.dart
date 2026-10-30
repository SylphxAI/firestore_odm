import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:build/build.dart';
import 'package:firestore_odm_builder/src/model_builder_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  const generator = ModelBuilderGenerator();

  Future<String?> generate(String model) async {
    final temporary = Directory('test').createTempSync('model_generation_');
    final fixture = File.fromUri(temporary.absolute.uri.resolve('model.dart'))
      ..writeAsStringSync('''
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
$model
''');
    final contexts = AnalysisContextCollection(
      includedPaths: [fixture.absolute.path],
    );
    try {
      final resolved =
          await contexts
                  .contextFor(fixture.absolute.path)
                  .currentSession
                  .getResolvedUnit(fixture.absolute.path)
              as ResolvedUnitResult;
      return await generator.generate(
        LibraryReader(resolved.libraryElement),
        _UnusedBuildStep(),
      );
    } finally {
      await contexts.dispose();
      temporary.deleteSync(recursive: true);
    }
  }

  test(
    'a reused generator revalidates bounds for each resolved model',
    () async {
      expect(
        await generate('''
@firestoreOdm
class Model {
  const Model({this.value = 0});
  @Min(0)
  final int value;
}
'''),
        isNotEmpty,
      );
      await expectLater(
        generate('''
@firestoreOdm
class Model {
  const Model({this.value = ''});
  @Min(0)
  final String value;
}
'''),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    },
  );

  test(
    'a model without an unnamed constructor still fails generation',
    () async {
      await expectLater(
        generate('''
@firestoreOdm
class Model {
  const Model.named({this.value = 0});
  final int value;
}
'''),
        throwsA(isA<InvalidGenerationSourceError>()),
      );
    },
  );
}

class _UnusedBuildStep implements BuildStep {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected asset access: ${invocation.memberName}',
  );
}
