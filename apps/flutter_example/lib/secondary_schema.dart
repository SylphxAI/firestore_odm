import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/comment.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/user.dart';

part 'secondary_schema.g.dart';

/// Secondary test schema to reproduce bug with multiple schemas
@Schema()
@Collection<User>('secondary_users')
@Collection<Post>('secondary_posts')
@Collection<Comment>('secondary_comments')
@Collection<Post>('secondary_users/*/user_posts') // Subcollection
@Collection<Comment>('secondary_posts/*/post_comments') // Subcollection
const SecondarySchema secondarySchema = _$SecondarySchema;
