/// Subcollection accessors are path-derived methods with parent args:
/// 'users/*/posts' -> usersPosts(String userId) (ADR-0002).
library;

import 'package:flutter_example/models/comment.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('usersPosts accesses a per-user subcollection', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'alice'));
    final posts = odm.usersPosts('alice');
    final post = samplePost(id: 'p1', author: 'alice');
    await posts.set(post);

    final read = await posts('p1').get();
    expect(read?.authorId, 'alice');
    expect((await posts.get()).single.title, 'Post p1');
  });

  test('deep nesting: usersPostsComments', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'alice'));
    await odm.usersPosts('alice').set(samplePost(id: 'p1', author: 'alice'));
    final comments = odm.usersPostsComments('alice', 'p1');
    await comments.set(
      Comment(
        id: 'c1',
        content: 'hello',
        authorId: 'alice',
        authorName: 'Alice',
        postId: 'p1',
        createdAt: DateTime.utc(2026, 3, 1),
      ),
    );
    expect((await comments('c1').get())?.content, 'hello');
  });

  test('root and subcollection accessors coexist without ambiguity', () async {
    final (_, odm) = newDb();
    await odm.posts.set(samplePost(id: 'root-post'));
    await odm.users.set(sampleUser(id: 'u'));
    await odm.usersPosts('u').set(samplePost(id: 'sub-post'));
    expect((await odm.posts('root-post').get())?.id, 'root-post');
    expect((await odm.usersPosts('u')('sub-post').get())?.id, 'sub-post');
  });
}
