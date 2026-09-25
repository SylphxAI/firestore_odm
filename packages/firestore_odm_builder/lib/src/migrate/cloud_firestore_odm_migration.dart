/// Codemod from `cloud_firestore_odm` to `firestore_odm`.
///
/// Pure functions over source text: [collectDeclarations] finds the typed
/// collection references a file declares, [migrateDartSource] rewrites a file
/// given every declaration in the project, and [migratePubspec] swaps the
/// dependencies. What cannot be rewritten mechanically is returned as a
/// [FollowUp] with its line in the original file.
library;

import 'dart:convert' show LineSplitter;
import 'dart:math' as math;

import 'dart_scanner.dart';

/// The firestore_odm version the codemod migrates to.
const firestoreOdmConstraint = '^5.1.0';

/// A `@Collection` annotation of a cloud_firestore_odm reference declaration.
class CollectionAnnotation {
  const CollectionAnnotation(this.type, this.path, this.name);

  /// The model type, e.g. `Movie`.
  final String type;

  /// The collection path, e.g. `movies/*/comments`.
  final String path;

  /// The subcollection accessor cloud_firestore_odm generated (`name:` or the
  /// last path segment in camelCase).
  final String name;

  bool get isSubcollection => path.contains('*');
}

/// A `final xRef = XCollectionReference();` declaration and its annotations.
class RefDeclaration {
  const RefDeclaration(this.variable, this.collections);

  /// The declared variable, e.g. `moviesRef`.
  final String variable;

  final List<CollectionAnnotation> collections;

  /// Stem for the generated schema names: `moviesRef` -> `movies`.
  String get stem {
    final s = variable.replaceFirst(RegExp(r'(Collection)?Ref(erence)?$'), '');
    return s.isEmpty ? variable : s;
  }

  String get schemaClass => '${_upperFirst(stem)}Schema';
  String get schemaConstant => '${stem}Schema';
  String get odmVariable => '${stem}Odm';
}

/// Something the codemod could not rewrite, at a line of the original file.
class FollowUp {
  const FollowUp(this.line, this.message);

  final int line;
  final String message;

  @override
  String toString() => 'line $line: $message';
}

/// The rewritten source and what is left to do by hand.
class MigrationResult {
  const MigrationResult(this.source, this.followUps, {required this.changed});

  final String source;
  final List<FollowUp> followUps;
  final bool changed;
}

final _declaration = RegExp(
  r'((?:@Collection<[^\n]+?>\((?:[^()]|\([^()]*\))*\)\s*)+)'
  r'(?:late\s+)?(?:final|const|var)\s+(\w+)\s*=\s*\w+CollectionReference\(\s*\)\s*;',
);
final _annotation = RegExp(
  r'''@Collection<([^\n]+?)>\(\s*(['"])(.*?)\2(?:\s*,\s*name:\s*(['"])(.*?)\4)?\s*,?\s*\)''',
);

/// Finds the collection reference declarations in [source].
List<RefDeclaration> collectDeclarations(String source) => [
  for (final m in _declaration.allMatches(source))
    RefDeclaration(m.group(2)!, [
      for (final a in _annotation.allMatches(m.group(1)!))
        CollectionAnnotation(
          a.group(1)!.trim(),
          a.group(3)!,
          a.group(5) ?? _camelCase(a.group(3)!.split('/').last),
        ),
    ]),
];

/// Rewrites one Dart file. [declarations] holds every reference declaration
/// in the project, so call sites in other files resolve.
MigrationResult migrateDartSource(
  String source,
  List<RefDeclaration> declarations,
) {
  final followUps = _followUps(source, declarations);
  var out = source;
  out = _rewriteImports(out);
  out = _rewriteDeclarations(out);
  out = _annotateModels(out, source);
  out = out.replaceAll('@Id()', '@DocumentIdField()');
  out = out.replaceAll(RegExp(r'[ \t]*@(Min|Max)\([^)]*\)[ \t]*\n'), '');
  out = out.replaceAll(RegExp(r'[ \t]*_\$assert\w+\(this\);[ \t]*\n'), '');
  for (final declaration in declarations) {
    out = _rewriteRefChains(out, declaration);
  }
  out = _rewriteCalls(out);
  return MigrationResult(out, followUps, changed: out != source);
}

/// Swaps cloud_firestore_odm dependencies for firestore_odm and raises
/// cloud_firestore/firebase_core to the majors firestore_odm supports.
String migratePubspec(String pubspec) => pubspec
    .replaceAllMapped(
      RegExp(r'^(\s+)cloud_firestore_odm_generator:.*$', multiLine: true),
      (m) => '${m[1]}firestore_odm_builder: $firestoreOdmConstraint',
    )
    .replaceAllMapped(
      RegExp(r'^(\s+)cloud_firestore_odm:.*$', multiLine: true),
      (m) => '${m[1]}firestore_odm: $firestoreOdmConstraint',
    )
    .replaceAllMapped(
      RegExp(
        r'''^(\s+)cloud_firestore:\s*['"]?[\^>=~ ]*[0-5]\..*$''',
        multiLine: true,
      ),
      (m) => '${m[1]}cloud_firestore: ^6.4.0',
    )
    .replaceAllMapped(
      RegExp(
        r'''^(\s+)firebase_core:\s*['"]?[\^>=~ ]*[0-3]\..*$''',
        multiLine: true,
      ),
      (m) => '${m[1]}firebase_core: ^4.0.0',
    );

String _rewriteImports(String source) {
  final odmImport = RegExp(
    r'''import\s+['"]package:cloud_firestore_odm/[\w/]+\.dart['"]\s*;[ \t]*\n?''',
  );
  if (!odmImport.hasMatch(source)) return source;
  var first = true;
  final hasTarget = source.contains('package:firestore_odm/firestore_odm.dart');
  return source.replaceAllMapped(odmImport, (m) {
    final keep = first && !hasTarget;
    first = false;
    return keep ? "import 'package:firestore_odm/firestore_odm.dart';\n" : '';
  });
}

String _rewriteDeclarations(String source) =>
    source.replaceAllMapped(_declaration, (m) {
      final declaration = collectDeclarations(m.group(0)!).single;
      final root = declaration.collections
          .where((c) => !c.isSubcollection)
          .firstOrNull;
      final annotations = [
        for (final c in declaration.collections)
          "@Collection<${c.type}>('${c.path}')",
      ].join('\n');
      final ref = root == null
          ? ''
          : '\nfinal ${declaration.variable} = '
                '${declaration.odmVariable}.${collectionAccessor(root.path)};';
      return '''
class ${declaration.schemaClass} extends FirestoreSchema {
  const ${declaration.schemaClass}();
}

@Schema()
$annotations
const ${declaration.schemaConstant} = ${declaration.schemaClass}();

final ${declaration.odmVariable} = FirestoreODM(${declaration.schemaConstant});$ref''';
    });

/// Adds `@firestoreOdm` to the model classes this file declares and uses in
/// a `@Collection`, unless they already carry it.
String _annotateModels(String source, String original) {
  final types = {
    for (final d in collectDeclarations(original))
      for (final c in d.collections) c.type.split('<').first,
  };
  var out = source;
  for (final type in types) {
    out = out.replaceAllMapped(
      RegExp(
        r'^([ \t]*)((?:(?:abstract|sealed|final|base|interface)\s+)*class\s+'
        '$type'
        r'\b)',
        multiLine: true,
      ),
      (m) {
        final before = out.substring(0, m.start).trimRight();
        if (before.endsWith('@firestoreOdm')) return m[0]!;
        return '${m[1]}@firestoreOdm\n${m[1]}${m[2]}';
      },
    );
  }
  return out;
}

/// Rewrites call chains that start at a reference variable: subcollection
/// access, `add`, and `snapshots()`.
String _rewriteRefChains(String source, RefDeclaration declaration) {
  final subs = {
    for (final c in declaration.collections.where((c) => c.isSubcollection))
      if (c.path.split('/').where((s) => s == '*').length == 1)
        c.name: subcollectionAccessor(c.path),
  };
  var out = source;
  final start = RegExp('\\b${declaration.variable}\\b');
  var from = 0;
  while (true) {
    final m = start.firstMatch(out.substring(from));
    if (m == null) break;
    final chainStart = from + m.start;
    final chainEnd = _chainEnd(out, from + m.end);
    var chain = out.substring(chainStart, chainEnd);
    for (final entry in subs.entries) {
      chain = chain.replaceAllMapped(
        RegExp(
          '^${declaration.variable}\\s*\\.doc\\(((?:[^()]|\\([^()]*\\))+)\\)'
          '\\s*\\.${entry.key}\\b',
        ),
        (s) => '${declaration.odmVariable}.${entry.value}(${s[1]})',
      );
    }
    chain = chain
        .replaceFirst(
          RegExp('^${declaration.variable}\\.add\\('),
          '${declaration.variable}.create(',
        )
        .replaceAll(RegExp(r'\.snapshots\(\s*\)'), '.stream');
    out = out.replaceRange(chainStart, chainEnd, chain);
    from = chainStart + math.max(chain.length, 1);
  }
  return out;
}

/// End of a `.a(...).b.c(...)` member chain that starts before [index].
int _chainEnd(String source, int index) {
  var i = index;
  while (true) {
    final rest = RegExp(
      r'^\s*\.\s*[A-Za-z_]\w*',
    ).firstMatch(source.substring(i));
    if (rest == null) return i;
    i += rest.end;
    while (true) {
      final ws = RegExp(r'^\s*[(]').firstMatch(source.substring(i));
      if (ws == null) break;
      final close = closingBracket(source, i + ws.end - 1);
      if (close < 0) return i;
      i = close + 1;
    }
  }
}

final _typedCall = RegExp(r'\.(where|orderBy)([A-Z]\w*)\s*\(');
final _namedUpdate = RegExp(r'\.update\(\s*[A-Za-z_]\w*\s*:');
const _cursors = ['startAt', 'startAfter', 'endAt', 'endBefore'];

/// Rewrites generated `whereX`/`orderByX` methods and named `update(...)`.
/// Consecutive `orderByX` calls become one `orderBy` with a record of fields.
String _rewriteCalls(String source) {
  final out = StringBuffer();
  var i = 0;
  while (i < source.length) {
    final typed = _typedCall.matchAsPrefix(source, i);
    final update = typed == null ? _namedUpdate.matchAsPrefix(source, i) : null;
    final call = typed ?? update;
    final close = call == null
        ? -1
        : closingBracket(source, source.indexOf('(', call.start));
    if (call == null || close < 0 || typed?[2] == 'FieldPath') {
      final end = call == null || close < 0 ? i + 1 : close + 1;
      out.write(source.substring(i, end));
      i = end;
      continue;
    }
    final args = splitArguments(
      source.substring(source.indexOf('(', i) + 1, close),
    );
    if (update != null) {
      out.write('.patch(${_patchOps(args)})');
      i = close + 1;
    } else if (typed![1] == 'where') {
      final field = _lowerFirst(typed[2]!);
      final call = args
          .map((a) => a.name == null ? a.value : '${a.name}: ${a.value}')
          .join(', ');
      out.write('.where((\$) => \$.$field($call))');
      i = close + 1;
    } else {
      final group = _OrderByGroup()..add(_lowerFirst(typed[2]!), args);
      i = close + 1;
      while (true) {
        final ws = RegExp(r'\s*').matchAsPrefix(source, i)!;
        final next = _typedCall.matchAsPrefix(source, ws.end);
        if (next == null || next[1] != 'orderBy' || next[2] == 'FieldPath') {
          break;
        }
        final open = source.indexOf('(', next.start);
        final end = closingBracket(source, open);
        if (end < 0) break;
        group.add(
          _lowerFirst(next[2]!),
          splitArguments(source.substring(open + 1, end)),
        );
        i = end + 1;
      }
      out.write(group.render());
    }
  }
  return out.toString();
}

class _OrderByGroup {
  final fields = <String>[];
  final cursors = <String, List<String>>{};

  void add(String field, List<Argument> args) {
    final options = <String>[];
    for (final a in args) {
      if (_cursors.contains(a.name)) {
        (cursors[a.name!] ??= []).add(a.value);
      } else if (a.name == 'descending') {
        options.add('descending: ${a.value}');
      }
    }
    fields.add('\$.$field(${options.join(', ')})');
  }

  String render() {
    final record = fields.length == 1
        ? '(${fields.single},)'
        : '(${fields.join(', ')})';
    final buffer = StringBuffer('.orderBy((\$) => $record)');
    for (final cursor in _cursors) {
      final values = cursors[cursor];
      if (values == null) continue;
      final tuple = values.length == 1
          ? '(${values.single},)'
          : '(${values.join(', ')})';
      buffer.write('.$cursor($tuple)');
    }
    return buffer.toString();
  }
}

final _fieldValue = RegExp(
  r'^FieldValue\.(increment|arrayUnion|arrayRemove|serverTimestamp|delete)\((.*)\)$',
  dotAll: true,
);

String _patchOps(List<Argument> args) {
  final ops = <String>[];
  for (final a in args) {
    final name = a.name;
    if (name == null) continue;
    if (name.endsWith('FieldValue')) {
      final field = name.substring(0, name.length - 'FieldValue'.length);
      final fv = _fieldValue.firstMatch(a.value);
      ops.add(
        fv == null
            ? '\$.$field.set(${a.value})'
            : '\$.$field.${fv[1]}(${fv[2]})',
      );
    } else {
      ops.add('\$.$name.set(${a.value})');
    }
  }
  return '(\$) => [${ops.join(', ')}]';
}

List<FollowUp> _followUps(String source, List<RefDeclaration> declarations) {
  final lines = const LineSplitter().convert(source);
  final result = <FollowUp>[];
  final checks = <(RegExp, String)>[
    (
      RegExp(r'\b(transaction|batch)(Update|Set|Get)\('),
      'transaction/batch helpers: inside odm.runTransaction((tx) async {...}) '
          'use odm.<collection>.inTransaction(tx)(id).get()/patch(...); '
          'inside odm.runBatch((batch) {...}) use '
          'odm.<collection>.inBatch(batch).set/patch/delete.',
    ),
    (
      RegExp(r'\b(where|orderBy)FieldPath\('),
      'string field paths: use the typed selector, or the `ref`/`nativeQuery` '
          'escape hatch for a raw query.',
    ),
    (
      RegExp(r'\b(startAt|startAfter|endAt|endBefore)Document:'),
      'snapshot cursors: use startAfterObject(model) (or startAfter with the '
          'orderBy values) on the ordered query.',
    ),
    (
      RegExp(r'\bFirestoreBuilder\s*<'),
      'FirestoreBuilder: use StreamBuilder<List<T>> (query.stream) or '
          'StreamBuilder<T?> (document.stream); data arrives as models.',
    ),
    (
      RegExp(r'@(Min|Max)\('),
      '@Min/@Max validators are removed: validate in the model constructor.',
    ),
    (
      RegExp(r'@NamedQuery<'),
      '@NamedQuery (bundles): load the bundle with FirebaseFirestore.loadBundle '
          'and query through the typed collection.',
    ),
    (
      RegExp(r'\.(docs|data)\b(?!\s*\()'),
      'snapshot access: get() returns List<T> / T? and stream emits models; '
          'drop .docs/.data/.id (declare a @DocumentIdField to read ids).',
    ),
  ];
  for (final d in declarations) {
    checks
      ..add((
        RegExp('\\b${d.variable}\\.add\\('),
        '${d.variable}.add() became create(), which returns the new '
            'document id (a String), not a reference.',
      ))
      ..add((
        RegExp('\\b${d.variable}\\.doc\\(\\s*\\)'),
        'doc() without an id: call create(model) to get a generated id.',
      ));
  }
  for (var i = 0; i < lines.length; i++) {
    for (final (pattern, message) in checks) {
      if (pattern.hasMatch(lines[i])) result.add(FollowUp(i + 1, message));
    }
  }
  return result;
}

/// The root collection getter the builder generates for [path].
String collectionAccessor(String path) =>
    _lowerFirst(_pascalCase(path.split('/').last));

/// The subcollection method the builder generates for [path]
/// (`users/*/posts` -> `usersPosts`).
String subcollectionAccessor(String path) =>
    _lowerFirst(path.split('/').where((s) => s != '*').map(_pascalCase).join());

String _camelCase(String s) => _lowerFirst(_pascalCase(s));

String _pascalCase(String s) =>
    s.split(RegExp(r'[_\-\s]')).map(_upperFirst).join();

String _upperFirst(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _lowerFirst(String s) =>
    s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
