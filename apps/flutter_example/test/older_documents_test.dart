/// Reading documents written before a field existed, or by another client.
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('missing fields take the model defaults', () async {
    final (fake, odm) = newDb();
    await fake.doc('users/old').set({
      'name': 'Old',
      'email': 'old@example.com',
      'age': 40,
      'profile': {
        'bio': 'b',
        'avatar': 'a',
        'socialLinks': <String, String>{},
        'interests': <String>[],
      },
    });
    final user = await odm.users('old').get();
    expect(user?.tags, isEmpty);
    expect(user?.rating, 0.0);
    expect(user?.isActive, isFalse);
    expect(user?.profile.followers, 0);
    expect(user?.lastLogin, isNull);
  });

  test('a whole number stored in a double field reads as double', () async {
    final (fake, odm) = newDb();
    await odm.users.set(sampleUser(id: 'u1'));
    await fake.doc('users/u1').update({'rating': 4});
    expect((await odm.users('u1').get())?.rating, 4.0);
  });
}
