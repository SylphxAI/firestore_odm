# Multiple ODM Instances

A powerful feature of the schema-based architecture is the ability to create multiple, completely separate ODM instances, even within the same application. This is useful for a variety of scenarios:

-   **Microservices or Modular Apps**: Different parts of your app can have their own dedicated database schemas and ODM instances.
-   **Testing**: You can easily create a separate ODM instance that points to a test or emulator database.
-   **Multi-Tenant Apps**: If you have different database structures for different user roles or tenants, you can create a specific ODM for each one.

## How It Works

The key is that the `FirestoreODM` class is instantiated with a specific schema variable. You can define as many schema variables as you need.

### 1. Define Multiple Schemas

Create different schema definitions in your application.

```dart
// lib/schemas/admin_schema.dart
class AdminSchema extends FirestoreSchema {
  const AdminSchema();
}

@Schema()
@Collection<User>("users")
@Collection<AuditLog>("audit_logs")
const adminSchema = AdminSchema();

// lib/schemas/user_schema.dart
class UserSchema extends FirestoreSchema {
  const UserSchema();
}

@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
const userSchema = UserSchema();
```

After running the build runner, the generated extensions land in `admin_schema.g.dart` and `user_schema.g.dart` (each schema file declares its part).

### 2. Create Separate ODM Instances

Now, you can create separate `FirestoreODM` instances, each configured with a different schema.

```dart
import 'package:firestore_odm/firestore_odm.dart';
import 'schemas/admin_schema.dart';
import 'schemas/user_schema.dart';

// An ODM instance for administrative tasks
final adminDb = FirestoreODM(adminSchema);

// A separate ODM instance for regular user data access
final userDb = FirestoreODM(userSchema);

// These are now fully type-safe and separate:
final auditLogs = adminDb.audit_logs; // This exists
// final posts = adminDb.posts; // This would be a compile-time error

final userPosts = userDb.posts; // This exists
// final auditLogs = userDb.audit_logs; // This would be a compile-time error
```

This approach provides strong compile-time guarantees, ensuring that different parts of your application only access the collections they are authorized to use, as defined by their respective schemas.
