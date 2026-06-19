/// Regression test for GitHub Issue #5:
/// https://github.com/SylphxAI/firestore_odm/issues/5
///
/// The generated `$ModelFromJson` must use a **nullable** cast for a nested
/// object field whose `fromJson` factory accepts a nullable map — even when the
/// parent field is non-nullable with a default. Otherwise, reading a Firestore
/// document that predates the field crashes with:
///   type 'Null' is not a subtype of type 'Map<String, Object?>' in type cast
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/defaulted_nested_test.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreODM<TestSchema> db;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    db = FirestoreODM(testSchema, firestore: firestore);
  });

  group('Issue #5: nullable-input fromJson on non-nullable nested field', () {
    test(
      'reads a legacy document missing the nested field without crashing',
      () async {
        // Simulate a document created before `shippingAddress` existed: write
        // raw data directly, bypassing the ODM's toJson so the field is absent.
        await firestore.collection('orderWithDefaults').doc('legacy').set({
          'productId': 'p1',
        });

        final result = await db.orderWithDefaults('legacy').get();

        expect(result, isNotNull);
        expect(result!.productId, equals('p1'));
        // The nullable-aware cast lets DefaultedAddress.fromJson(null) return
        // the default instance instead of throwing.
        expect(result.shippingAddress.street, equals(''));
        expect(result.shippingAddress.city, equals(''));
      },
    );

    test('reads a document with an explicit null nested field', () async {
      await firestore.collection('orderWithDefaults').doc('explicitNull').set({
        'productId': 'p2',
        'shippingAddress': null,
      });

      final result = await db.orderWithDefaults('explicitNull').get();

      expect(result, isNotNull);
      expect(result!.shippingAddress.street, equals(''));
      expect(result.shippingAddress.city, equals(''));
    });

    test('round-trips a populated nested field', () async {
      const order = OrderWithDefault(
        id: 'full',
        productId: 'p3',
        shippingAddress: DefaultedAddress(
          street: '1 Main St',
          city: 'Metropolis',
        ),
      );

      await db.orderWithDefaults.insert(order);
      final result = await db.orderWithDefaults('full').get();

      expect(result, isNotNull);
      expect(result!.productId, equals('p3'));
      expect(result.shippingAddress.street, equals('1 Main St'));
      expect(result.shippingAddress.city, equals('Metropolis'));
    });

    test(
      'uses the constructor default when inserted without an address',
      () async {
        const order = OrderWithDefault(id: 'defaulted', productId: 'p4');

        await db.orderWithDefaults.insert(order);
        final result = await db.orderWithDefaults('defaulted').get();

        expect(result, isNotNull);
        expect(result!.shippingAddress.street, equals(''));
        expect(result.shippingAddress.city, equals(''));
      },
    );
  });
}
