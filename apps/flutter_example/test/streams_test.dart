/// Document and query streams.
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('collection stream emits document lists', () async {
    final (_, odm) = newDb();
    final emitted = <List<User>>[];
    final sub = odm.users.stream.listen(emitted.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await odm.users.set(sampleUser(id: 'u1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emitted, isNotEmpty);
    expect(emitted.last.map((u) => u.id), contains('u1'));
  });

  test(
    'document stream emits null when missing and data when present',
    () async {
      final (_, odm) = newDb();
      final emitted = <User?>[];
      final sub = odm.users('u1').stream.listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await odm.users.set(sampleUser(id: 'u1'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(emitted, contains(null));
      expect(emitted.any((u) => u?.id == 'u1'), isTrue);
    },
  );
}
