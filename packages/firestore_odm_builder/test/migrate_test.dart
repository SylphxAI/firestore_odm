import 'package:firestore_odm_builder/src/migrate/cloud_firestore_odm_migration.dart';
import 'package:test/test.dart';

/// The model file of the cloud_firestore_odm example app, trimmed.
const movieFile = r'''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_odm/cloud_firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

@JsonSerializable()
class Movie {
  Movie({required this.id, required this.likes, required this.title}) {
    _$assertMovie(this);
  }

  @Id()
  final String id;
  @Min(0)
  final int likes;
  final String title;
}

@Collection<Movie>('movies')
@Collection<Comment>('movies/*/comments', name: 'comments')
final moviesRef = MovieCollectionReference();

@JsonSerializable()
class Comment {
  Comment({required this.message});

  final String message;
}
''';

List<RefDeclaration> get declarations => collectDeclarations(movieFile);

String migrate1(String source) =>
    migrateDartSource(source, collectDeclarations(source)).source;

String migrate(String source) => migrateDartSource(source, declarations).source;

void main() {
  group('declarations', () {
    test('finds the reference and its collections', () {
      final d = declarations.single;
      expect(d.variable, 'moviesRef');
      expect(d.schemaClass, 'MoviesSchema');
      expect(d.collections.map((c) => (c.type, c.path, c.name)), [
        ('Movie', 'movies', 'movies'),
        ('Comment', 'movies/*/comments', 'comments'),
      ]);
    });

    test('the model file becomes a schema and annotated models', () {
      final out = migrate(movieFile);
      expect(
        out,
        contains("import 'package:firestore_odm/firestore_odm.dart';"),
      );
      expect(out, isNot(contains('cloud_firestore_odm')));
      expect(out, contains('class MoviesSchema extends FirestoreSchema'));
      expect(
        out,
        contains(
          "@Schema()\n@Collection<Movie>('movies')\n"
          "@Collection<Comment>('movies/*/comments')\n"
          'const moviesSchema = MoviesSchema();',
        ),
      );
      expect(out, contains('final moviesOdm = FirestoreODM(moviesSchema);'));
      expect(out, contains('final moviesRef = moviesOdm.movies;'));
      expect(out, contains('@firestoreOdm\nclass Movie {'));
      expect(out, contains('@firestoreOdm\nclass Comment {'));
      expect(out, contains('@DocumentIdField()\n  final String id;'));
      expect(out, contains('@Min(0)'));
      expect(out, isNot(contains(r'_$assertMovie')));
      expect(out, isNot(contains('line ')));
    });

    test('migrating twice changes nothing more', () {
      final once = migrate(movieFile);
      expect(migrateDartSource(once, declarations).changed, isFalse);
    });
  });

  group('queries', () {
    test('whereX becomes a typed where', () {
      expect(
        migrate(
          'moviesRef.whereLikes(isGreaterThan: 10).whereTitle(isEqualTo: t)',
        ),
        r'moviesRef.where(($) => $.likes(isGreaterThan: 10))'
        r'.where(($) => $.title(isEqualTo: t))',
      );
      expect(
        migrate('q.whereDocumentId(whereIn: ids)'),
        r'q.where(($) => $.documentId(whereIn: ids))',
      );
    });

    test('chained orderByX calls become one orderBy with cursors', () {
      expect(
        migrate('moviesRef.orderByLikes(descending: true).limit(10)'),
        r'moviesRef.orderBy(($) => ($.likes(descending: true),)).limit(10)',
      );
      expect(
        migrate(
          'moviesRef\n    .orderByLikes(startAfter: 5)\n'
          '    .orderByTitle(descending: true, startAfter: last.title)',
        ),
        'moviesRef\n    '
        r'.orderBy(($) => ($.likes(), $.title(descending: true)))'
        '.startAfter((5, last.title))',
      );
    });

    test('field-path escape hatches are left for a person', () {
      const source = "q.whereFieldPath(FieldPath.documentId, isEqualTo: 'a')";
      final result = migrateDartSource(source, declarations);
      expect(result.source, source);
      expect(result.followUps.single.message, contains('string field paths'));
    });
  });

  group('writes and references', () {
    test('named update becomes patch with FieldValue ops', () {
      expect(
        migrate(
          'moviesRef.doc(id).update(title: t, '
          'likesFieldValue: FieldValue.increment(1), '
          "tagsFieldValue: FieldValue.arrayUnion(['a']))",
        ),
        r"moviesRef.doc(id).patch(($) => [$.title.set(t), "
        r"$.likes.increment(1), $.tags.arrayUnion(['a'])])",
      );
    });

    test('a positional update (raw cloud_firestore) is untouched', () {
      const source = "doc.update({'likes': 1})";
      expect(migrate(source), source);
    });

    test('subcollections, add and snapshots follow the reference', () {
      expect(
        migrate('moviesRef.doc(movie.id).comments.snapshots()'),
        'moviesOdm.moviesComments(movie.id).stream',
      );
      final result = migrateDartSource(
        'await moviesRef.add(movie);',
        declarations,
      );
      expect(result.source, 'await moviesRef.create(movie);');
      expect(result.followUps.single.message, contains('returns the new'));
    });

    test('other snapshots() calls are untouched', () {
      const source = "FirebaseFirestore.instance.doc('a/b').snapshots()";
      expect(migrate(source), source);
    });

    test('a transaction helper is reported by line', () {
      final result = migrateDartSource(
        'void f() {\n'
        '  moviesRef.doc(id).transactionUpdate(tx, likes: 1);\n'
        '}\n',
        declarations,
      );
      expect(result.followUps.single.line, 2);
      expect(result.followUps.single.message, contains('transaction/batch'));
    });

    test('FirestoreBuilder keeps working, with the model payload type', () {
      final result = migrateDartSource(
        'void f() {\n'
        '  FirestoreBuilder<MovieQuerySnapshot>(ref: moviesRef);\n'
        '  FirestoreBuilder<CommentDocumentSnapshot>(ref: commentsRef);\n'
        '}\n',
        declarations,
      );
      expect(
        result.source,
        contains('FirestoreBuilder<List<Movie>>(ref: moviesRef);'),
      );
      expect(
        result.source,
        contains('FirestoreBuilder<Comment?>(ref: commentsRef);'),
      );
      expect(result.followUps, isEmpty);
    });

    test('a snapshot type the project does not declare is reported', () {
      final result = migrateDartSource(
        'FirestoreBuilder<FooQuerySnapshot>(ref: query);',
        declarations,
      );
      expect(result.source, contains('FirestoreBuilder<FooQuerySnapshot>'));
      expect(result.followUps.single.line, 1);
      expect(result.followUps.single.message, contains('model payload'));
    });
  });

  group('class-level @Collection (cloud_firestore_odm 1.0 style)', () {
    const eventFile = r"""
import 'package:cloud_firestore_odm/cloud_firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

@Collection<EventDto>('events')
@freezed
class EventDto with _$EventDto {
  factory EventDto({@Id() required String id}) = _EventDto;
}

final eventDtoRef = EventDtoCollectionReference();
""";

    test('the annotation moves into a schema at the end of the file', () {
      final d = collectDeclarations(eventFile);
      expect(d.first.classLevel, isTrue);
      final out = migrateDartSource(eventFile, d).source;
      expect(out, isNot(contains("@Collection<EventDto>('events')\n@freezed")));
      expect(out, contains('@freezed\n@firestoreOdm\nclass EventDto'));
      expect(out, contains('class EventDtoSchema extends FirestoreSchema'));
      expect(
        out,
        contains(
          "@Schema()\n@Collection<EventDto>('events')\n"
          'const eventDtoSchema = EventDtoSchema();',
        ),
      );
      expect(
        out,
        contains('final eventDtoOdm = FirestoreODM(eventDtoSchema);'),
      );
      expect(out, contains('final eventDtoRef = eventDtoOdm.events;'));
    });

    test('a multi-line annotation chain before the class is recognised', () {
      const source = """
@Collection<A>('as')
@JsonSerializable(
  explicitToJson: true,
)
class A {}
""";
      final out = migrate1(source);
      expect(out, startsWith('@JsonSerializable('));
      expect(out, contains("@Collection<A>('as')\nconst aSchema"));
    });

    test('migrating twice changes nothing more', () {
      final d = collectDeclarations(eventFile);
      final once = migrateDartSource(eventFile, d).source;
      expect(
        migrateDartSource(once, collectDeclarations(once)).changed,
        isFalse,
      );
    });
  });

  group('directly constructed references', () {
    final decls = collectDeclarations(r"""
@Collection<EventDto>('events')
class EventDto {}
""");

    String run(String source) => migrateDartSource(source, decls).source;

    test('XCollectionReference(firestore) uses that Firestore instance', () {
      expect(
        run('final events = EventDtoCollectionReference(_firestore);'),
        'final events = FirestoreODM(eventDtoSchema, firestore: _firestore)'
        '.events;',
      );
    });

    test('a multi-line constructor call is rewritten', () {
      expect(
        run('final c = EventDtoCollectionReference(\n  _firestore,\n);'),
        'final c = FirestoreODM(eventDtoSchema, firestore: _firestore)'
        '.events;',
      );
    });

    test('XCollectionReference() uses the schema ODM', () {
      expect(
        run('final c = EventDtoCollectionReference();'),
        'final c = eventDtoOdm.events;',
      );
    });

    test('call chains on the local variable follow the rewrite', () {
      expect(
        run(
          'void f() {\n'
          '  final events = EventDtoCollectionReference(db);\n'
          '  events.whereTitle(isEqualTo: t).snapshots().listen(print);\n'
          '  events.add(e);\n'
          '}\n',
        ),
        'void f() {\n'
        '  final events = FirestoreODM(eventDtoSchema, firestore: db).events;\n'
        r'  events.where(($) => $.title(isEqualTo: t)).stream.listen(print);'
        '\n  events.create(e);\n}\n',
      );
    });

    test('a native snapshots() call elsewhere is untouched', () {
      const source = 'void f() {\n  other.snapshots();\n}\n';
      expect(run(source), source);
    });
  });

  group('generated types the codemod cannot rewrite are reported', () {
    final decls = collectDeclarations(r"""
@Collection<User>('users')
@Collection<Post>('users/*/posts')
final usersRef = UserCollectionReference();
""");

    List<String> reports(String source) => [
      for (final f in migrateDartSource(source, decls).followUps)
        '${f.line}: ${f.message.split(':').first}',
    ];

    test('document reference types and constructors', () {
      expect(
        reports(
          'UserDocumentReference r(String id) =>\n'
          '    UserDocumentReference(usersRef.doc(id).reference);',
        ),
        [
          '1: generated document reference type',
          '2: .reference',
          '2: generated document reference type',
        ],
      );
    });

    test('subcollection references and collection types', () {
      expect(
        reports(
          'PostCollectionReference p(DocumentReference d) =>\n'
          '    PostCollectionReference(d);',
        ),
        [
          '1: generated collection reference the codemod could not rewrite',
          '2: generated collection reference the codemod could not rewrite',
        ],
      );
      expect(reports('UserCollectionReference c;'), [
        '1: generated collection reference the codemod could not rewrite',
      ]);
    });

    test('snapshot types outside FirestoreBuilder', () {
      expect(reports('void f(UserQueryDocumentSnapshot s) {}'), [
        '1: generated snapshot type',
      ]);
      expect(
        reports('FirestoreBuilder<UserQuerySnapshot>(ref: usersRef);'),
        isEmpty,
      );
    });
  });

  group('pubspec', () {
    test('swaps packages and raises Firebase majors', () {
      const pubspec = '''
dependencies:
  cloud_firestore: ^5.4.0
  cloud_firestore_odm: ^1.0.0-dev.88
  firebase_core: ^3.6.0
  json_annotation: ^4.8.1
dev_dependencies:
  cloud_firestore_odm_generator: ^1.0.0-dev.88
  json_serializable: ^6.8.0
''';
      expect(migratePubspec(pubspec), '''
dependencies:
  cloud_firestore: ^6.4.0
  firestore_odm: $firestoreOdmConstraint
  firebase_core: ^4.0.0
  json_annotation: ^4.8.1
dev_dependencies:
  firestore_odm_builder: $firestoreOdmConstraint
  json_serializable: ^6.8.0
''');
    });

    test('current Firebase constraints are kept', () {
      const pubspec = 'dependencies:\n  cloud_firestore: ^6.10.0\n';
      expect(migratePubspec(pubspec), pubspec);
    });
  });

  test('accessor names match the builder', () {
    expect(collectionAccessor('firestore-example-app'), 'firestoreExampleApp');
    expect(collectionAccessor('user_profiles'), 'userProfiles');
    expect(
      subcollectionAccessor('users/*/posts/*/comments'),
      'usersPostsComments',
    );
  });
}
