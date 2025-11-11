# Firestore ODM Documentation

This directory contains the comprehensive documentation for **Firestore ODM** - a revolutionary type-safe Object Document Mapper for Cloud Firestore on Dart & Flutter.

## 🌟 What is Firestore ODM?

Firestore ODM transforms your Firestore development experience by providing:

- **Complete Type Safety**: No more `Map<String, dynamic>` or runtime errors
- **Lightning Fast Code Generation**: Highly optimized generated code using callables and Dart extensions
- **Minimal Generated Code**: Smart generation produces compact, efficient output
- **Model Reusability**: Same model works in both collections and subcollections without code duplication
- **Revolutionary Features**: Smart pagination, streaming aggregations, and automatic deferred writes in transactions

## 📚 Documentation Structure

### 🚀 Getting Started
- **[Introduction](./guide/introduction.md)** - What is Firestore ODM and detailed comparison with standard cloud_firestore
- **[Getting Started](./guide/getting-started.md)** - Complete setup guide from installation to first query

### 🏗️ Core Concepts
- **[Data Modeling](./guide/data-modeling.md)** - Support for freezed, plain Dart classes, and fast_immutable_collections
- **[Schema Definition](./guide/schema-definition.md)** - Schema-based architecture for type-safe database structure
- **[Document ID](./guide/document-id.md)** - Automatic document ID handling with `@DocumentIdField`
- **[Server Timestamps](./guide/server-timestamps.md)** - Type-safe server timestamp handling
- **[Multiple ODM Instances](./guide/multiple-instances.md)** - Separate schemas for different app modules

### 📖 Working with Documents
- **[Reading Documents](./guide/reading-documents.md)** - Single document operations: get, stream, exists
- **[Writing Documents](./guide/writing-documents.md)** - Three powerful update strategies: patch, modify, incrementalModify

### 🔍 Querying Data
- **[Fetching Data](./guide/fetching-data.md)** - Execute queries and real-time subscriptions
- **[Filtering Data](./guide/filtering-data.md)** - Type-safe where clauses with complex logical operations
- **[Ordering & Limiting](./guide/ordering-and-limiting.md)** - Sort and limit query results
- **[Pagination](./guide/pagination.md)** - Revolutionary Smart Builder pagination with zero inconsistency risk
- **[Bulk Operations](./guide/bulk-operations.md)** - Update or delete multiple documents at once

### 🚀 Advanced Features
- **[Aggregations](./guide/aggregations.md)** - Server-side count, sum, average with unique streaming support
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

### Smart Update Strategies
```dart
// ❌ Standard - Manual map construction
await userDoc.update({
  'profile.followers': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['verified']),
});

// ✅ ODM - Three intelligent update patterns
await userDoc.patch(($) => [
  $.profile.followers.increment(1),
  $.tags.add('verified'),
]);

await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1, // Auto-detects -> FieldValue.increment(1)
));
```

### Revolutionary Pagination
```dart
// ❌ Standard - Error-prone manual cursor management
Query nextQuery = query.startAfterDocument(lastDoc);

// ✅ ODM - Smart Builder with zero inconsistency risk
final nextPage = await db.users
  .orderBy(($) => $.createdAt)
  .startAfterObject(page1.last) // Type-safe cursor extraction
  .get();
```

### Unique Streaming Aggregations
```dart
// ❌ Standard - No streaming aggregations
// Only basic count, no real-time updates

// ✅ ODM - Real-time streaming aggregations (unique feature!)
db.users.aggregate(($) => (
  count: $.count(),
  averageAge: $.age.average(),
)).stream.listen((result) {
  print('Live stats: ${result.count} users, avg age ${result.averageAge}');
});
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
- **Streaming Aggregations**: Client-side implementation of real-time aggregate subscriptions
- **Flexible Data Modeling**: Support for freezed, json_serializable, and fast_immutable_collections

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