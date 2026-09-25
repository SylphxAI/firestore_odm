/// Writes the same N models for both benchmark projects, so code generation
/// is timed on identical input.
///
/// dart run benchmarks/generate_models.dart [count, default 20]
library;

import 'dart:io';

const _fields = '''
  final String name;
  final String description;
  final int count;
  final int rank;
  final double score;
  final bool active;
  final DateTime? updatedAt;
  final List<String> tags;''';

const _params = '''
    required this.id,
    required this.name,
    required this.description,
    required this.count,
    required this.rank,
    required this.score,
    required this.active,
    this.updatedAt,
    this.tags = const [],''';

void main(List<String> args) {
  final count = args.isEmpty ? 20 : int.parse(args.single);
  final root = File(Platform.script.toFilePath()).parent.path;
  final odmDir = Directory('$root/firestore_odm/lib/models');
  final cfDir = Directory('$root/cloud_firestore_odm/lib/models');
  for (final dir in [odmDir, cfDir]) {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
  }

  final names = [
    for (var i = 1; i <= count; i++) 'Model${i.toString().padLeft(2, '0')}',
  ];
  for (final name in names) {
    final file = _snake(name);
    File('${odmDir.path}/$file.dart').writeAsStringSync('''
import 'package:firestore_odm/firestore_odm.dart';

part '$file.g.dart';

@firestoreOdm
class $name {
  const $name({
$_params
  });

  @DocumentIdField()
  final String id;
$_fields
}
''');
    File('${cfDir.path}/$file.dart').writeAsStringSync('''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_odm/cloud_firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part '$file.g.dart';

@JsonSerializable()
class $name {
  $name({
$_params
  });

  factory $name.fromJson(Map<String, Object?> json) => _\$${name}FromJson(json);

  @Id()
  final String id;
$_fields

  Map<String, Object?> toJson() => _\$${name}ToJson(this);
}

@Collection<$name>('${_snake(name)}')
final ${_lower(name)}Ref = ${name}CollectionReference();
''');
  }

  File('${odmDir.path}/schema.dart').writeAsStringSync('''
import 'package:firestore_odm/firestore_odm.dart';

${names.map((n) => "import '${_snake(n)}.dart';").join('\n')}

part 'schema.g.dart';

class BenchSchema extends FirestoreSchema {
  const BenchSchema();
}

@Schema()
${names.map((n) => "@Collection<$n>('${_snake(n)}')").join('\n')}
const benchSchema = BenchSchema();
''');
  stdout.writeln('Wrote $count models for each project.');
}

String _snake(String s) => s
    .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')
    .replaceFirst('_', '');

String _lower(String s) => s[0].toLowerCase() + s.substring(1);
