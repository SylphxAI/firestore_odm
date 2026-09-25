import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/comment.dart';
import 'package:flutter_example/models/dart_immutable_user.dart';
import 'package:flutter_example/models/defaulted_nested_test.dart';
import 'package:flutter_example/models/enum_models.dart';
import 'package:flutter_example/models/json_key_user.dart';
import 'package:flutter_example/models/manual_user.dart';
import 'package:flutter_example/models/manual_user2.dart';
import 'package:flutter_example/models/manual_user3.dart';
import 'package:flutter_example/models/nullable_types_test.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/shared_post.dart';
import 'package:flutter_example/models/simple_generic.dart';
import 'package:flutter_example/models/simple_story.dart';
import 'package:flutter_example/models/task.dart';
import 'package:flutter_example/models/user.dart';

part 'test_schema.g.dart';

/// The schema class for this example app. Declared by hand so the schema
/// variable's type is resolvable before code generation (ADR-0002).
class TestSchema extends FirestoreSchema {
  const TestSchema();
}

/// Test schema that includes all collections used in existing tests.
@Schema()
@Collection<User>('users')
@Collection<Post>('posts')
@Collection<Post>('users/*/posts') // User subcollection
@Collection<User>(
  'users2',
) // Second User collection without posts subcollection
@Collection<Comment>('comments') // Root comments collection
@Collection<Comment>('posts/*/comments') // Comments on posts in main collection
@Collection<Comment>(
  'users/*/posts/*/comments',
) // Nested: comments on user posts
@Collection<SimpleStory>('simpleStories')
@Collection<SharedPost>('sharedPosts')
@Collection<SharedPost>('users/*/sharedPosts') // Subcollection path
@Collection<JsonKeyUser>('jsonKeyUsers') // JsonKey annotation test
@Collection<DartImmutableUser>('dartImmutableUsers') // Pure Dart immutable test
@Collection<ManualUser>('manualUsers') // Manual toJson/fromJson test
@Collection<ManualUser2>('manualUsers2') // Without toJson/fromJson test
@Collection<ManualUser3<ManualUser3Profile<Book>>>(
  'manualUsers3',
) // Complicated generic without toJson/fromJson
@Collection<ManualUser3<ManualUser3Profile<String>>>(
  'manualUsers3Strings',
) // Generic with different type parameter
@Collection<Task>('tasks') // Duration field test
@Collection<StringGeneric>('stringGenerics') // Generic collection test
@Collection<IntGeneric>('intGenerics') // Generic collection test
@Collection<User>('snake_case_users') // Snake_case to camelCase test
@Collection<Post>('snake_case_users/*/user_posts') // Snake_case subcollection
@Collection<Comment>(
  'snake_case_users/*/user_posts/*/post_comments',
) // Nested snake_case subcollection
@Collection<EnumUser>('enumUsers') // Enum + JsonValue test
@Collection<EnumTask>('enumTasks') // Enum with numeric @JsonValue test
@Collection<SimpleEnumTask>('simpleEnumTasks') // Enum orderBy support
@Collection<NullableTypesTestModel>('nullableTypesTests') // Nullable types test
@Collection<NestedData>('nestedData') // Nested data for issue #3 testing
@Collection<OrderWithDefault>('orderWithDefaults') // Issue #5 nullable-input
const TestSchema testSchema = TestSchema();
