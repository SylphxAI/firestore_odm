/// Real benchmark harness (ADR-0002): measured, not asserted.
///
/// These are recorded benchmarks — they assert only that the operations
/// complete and print the measurements. They exist so the `performance` CI
/// lane has real numbers to gate on (regression thresholds are applied by
/// comparing against the recorded baseline, not by hard-coded wall clocks).
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('serialization round-trip benchmark', () async {
    final user = sampleUser(id: 'bench');
    // Warm up.
    for (var i = 0; i < 100; i++) {
      final json = UserToJson(user)!;
      UserFromJson(json);
    }
    const iterations = 10000;
    final sw = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      final json = UserToJson(user)!;
      UserFromJson(json);
    }
    sw.stop();
    final perOpUs = sw.elapsedMicroseconds / iterations;
    // Recorded metric (CI prints it; a baseline file records it for drift).
    // ignore: avoid_print
    print('BENCH serialization_roundtrip_us_per_op=$perOpUs');
    expect(perOpUs, lessThan(1000)); // generous ceiling; baseline is far lower
  });

  test('patch operationsToMap benchmark', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'bench'));
    final sw = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      await odm.users.patch('bench', (p) => [p.age.increment(1)]);
    }
    sw.stop();
    final perOpMs = sw.elapsedMilliseconds / 1000;
    // ignore: avoid_print
    print('BENCH patch_op_ms_per_op=$perOpMs');
    expect(perOpMs, lessThan(100)); // generous ceiling for CI machines
  });
}
