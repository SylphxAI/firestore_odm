/// The [FirestoreBuilder] widget: builds from a typed reference and rebuilds
/// on every change, without restarting the listener.
///
/// This is the replacement for `cloud_firestore_odm`'s widget of the same
/// name. It listens to the reference's `stream` instead of snapshot
/// wrappers, so `snapshot.data` is your model (`List<T>` for a collection or
/// query, `T?` for a document).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// A typed reference whose latest value can be watched: something a
/// [FirestoreBuilder] can listen to.
///
/// The ODM's collection, query and document handles implement it
/// ([FirestoreCollection], [Query], [OrderedQuery], [FirestoreDocument]), so
/// any of them can be passed as `ref`.
abstract interface class FirestoreListenable<Snapshot> {
  /// A live stream of the current value at this reference.
  ///
  /// Reading it starts a new listener; [FirestoreBuilder] reads it once per
  /// reference and keeps that subscription across rebuilds.
  Stream<Snapshot> get stream;

  /// The native Firestore reference behind this handle.
  ///
  /// Two handles that point at the same document or query return equal
  /// objects, which is how [FirestoreBuilder] tells whether `ref` still
  /// watches the same place — a reference rebuilt on every `build`, such as
  /// from `odm.users.where(...)`, reuses the listener instead of billing a
  /// second one.
  Object get nativeReference;
}

/// Listens to a typed reference and builds a widget from its latest value.
///
/// ```dart
/// FirestoreBuilder<List<Movie>>(
///   ref: odm.movies.where(($) => $.likes(isGreaterThan: 100)),
///   builder: (context, snapshot, child) {
///     if (snapshot.hasError) return Text('${snapshot.error}');
///     if (!snapshot.hasData) return const CircularProgressIndicator();
///     return MovieList(snapshot.data!);
///   },
/// );
/// ```
///
/// `snapshot` is an [AsyncSnapshot]: `ConnectionState.waiting` until the
/// first value arrives, then `ConnectionState.active` for values and errors.
/// [child] is passed through to [builder] unchanged, for a subtree that does
/// not depend on the reference.
class FirestoreBuilder<Snapshot> extends StatefulWidget {
  /// Creates a builder that listens to [ref].
  const FirestoreBuilder({
    super.key,
    required this.ref,
    required this.builder,
    this.child,
  });

  /// The listened reference.
  final FirestoreListenable<Snapshot> ref;

  /// Called with the latest snapshot from [ref].
  final Widget Function(
    BuildContext context,
    AsyncSnapshot<Snapshot> snapshot,
    Widget? child,
  )
  builder;

  /// An optional child for the part of the tree that does not depend on
  /// [ref]; it is not rebuilt when [ref] emits.
  final Widget? child;

  @override
  State<FirestoreBuilder<Snapshot>> createState() =>
      _FirestoreBuilderState<Snapshot>();
}

class _FirestoreBuilderState<Snapshot>
    extends State<FirestoreBuilder<Snapshot>> {
  Object? _streamCacheKey;
  Stream<Snapshot>? _streamCache;

  /// The stream for the current reference, created once per reference.
  Stream<Snapshot> get _stream {
    final nativeReference = widget.ref.nativeReference;
    if (nativeReference == _streamCacheKey) return _streamCache!;
    _streamCacheKey = nativeReference;
    return _streamCache = widget.ref.stream;
  }

  AsyncSnapshot<Snapshot> _snapshot = AsyncSnapshot<Snapshot>.nothing();
  Stream<Snapshot>? _listenedStream;
  StreamSubscription<Snapshot>? _subscription;

  void _listen(Stream<Snapshot> stream) {
    if (stream == _listenedStream) return;

    _subscription?.cancel();
    _listenedStream = stream;
    // Keep the last value (as StreamBuilder does) so a rebuild does not flash
    // an empty state while the new stream delivers its first event.
    _setSnapshot(_snapshot.inState(ConnectionState.waiting));
    _subscription = stream.listen(
      (event) => _setSnapshot(
        AsyncSnapshot<Snapshot>.withData(ConnectionState.active, event),
      ),
      onError: (Object error, StackTrace stackTrace) => _setSnapshot(
        AsyncSnapshot<Snapshot>.withError(
          ConnectionState.active,
          error,
          stackTrace,
        ),
      ),
    );
  }

  void _setSnapshot(AsyncSnapshot<Snapshot> snapshot) {
    _snapshot = snapshot;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _listen(_stream);
  }

  @override
  void didUpdateWidget(covariant FirestoreBuilder<Snapshot> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _listen(_stream);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _snapshot, widget.child);
}
