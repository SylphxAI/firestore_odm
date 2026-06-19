import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_example/models/enum_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enum + @JsonValue support', () {
    late FakeFirebaseFirestore fake;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fake = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fake);
    });

    test(
      'update/get should serialize enums using @JsonValue and defaults',
      () async {
        final u = EnumUser(
          id: 'e1',
          name: 'Alice',
          accountType: AccountType.pro, // @JsonValue('pro')
          // plan default = AccountType.free
        );

        await odm.enumUsers(u.id).update(u);

        final raw = await fake.collection('enumUsers').doc(u.id).get();
        final data = raw.data()!;
        expect(data['accountType'], 'pro'); // uses @JsonValue
        // plan default should be serialized as 'free'
        expect(data['plan'], 'free');

        final got = await odm.enumUsers(u.id).get();
        expect(got, isNotNull);
        expect(got!.accountType, AccountType.pro);
        expect(got.plan, AccountType.free);
        expect(got.optional, isNull);
      },
    );

    test('patch should serialize enum fields correctly', () async {
      await fake.collection('enumUsers').doc('e2').set(<String, dynamic>{
        'name': 'Bob',
        'accountType': 'free',
        'plan': 'free',
      });

      await odm
          .enumUsers('e2')
          .patch(
            ($) => [
              $.accountType(AccountType.enterprise), // 'enterprise'
              $.optional(AccountType.pro), // 'pro'
            ],
          );

      final raw = await fake.collection('enumUsers').doc('e2').get();
      final data = raw.data()!;
      expect(data['accountType'], 'enterprise');
      expect(data['optional'], 'pro');

      final got = await odm.enumUsers('e2').get();
      expect(got, isNotNull);
      expect(got!.accountType, AccountType.enterprise);
      expect(got.optional, AccountType.pro);
    });
  });
}
