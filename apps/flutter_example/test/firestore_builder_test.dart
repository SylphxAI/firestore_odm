/// The `FirestoreBuilder` widget: states, ref changes, and listener reuse.
library;

import 'dart:async';

import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A [FirestoreListenable] that hands out a new stream per read, so a test
/// can count how often the widget subscribes.
class _CountingRef implements FirestoreListenable<List<String>> {
  _CountingRef(this.nativeReference);

  @override
  final Object nativeReference;

  /// How many times `stream` was read.
  int reads = 0;

  /// Subscriptions started on the streams handed out.
  int listens = 0;

  /// Subscriptions cancelled.
  int cancels = 0;

  final _controllers = <StreamController<List<String>>>[];

  @override
  Stream<List<String>> get stream {
    reads++;
    final controller = StreamController<List<String>>(
      onListen: () => listens++,
      onCancel: () => cancels++,
    );
    _controllers.add(controller);
    return controller.stream;
  }

  /// Emits [value] on the stream the widget listens to.
  void emit(List<String> value) => _controllers.last.add(value);

  /// Emits [error] on the stream the widget listens to.
  void fail(Object error) => _controllers.last.addError(error);
}

/// Builds a `FirestoreBuilder` over [ref] and records every snapshot it sees.
Widget recorder(
  FirestoreListenable<List<String>> ref,
  List<AsyncSnapshot<List<String>>> snapshots, {
  Widget? child,
}) => FirestoreBuilder<List<String>>(
  ref: ref,
  child: child,
  builder: (context, snapshot, child) {
    snapshots.add(snapshot);
    return Text(
      snapshot.hasData ? 'data:${snapshot.data!.join(',')}' : 'no-data',
    );
  },
);

/// Pumps [widget] under a `Directionality`, as a real app would.
Future<void> pumpApp(WidgetTester tester, Widget widget) => tester.pumpWidget(
  Directionality(textDirection: TextDirection.ltr, child: widget),
);

/// Lets a queued stream event reach the widget, then draws the frame it
/// scheduled.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  group('over a real reference', () {
    testWidgets('a collection starts waiting, then shows the models', (
      tester,
    ) async {
      final (_, odm) = newDb();
      final snapshots = <AsyncSnapshot<List<User>>>[];
      await pumpApp(
        tester,
        FirestoreBuilder<List<User>>(
          ref: odm.users,
          builder: (context, snapshot, child) {
            snapshots.add(snapshot);
            if (!snapshot.hasData) return const Text('waiting');
            return Text('users:${snapshot.data!.map((u) => u.id).join(',')}');
          },
        ),
      );

      expect(snapshots.first.connectionState, ConnectionState.waiting);
      expect(find.text('waiting'), findsOneWidget);

      await tester.runAsync(() async {
        await odm.users.set(sampleUser(id: 'u1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(snapshots.last.connectionState, ConnectionState.active);
      expect(find.text('users:u1'), findsOneWidget);

      await tester.runAsync(() async {
        await odm.users.set(sampleUser(id: 'u2'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(find.text('users:u1,u2'), findsOneWidget);
    });

    testWidgets('a document emits null while it is missing', (tester) async {
      final (_, odm) = newDb();
      final snapshots = <AsyncSnapshot<User?>>[];
      await pumpApp(
        tester,
        FirestoreBuilder<User?>(
          ref: odm.users('u1'),
          builder: (context, snapshot, child) {
            snapshots.add(snapshot);
            return Text(snapshot.data?.name ?? 'missing');
          },
        ),
      );

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(snapshots.last.data, isNull);
      expect(snapshots.last.connectionState, ConnectionState.active);
      expect(find.text('missing'), findsOneWidget);

      await tester.runAsync(() async {
        await odm.users.set(sampleUser(id: 'u1'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(snapshots.last.data?.id, 'u1');
      expect(find.text('User u1'), findsOneWidget);
    });

    testWidgets('rebuilding with the same reference keeps the value', (
      tester,
    ) async {
      final (_, odm) = newDb();
      final snapshots = <AsyncSnapshot<User?>>[];
      Future<void> show() => pumpApp(
        tester,
        FirestoreBuilder<User?>(
          ref: odm.users('u1'),
          builder: (context, snapshot, child) {
            snapshots.add(snapshot);
            return const SizedBox();
          },
        ),
      );

      await tester.runAsync(() => odm.users.set(sampleUser(id: 'u1')));
      await show();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(snapshots.last.connectionState, ConnectionState.active);
      expect(snapshots.last.data?.id, 'u1');

      // A new handle for the same document: the widget keeps its listener, so
      // it does not fall back to the waiting state.
      await show();
      expect(snapshots.last.connectionState, ConnectionState.active);
      expect(snapshots.last.data?.id, 'u1');
    });

    testWidgets('a new reference keeps the old value while it loads', (
      tester,
    ) async {
      final (_, odm) = newDb();
      final snapshots = <AsyncSnapshot<User?>>[];
      await tester.runAsync(() async {
        await odm.users.set(sampleUser(id: 'u1'));
        await odm.users.set(sampleUser(id: 'u2'));
      });
      Future<void> show(String id) => pumpApp(
        tester,
        FirestoreBuilder<User?>(
          ref: odm.users(id),
          builder: (context, snapshot, child) {
            snapshots.add(snapshot);
            return Text(snapshot.data?.id ?? 'missing');
          },
        ),
      );

      await show('u1');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.text('u1'), findsOneWidget);

      await show('u2');
      // Still showing u1's value, now in the waiting state.
      expect(snapshots.last.connectionState, ConnectionState.waiting);
      expect(snapshots.last.data?.id, 'u1');
      expect(find.text('u1'), findsOneWidget);

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.text('u2'), findsOneWidget);
    });
  });

  group('with a countable reference', () {
    testWidgets('the stream is read once and kept across rebuilds', (
      tester,
    ) async {
      final identity = Object();
      final ref = _CountingRef(identity);
      final snapshots = <AsyncSnapshot<List<String>>>[];

      await pumpApp(tester, recorder(ref, snapshots));
      expect(ref.reads, 1);
      expect(ref.listens, 1);

      ref.emit(['a']);
      await settle(tester);
      expect(find.text('data:a'), findsOneWidget);

      // A second handle over the same native reference: same listener.
      final rebuilt = _CountingRef(identity);
      await pumpApp(tester, recorder(rebuilt, snapshots));
      expect(rebuilt.reads, 0);
      expect(ref.cancels, 0);
      expect(find.text('data:a'), findsOneWidget);

      // A different native reference: the old listener is cancelled and the
      // new stream is read.
      final other = _CountingRef(Object());
      await pumpApp(tester, recorder(other, snapshots));
      await settle(tester);
      expect(other.reads, 1);
      expect(ref.cancels, 1);

      other.emit(['b']);
      await settle(tester);
      expect(find.text('data:b'), findsOneWidget);
    });

    testWidgets('disposing cancels the subscription', (tester) async {
      final ref = _CountingRef(Object());
      await pumpApp(tester, recorder(ref, []));
      expect(ref.listens, 1);

      await pumpApp(tester, const SizedBox());
      await settle(tester);

      expect(ref.cancels, 1);
    });

    testWidgets('an error arrives as an error snapshot', (tester) async {
      final ref = _CountingRef(Object());
      final snapshots = <AsyncSnapshot<List<String>>>[];
      await pumpApp(
        tester,
        FirestoreBuilder<List<String>>(
          ref: ref,
          builder: (context, snapshot, child) {
            snapshots.add(snapshot);
            return Text(snapshot.hasError ? 'error:${snapshot.error}' : 'ok');
          },
        ),
      );

      ref.fail(StateError('boom'));
      await settle(tester);

      expect(snapshots.last.hasError, isTrue);
      expect(snapshots.last.error, isA<StateError>());
      expect(snapshots.last.connectionState, ConnectionState.active);
      expect(find.textContaining('error:'), findsOneWidget);
    });

    testWidgets('child is passed through untouched', (tester) async {
      final child = Container(key: const Key('child'));
      Widget? seen;
      await pumpApp(
        tester,
        FirestoreBuilder<List<String>>(
          ref: _CountingRef(Object()),
          child: child,
          builder: (context, snapshot, child) {
            seen = child;
            return child ?? const SizedBox();
          },
        ),
      );

      expect(seen, same(child));

      // The child keeps its element across a rebuild of the builder.
      final element = tester.element(find.byKey(const Key('child')));
      await pumpApp(
        tester,
        FirestoreBuilder<List<String>>(
          ref: _CountingRef(Object()),
          child: child,
          builder: (context, snapshot, child) => child ?? const SizedBox(),
        ),
      );
      expect(tester.element(find.byKey(const Key('child'))), same(element));
    });
  });
}
