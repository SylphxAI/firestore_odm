/// Multiple schemas coexist without interference.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/secondary_schema.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('two schemas on the same Firestore instance', () async {
    final fake = FakeFirebaseFirestore();
    final primary = FirestoreODM(testSchema, firestore: fake);
    final secondary = FirestoreODM(secondarySchema, firestore: fake);

    await primary.users.set(sampleUser(id: 'u1'));
    await secondary.secondaryUsers.set(sampleUser(id: 'u2'));

    expect((await primary.users('u1').get())?.id, 'u1');
    expect((await secondary.secondaryUsers('u2').get())?.id, 'u2');
    // Separate collections: primary 'users' does not contain u2.
    expect(await primary.users('u2').get(), isNull);
    expect(await secondary.secondaryUsers('u1').get(), isNull);
  });

  test('secondary schema subcollections', () async {
    final fake = FakeFirebaseFirestore();
    final secondary = FirestoreODM(secondarySchema, firestore: fake);
    await secondary.secondaryUsers.set(sampleUser(id: 'u'));
    await secondary
        .secondaryUsersUserPosts('u')
        .set(samplePost(id: 'p', author: 'u'));
    expect((await secondary.secondaryUsersUserPosts('u')('p').get())?.id, 'p');
  });
}
