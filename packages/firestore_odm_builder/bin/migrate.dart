/// Migrates a project from cloud_firestore_odm to firestore_odm.
///
/// ```sh
/// dart pub global activate firestore_odm_builder
/// dart pub global run firestore_odm_builder:migrate            # preview
/// dart pub global run firestore_odm_builder:migrate --apply    # write
/// ```
library;

import 'dart:io';

import 'package:firestore_odm_builder/src/migrate/cloud_firestore_odm_migration.dart';

Future<void> main(List<String> arguments) async {
  final apply = arguments.contains('--apply');
  final roots = arguments.where((a) => !a.startsWith('--')).toList();
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(
      'Usage: migrate [--apply] [project directory, default: .]\n'
      'Rewrites cloud_firestore_odm code and pubspec.yaml for firestore_odm. '
      'Without --apply it only lists the changes.',
    );
    return;
  }
  final root = Directory(roots.isEmpty ? '.' : roots.single);
  final pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('No pubspec.yaml in ${root.absolute.path}');
    exitCode = 64;
    return;
  }

  final files = [
    for (final dir in ['lib', 'test', 'bin', 'integration_test'])
      if (Directory('${root.path}/$dir').existsSync())
        ...Directory('${root.path}/$dir')
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (f) =>
                  f.path.endsWith('.dart') &&
                  !f.path.endsWith('.g.dart') &&
                  !f.path.endsWith('.freezed.dart'),
            ),
  ];
  final sources = {for (final f in files) f: f.readAsStringSync()};
  final declarations = [
    for (final source in sources.values) ...collectDeclarations(source),
  ];

  var changed = 0;
  var followUps = 0;
  final pubspecSource = pubspec.readAsStringSync();
  final newPubspec = migratePubspec(pubspecSource);
  if (newPubspec != pubspecSource) {
    changed++;
    stdout.writeln('pubspec.yaml: dependencies updated');
    if (apply) pubspec.writeAsStringSync(newPubspec);
  }
  for (final MapEntry(key: file, value: source) in sources.entries) {
    final result = migrateDartSource(source, declarations);
    final path = file.path.substring(root.path.length + 1);
    if (result.changed) {
      changed++;
      stdout.writeln('$path: rewritten');
      if (apply) file.writeAsStringSync(result.source);
    }
    for (final followUp in result.followUps) {
      followUps++;
      stdout.writeln('  $path:${followUp.line}: ${followUp.message}');
    }
  }

  stdout.writeln(
    '\n$changed file(s) ${apply ? 'rewritten' : 'to rewrite (run with --apply)'}; '
    '$followUps place(s) to finish by hand.',
  );
  if (apply && changed > 0) {
    stdout.writeln(
      'Next: dart pub get && dart run build_runner build '
      '--delete-conflicting-outputs && dart analyze',
    );
  }
}
