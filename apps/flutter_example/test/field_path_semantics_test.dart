/// Native FieldPath component boundaries are part of the v5 contract.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('patch maps retain literal dots in field components', () {
    final field = FieldNode(components: ['profile', 'v2.x']);
    final update = operationsToMap([SetOperation(field, 'value')]);
    final key = update.keys.single;

    expect(key, isA<FieldPath>());
    expect((key as FieldPath).components, ['profile', 'v2.x']);
  });

  test('typed filters retain literal dots in field components', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('docs').doc('match').set({
      'profile': {'v2.x': 'value'},
    });
    await firestore.collection('docs').doc('miss').set({
      'profile': {
        'v2': {'x': 'value'},
      },
    });

    final field = FilterField<String, String>(
      field: FieldNode(components: ['profile', 'v2.x']),
      toJson: (value) => value,
    );
    final result = await QueryFilterHandler.applyFilter(
      firestore.collection('docs'),
      field(isEqualTo: 'value'),
    ).get();

    expect(result.docs.map((doc) => doc.id).toList(), ['match']);
  });
}
