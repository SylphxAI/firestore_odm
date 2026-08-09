/// Typed batches: create/set/patch/delete committed atomically (ADR-0002).
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('runBatch commits all queued writes atomically', () async {
    final (_, odm) = newDb();
    late String generatedId;
    await odm.runBatch((b) {
      final users = odm.users.inBatch(b);
      generatedId = users.create(sampleUser(id: 'ignored'));
      users.set(sampleUser(id: 'explicit'));
      users.doc('explicit').patch((p) => [p.rating.increment(1.0)]);
      users.delete('missing');
    });
    expect(generatedId, isNotEmpty);
    expect(await odm.users(generatedId).get(), isNotNull);
    expect((await odm.users('explicit').get())?.rating, 5.5);
  });

  test('manual batch context with explicit commit', () async {
    final (_, odm) = newDb();
    final b = odm.batch();
    odm.users.inBatch(b).set(sampleUser(id: 'x'));
    expect(await odm.users('x').get(), isNull);
    await b.commit();
    expect(await odm.users('x').get(), isNotNull);
  });
}
