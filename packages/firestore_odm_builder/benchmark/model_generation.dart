/// Run from the builder package: dart run benchmark/model_generation.dart.
/// Measures the generator after resolution; generated source is saved when an
/// output directory is supplied so two revisions can be compared byte for byte.
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:build/build.dart';
import 'package:firestore_odm_builder/src/model_builder_generator.dart';
import 'package:source_gen/source_gen.dart';

Future<void> main(List<String> args) async {
  final output = args.isEmpty ? null : Directory(args.first);
  output?.createSync(recursive: true);
  final temporary = Directory('benchmark').createTempSync('model_generation_');
  final fixture = File('${temporary.path}/model.dart');
  try {
    for (final count in [10, 100, 1000]) {
      fixture.writeAsStringSync('''
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
@firestoreOdm
class WideModel {
  const WideModel({required this.id, ${List.generate(count, (i) => 'this.field$i = $i').join(', ')}});
  final String id;
  ${List.generate(count, (i) => '@Min(0) final int field$i;').join('\n')}
}
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
        final library = LibraryReader(resolved.libraryElement);
        const generator = ModelBuilderGenerator();
        final buildStep = _UnusedBuildStep();
        for (var warmup = 0; warmup < 5; warmup++) {
          await generator.generate(library, buildStep);
        }
        final times = <int>[];
        String? source;
        for (var run = 0; run < 11; run++) {
          final watch = Stopwatch()..start();
          source = await generator.generate(library, buildStep);
          watch.stop();
          times.add(watch.elapsedMicroseconds);
        }
        times.sort();
        if (source == null) throw StateError('No generated model');
        if (output != null) {
          File('${output.path}/model_$count.dart').writeAsStringSync(source);
        }
        stdout.writeln(
          jsonEncode({
            'fields': count,
            'runs_us': times,
            'median_us': times[times.length ~/ 2],
            'generated_bytes': utf8.encode(source).length,
            'rss_bytes': ProcessInfo.currentRss,
            'sdk': Platform.version,
          }),
        );
      } finally {
        await contexts.dispose();
      }
    }
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

class _UnusedBuildStep implements BuildStep {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'The model generator must not read build assets: ${invocation.memberName}',
  );
}
