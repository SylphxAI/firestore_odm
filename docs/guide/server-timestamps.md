> **5.0 note:** this guide documents the v4 API surface. See
> [migration-guide-5](./migration-guide-5) and [getting-started](./getting-started)
> for the current 5.0 API (create/set/patch/delete, no sentinels, no modify).
>
# Server Timestamps

In distributed systems, relying on the client's clock can lead to inconsistencies. Firestore provides a `FieldValue.serverTimestamp()` to ensure that timestamps are generated consistently on Google's servers. This ODM provides a convenient and type-safe way to use this feature.

## The `FirestoreODM.serverTimestamp` Constant

The ODM exposes a special static constant, `FirestoreODM.serverTimestamp`. You should use this constant whenever you want to set a server-generated timestamp on a `DateTime` field.

This constant acts as a **sentinel value**. When you use it in an update operation, the ODM's internal logic detects this special value and replaces it with the actual `FieldValue.serverTimestamp()` before sending the data to Firestore.

## Usage with `modify` and `incrementalModify`

When using `modify` or `incrementalModify`, assign `FirestoreODM.serverTimestamp` directly to your `DateTime` field within the `copyWith` method.

```dart
final userDoc = odm.users('jane-doe');

// The ODM will detect the special constant and convert it
// to a proper server timestamp.
await userDoc.modify((user) => user.copyWith(
  lastLogin: FirestoreODM.serverTimestamp,
));

// incrementalModify also supports server timestamps
await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1,
  lastLogin: FirestoreODM.serverTimestamp,
));
```

## Usage with `patch`

When using the `patch` method, you get access to a dedicated `.serverTimestamp()` method on any `DateTime` field. This is the recommended way to set server timestamps within a patch operation as it's more explicit.

```dart
final userDoc = odm.users('jane-doe');

// The .serverTimestamp() method directly creates the correct update operation.
await userDoc.patch(($) => [
  $.lastLogin.serverTimestamp(),
  $.profile.lastActivity.serverTimestamp(),
]);
```

By providing these two mechanisms, the ODM ensures you can easily and safely use server-generated timestamps, whether you prefer working with model objects (`modify`) or explicit update operations (`patch`).

## ⚠️ Important: Server Timestamp Arithmetic

**Warning:** You cannot perform arithmetic operations on `FirestoreODM.serverTimestamp`.

```dart
// ❌ This will NOT work as expected
FirestoreODM.serverTimestamp + Duration(days: 1)  // Results in a regular DateTime, not server timestamp

// ❌ This will also NOT work
FirestoreODM.serverTimestamp.add(Duration(hours: 1))  // Results in a regular DateTime
```

The `FirestoreODM.serverTimestamp` constant is a **sentinel value** that gets replaced with `FieldValue.serverTimestamp()` only when used exactly as-is. Any arithmetic operations will create a regular `DateTime` object instead of a server timestamp.

### If you need "server timestamp + offset":

1. **Use client-side calculation:**
   ```dart
   // Set to current time + 1 day (client time)
   DateTime.now().add(Duration(days: 1))
   ```

2. **Model design with computed getter (recommended):**
   Store the base timestamp and offset separately, then compute the final value:
   
   ```dart
   @freezed
   class User with _$User {
     const factory User({
       @DocumentIdField() required String id,
       required String name,
       DateTime? vipStartedAt, // When VIP started (server timestamp)
       Duration? vipExpiryOffset, // How long VIP lasts
     }) = _User;
     
     // Computed getter for VIP expiry date
     DateTime? get vipExpiryDate {
       if (vipStartedAt == null || vipExpiryOffset == null) return null;
       return vipStartedAt!.add(vipExpiryOffset!);
     }
     
     // Computed getter to check if VIP is still active
     bool get isVipActive {
       final expiryDate = vipExpiryDate;
       if (expiryDate == null) return false;
       return DateTime.now().isBefore(expiryDate);
     }
     
     factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
   }
   ```
   
   Usage:
   ```dart
   // Set server timestamp and Duration offset in one operation
   await userDoc.patch(($) => [
     $.vipStartedAt.serverTimestamp(), // Server sets exact start time
     $.vipExpiryOffset(Duration(days: 30)), // VIP lasts 30 days
   ]);
   
   // Access computed values
   final user = await userDoc.get();
   print('VIP expires at: ${user?.vipExpiryDate}'); // Automatically calculated
   print('Is VIP active: ${user?.isVipActive}'); // true/false
   ```

   **Note:** Firestore ODM supports `Duration` type natively. Duration values are serialized to/from Firestore as microseconds (int64), ensuring precision and compatibility.

3. **Two-step approach (separate operations):**
   ```dart
   // Step 1: Set server timestamp
   await userDoc.patch(($) => [$.createdAt.serverTimestamp()]);
   
   // Step 2: Read and calculate offset
   final user = await userDoc.get();
   final expiryDate = user!.createdAt.add(Duration(days: 30));
   await userDoc.patch(($) => [$.expiryDate(expiryDate)]);
   ```

   **Note:** This approach uses separate operations and may have potential race conditions. Unfortunately, you cannot use `patch` operations with server timestamps inside transactions, so this is the only viable approach for this pattern.

4. **Use Firestore Rules or Cloud Functions** for server-side calculations.

The key point: `FirestoreODM.serverTimestamp` must be used exactly as provided to work as a server timestamp.