import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/comment.dart';
import 'package:flutter_example/models/dart_immutable_user.dart';
import 'package:flutter_example/models/immutable_user.dart';
import 'package:flutter_example/models/json_key_user.dart';
import 'package:flutter_example/models/list_length_model.dart';
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
import 'package:flutter_example/models/enum_models.dart';

part 'test_schema.g.dart';

/// Test schema that includes all collections used in existing tests.
@Schema()
@Collection<User>('users')
@Collection<Post>('posts')
@Collection<Post>('users/*/posts') // User subcollection
@Collection<User>('users2') // Second User collection WITHOUT posts subcollection
@Collection<Comment>('comments') // Root comments collection
@Collection<Comment>('posts/*/comments') // Comments on posts in main collection
@Collection<Comment>('users/*/posts/*/comments') // Nested: Comments on user posts (DEEP NESTING)
@Collection<SimpleStory>('simpleStories')
@Collection<SharedPost>('sharedPosts') // Different path to avoid conflict
@Collection<SharedPost>('users/*/sharedPosts') // Different subcollection path
@Collection<ImmutableUser>('immutableUsers') // Fast immutable collections test
@Collection<JsonKeyUser>('jsonKeyUsers') // JsonKey annotation test
@Collection<DartImmutableUser>(
  'dartImmutableUsers',
) // Pure Dart immutable + json_serializable test
@Collection<ManualUser>(
  'manualUsers',
) // Manual toJson/fromJson implementation test
@Collection<ManualUser2>(
  'manualUsers2',
) // without toJson/fromJson implementation test
@Collection<ManualUser3<ManualUser3Profile<Book>>>(
  'manualUsers3',
) // complicated generic without toJson/fromJson implementation test

@Collection<ManualUser3<ManualUser3Profile<String>>>(
  'manualUsers3Strings', // different collection name to avoid conflicts
) // complicated generic with different type parameter test

@Collection<Task>('tasks') // Duration field test
@Collection<ListLengthModel>(
  'listLengthModels',
) // IList with JsonConverter test
@Collection<StringGeneric>('stringGenerics') // Generic collection test
@Collection<IntGeneric>('intGenerics') // Generic collection test
@Collection<User>('snake_case_users') // Test snake_case to camelCase conversion
@Collection<Post>('snake_case_users/*/user_posts') // Test snake_case subcollection
@Collection<Comment>('snake_case_users/*/user_posts/*/post_comments') // Test nested snake_case subcollection
@Collection<EnumUser>('enumUsers') // Enum + JsonValue test
@Collection<EnumTask>('enumTasks') // Enum with numeric @JsonValue test
@Collection<SimpleEnumTask>('simpleEnumTasks') // Simplified enum for automatic orderBy support
@Collection<NullableTypesTestModel>('nullableTypesTests') // Issue #3: nullable types test
@Collection<NestedData>('nestedData') // Nested data for issue #3 testing
const TestSchema testSchema = _$TestSchema;
