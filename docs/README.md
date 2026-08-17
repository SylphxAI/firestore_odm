# Firestore ODM Documentation

This directory documents the v5 clean-break contract for the type-safe Firestore
ODM on Dart and Flutter. The runtime, generator, examples, and guides share one
public API; historical v3/v4 release notes are retained only as history.

## 🌟 What is Firestore ODM?

Firestore ODM transforms your Firestore development experience by providing:

- **Complete Type Safety**: No more `Map<String, dynamic>` or runtime errors
- **Lightning Fast Code Generation**: Highly optimized generated code using callables and Dart extensions
- **Minimal Generated Code**: One unified generator produces converters and selectors
- **Model Reusability**: Same model works in both collections and subcollections without code duplication
- **Core Features**: Stable pagination, one-shot server aggregates, and deferred transaction writes

## 📚 Documentation Structure

### 🚀 Getting Started
- **[Introduction](./guide/introduction.md)** - What is Firestore ODM and detailed comparison with standard cloud_firestore
- **[Getting Started](./guide/getting-started.md)** - Complete setup guide from installation to first query

### 🏗️ Core Concepts
- **[Data Modeling](./guide/data-modeling.md)** - Support for freezed, plain Dart classes, JsonKey, and JsonConverter
- **[Schema Definition](./guide/schema-definition.md)** - Schema-based architecture for type-safe database structure
- **[Document ID](./guide/document-id.md)** - Automatic document ID handling with `@DocumentIdField`
- **[Server Timestamps](./guide/server-timestamps.md)** - Type-safe server timestamp handling
- **[Multiple ODM Instances](./guide/multiple-instances.md)** - Separate schemas for different app modules

### 📖 Working with Documents
- **[Reading Documents](./guide/reading-documents.md)** - Single document operations: get and stream
- **[Writing Documents](./guide/writing-documents.md)** - create, set, patch, and delete

### 🔍 Querying Data
- **[Fetching Data](./guide/fetching-data.md)** - Execute queries and real-time subscriptions
- **[Filtering Data](./guide/filtering-data.md)** - Type-safe where clauses with complex logical operations
- **[Ordering & Limiting](./guide/ordering-and-limiting.md)** - Sort and limit query results
- **[Pagination](./guide/pagination.md)** - Revolutionary Smart Builder pagination with zero inconsistency risk
- **[Bulk Operations](./guide/bulk-operations.md)** - Update or delete multiple documents at once

### 🚀 Advanced Features
- **[Aggregations](./guide/aggregations.md)** - One-shot server-side count, sum, and average
- **[Transactions](./guide/transactions.md)** - Atomic operations with automatic deferred writes
- **[Subcollections](./guide/subcollections.md)** - Type-safe nested collections with model reusability

## 🔥 Key Advantages Over Standard Firestore

### Type Safety Revolution
```dart
// ❌ Standard cloud_firestore - Runtime errors waiting to happen
Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
String name = data?['name']; // Runtime error if field doesn't exist

// ✅ Firestore ODM - Compile-time safety
User? user = await db.users('user123').get();
String name = user.name; // IDE autocomplete, compile-time checking
```

### Explicit Patch Operations
```dart
// ❌ Standard - Manual map construction
await userDoc.update({
  'profile.followers': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['verified']),
});

// ✅ ODM - Explicit typed patch operations
await userDoc.patch(($) => [
  $.profile.followers.increment(1),
  $.tags.arrayUnion(['verified']),
]);
```

### Revolutionary Pagination
```dart
// ❌ Standard - Error-prone manual cursor management
Query nextQuery = query.startAfterDocument(lastDoc);

// ✅ ODM - Smart Builder with zero inconsistency risk
final nextPage = await db.users
  .orderBy(($) => $.createdAt())
  .startAfterObject(page1.last) // Type-safe cursor extraction
  .get();
```

### One-shot Server Aggregations
```dart
// ❌ Standard - no typed aggregate result

// ✅ ODM - One-shot server-side aggregation
final stats = await db.users.aggregate(($) => (
  count: $.count(),
  averageAge: $.age.average(),
)).get();
print('Stats: ${stats.count} users, avg age ${stats.averageAge}');
```

## 🛠️ Technical Excellence

### Optimized Code Generation
- **Lightning Fast Builds**: Highly optimized code generation using callables and Dart extensions
- **Minimal Output**: Smart generation produces compact, efficient code without bloating your project
- **Model Reusability**: Same model works across collections and subcollections without code duplication
- **Zero Runtime Overhead**: All magic happens at compile time

### Advanced Features
- **Automatic Deferred Writes**: Transactions automatically handle read-before-write rules
- **Smart Builder Pagination**: Single source of truth eliminates cursor inconsistencies  
- **One-shot Aggregations**: Native server-side count, sum, and average
- **Flexible Data Modeling**: Support for freezed, json_serializable, JsonKey, and JsonConverter

## 🚀 Development

### Local Development
```bash
cd docs
npm install
npm run dev
```

### Building
```bash
cd docs
npm run build
```

### Deployment
The documentation is automatically deployed to GitHub Pages at:
**https://SylphxAI.github.io/firestore_odm/**

## 📊 Documentation Coverage

This comprehensive documentation covers:

- ✅ **Complete API Reference**: Every method and feature documented with examples
- ✅ **Real-world Examples**: Practical code samples for all use cases
- ✅ **Performance Insights**: Technical details about optimizations and best practices
- ✅ **Migration Guide**: Detailed comparison with standard cloud_firestore
- ✅ **Advanced Patterns**: Transactions, aggregations, subcollections, and bulk operations
- ✅ **Type Safety**: Comprehensive coverage of compile-time safety features

## 🎯 Target Audience

- **Flutter Developers** seeking type-safe Firestore operations
- **Dart Developers** building server-side applications with Firestore
- **Teams** wanting to eliminate runtime database errors
- **Projects** requiring high-performance, maintainable database code
- **Developers** frustrated with standard cloud_firestore limitations

---

**Transform your Firestore development experience with type-safe, intuitive database operations that feel natural and productive.**

🔗 **[Get Started Now](https://SylphxAI.github.io/firestore_odm/guide/getting-started.html)**
