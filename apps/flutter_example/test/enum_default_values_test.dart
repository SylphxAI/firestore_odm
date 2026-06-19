import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_example/models/enum_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enum default values handling', () {
    late FakeFirebaseFirestore fake;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fake = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fake);
    });

    test(
      'should apply constructor defaults when enum fields are missing from JSON',
      () async {
        // Store raw data without the plan field (should default to AccountType.free)
        await fake.collection('enumUsers').doc('default_test').set(
          <String, dynamic>{
            'id': 'default_test',
            'name': 'Default User',
            'accountType': 'pro', // Explicitly set this one
            // plan field is missing - should default to AccountType.free
            // optional field is missing - should be null
          },
        );

        final user = await odm.enumUsers('default_test').get();

        expect(user, isNotNull);
        expect(user!.id, 'default_test');
        expect(user.name, 'Default User');
        expect(user.accountType, AccountType.pro);
        expect(user.plan, AccountType.free); // Should default to free
        expect(user.optional, isNull); // Should be null
      },
    );

    test('should handle partial updates with missing enum fields', () async {
      // First create a complete user
      final initialUser = EnumUser(
        id: 'partial_test',
        name: 'Initial User',
        accountType: AccountType.enterprise,
        plan: AccountType.pro,
        optional: AccountType.free,
      );

      await odm.enumUsers(initialUser.id).update(initialUser);

      // Now manually update with missing plan field to simulate partial data
      await fake.collection('enumUsers').doc('partial_test').update(
        <String, dynamic>{
          'name': 'Updated User',
          'accountType': 'free',
          // plan field intentionally omitted - should retain previous value
        },
      );

      final user = await odm.enumUsers('partial_test').get();

      expect(user, isNotNull);
      expect(user!.name, 'Updated User');
      expect(user.accountType, AccountType.free);
      expect(
        user.plan,
        AccountType.pro,
      ); // Should retain previous value (partial updates don't reset to defaults)
      expect(user.optional, AccountType.free); // Should retain previous value
    });

    test(
      'should apply defaults when reading data with missing enum fields',
      () async {
        // Store raw data with some enum fields missing entirely
        await fake.collection('enumUsers').doc('missing_fields').set(<
          String,
          dynamic
        >{
          'id': 'missing_fields',
          'name': 'Missing Fields User',
          'accountType': 'enterprise',
          // plan field is completely missing from stored data - should default
          // optional field is missing - should be null
        });

        final user = await odm.enumUsers('missing_fields').get();

        expect(user, isNotNull);
        expect(user!.id, 'missing_fields');
        expect(user.name, 'Missing Fields User');
        expect(user.accountType, AccountType.enterprise);
        expect(
          user.plan,
          AccountType.free,
        ); // Should default since missing from stored data
        expect(
          user.optional,
          isNull,
        ); // Should be null since missing and nullable
      },
    );

    test('should handle nullable enum fields correctly', () async {
      final user = EnumUser(
        id: 'nullable_test',
        name: 'Nullable Test',
        accountType: AccountType.pro,
        // plan will default to AccountType.free
        optional: null, // Explicitly null
      );

      await odm.enumUsers(user.id).update(user);

      final retrieved = await odm.enumUsers(user.id).get();

      expect(retrieved, isNotNull);
      expect(retrieved!.accountType, AccountType.pro);
      expect(retrieved.plan, AccountType.free);
      expect(retrieved.optional, isNull);
    });
  });
}
