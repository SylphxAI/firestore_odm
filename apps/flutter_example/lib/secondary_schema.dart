import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/comment.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/user.dart';

/// Secondary schema class (multiple-schema support). Declared by hand so the
part 'secondary_schema.g.dart';

/// schema variable's type is resolvable before code generation (ADR-0002).
class SecondarySchema extends FirestoreSchema {
  const SecondarySchema();
}

/// Secondary test schema to reproduce bug with multiple schemas.
@Schema()
@Collection<User>('secondary_users')
@Collection<Post>('secondary_posts')
@Collection<Comment>('secondary_comments')
@Collection<Post>('secondary_users/*/user_posts') // Subcollection
@Collection<Comment>('secondary_posts/*/post_comments') // Subcollection
const SecondarySchema secondarySchema = SecondarySchema();
