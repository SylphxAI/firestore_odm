# Multiple ODM Instances

Create one `FirestoreODM` instance per schema and, when needed, per Firestore
client. This is useful for emulator tests, modular schemas, or separate
projects:

```dart
class AdminSchema extends FirestoreSchema {
  const AdminSchema();
}

class UserSchema extends FirestoreSchema {
  const UserSchema();
}

@Schema()
@Collection<AuditLog>('audit_logs')
const adminSchema = AdminSchema();

@Schema()
@Collection<User>('users')
const userSchema = UserSchema();

final adminDb = FirestoreODM(adminSchema, firestore: adminFirestore);
final userDb = FirestoreODM(userSchema, firestore: userFirestore);
```

Generated extensions are schema-specific: `adminDb.auditLogs` exists only on
the admin schema, while `userDb.users` exists only on the user schema. The
instances share no mutable registry or hidden service layer.
