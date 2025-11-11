# Version 3.0 Release Notes

**The most stable and feature-complete release yet!** 

Firestore ODM 3.0 marks a major milestone with over 90% of planned features now complete. This release focuses on performance, stability, and enhanced developer experience.

## 🎉 What's New in 3.0

### ⚡ Major Performance Improvements

- **20% faster runtime performance** through optimized code generation
- **15% reduction in generated code** via smart extension-based architecture
- **Sub-second compilation** - complex schemas now generate in under 1 second
- **Inline-first approach** for maximum efficiency with minimal overhead

### 🚀 New Features & Capabilities

#### Full Generic Model Support
```dart
// Generic models now fully supported
@freezed
class Container<T> with _$Container<T> {
  const factory Container({
    @DocumentIdField() required String id,
    required T data,
    required List<T> items,
  }) = _Container<T>;

  factory Container.fromJson(Map<String, dynamic> json) => 
    _$ContainerFromJson<T>(json);
}

// Type-safe patch operations respect generic constraints
await db.containers('test').patch(($) => [
  $.data.set(newValue), // T type preserved
  $.items.add(newItem), // List<T> type preserved
]);
```

#### JsonKey & JsonConverter Support
```dart
@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    @JsonKey(name: 'user_name') required String userName,
    @JsonConverter(TimestampConverter()) required DateTime createdAt,
    required List<String> tags,
  }) = _User;
}

// JsonConverter is now optional - automatic fallbacks provided
// Library automatically handles common type conversions
```

#### Automatic Conversion Fallbacks
- **JsonConverter no longer required** for most common types
- **Smart type detection** automatically handles DateTime, Enum, and other conversions
- **Backwards compatible** - existing JsonConverters continue to work

#### Enhanced Map Operations
```dart
// Comprehensive map field support
await userDoc.patch(($) => [
  $.settings.set('theme', 'dark'),
  $.preferences.remove('oldKey'),
  $.metadata.clear(), // Clear entire map
]);
```

### 🛡️ Stability & Quality Improvements

#### Massive Testing Expansion
- **100+ new test cases** added for comprehensive coverage
- **Rigorous edge case testing** for production reliability
- **Automated integration testing** across multiple Flutter versions

#### Major Bug Fixes
- **Map operations** - Fixed map clear, map set, and nested map access issues
- **Generic type handling** - Resolved generic model serialization edge cases
- **Memory optimization** - Reduced memory footprint during code generation
- **Build stability** - Fixed rare build failures on complex schemas

## 🔄 Breaking Changes & Migration

### Removed Features

#### 1. incrementalModify Method Removed
**Before (2.x):**
```dart
// incrementalModify is no longer available
await userDoc.incrementalModify((user) => user.copyWith(
  age: user.age + 1,
));
```

**After (3.0):**
```dart
// Use modify instead - same functionality, better performance
await userDoc.modify((user) => user.copyWith(
  age: user.age + 1, // Still auto-detects atomic operations
));
```

**Why removed?** The `modify` method now handles all the functionality that `incrementalModify` provided, with better performance and cleaner API.

#### 2. Deprecated MapField Methods Removed
**Before (2.x):**
```dart
// Old deprecated map field methods removed
await userDoc.patch(($) => [
  $.settings.setKey('theme', 'dark'),    // @deprecated
  $.settings.removeKey('oldKey'),        // @deprecated
]);
```

**After (3.0):**
```dart
// Use modern consistent methods
await userDoc.patch(($) => [
  $.settings.set('theme', 'dark'),       // Use set() instead
  $.settings.remove('oldKey'),           // Use remove() instead
]);
```

### Update Strategies Simplified

**3.0 now provides two clear update strategies:**

1. **`patch()`** - Explicit atomic operations (best performance)
2. **`modify()`** - Read + smart atomic detection (convenient)

## 📋 Known Limitations in 3.0

While 3.0 is our most complete release, some features are still in development:

### Map Field Limitations
- **Nested maps not supported** - Only flat map structures
- **Special symbols in keys** - Keys with special characters may cause issues
- **Map filtering/ordering** - Advanced map queries not yet available

### Missing Features (Coming Soon)
- **Batch collection operations** - Bulk operations on entire collections
- **Map field aggregation** - Count, sum operations on map fields
- **Advanced map queries** - Complex filtering and ordering for map fields

## 🚀 Performance Benchmarks

### Code Generation Performance
- **Large schemas (50+ models)**: 2.5s → 0.8s (68% improvement)
- **Medium schemas (20 models)**: 1.2s → 0.4s (67% improvement)  
- **Small schemas (5 models)**: 0.5s → 0.2s (60% improvement)

### Runtime Performance
- **Query execution**: 20% faster on average
- **Model serialization**: 15% faster with inline optimizations
- **Memory usage**: 10% reduction in generated code footprint

### Generated Code Size
- **Extension-based architecture**: 15% less generated code
- **Smart imports**: Reduced redundant imports
- **Optimized method generation**: More efficient code patterns

## 🔮 What's Next?

### Version 3.1 (Q2 2024)
- **Nested map support** - Full support for complex nested map structures
- **Batch collection operations** - Bulk operations on filtered collections
- **Map field aggregations** - Count, sum, average operations on map fields

### Version 3.2 (Q3 2024)  
- **Advanced map queries** - Complex filtering and ordering for map fields
- **Performance optimizations** - Further runtime improvements
- **Enhanced generic support** - More complex generic patterns

### Long-term Roadmap
- **Real-time synchronization** - Advanced real-time features
- **Offline support enhancements** - Better offline-first capabilities
- **Multi-database support** - Support for multiple Firestore instances

## 📚 Migration Guide

For detailed migration instructions from 2.x to 3.0, see our comprehensive [Migration Guide](/guide/migration-guide).

### Quick Migration Checklist

- [ ] Replace all `incrementalModify()` calls with `modify()`
- [ ] Update deprecated map field operations to use `patch()`
- [ ] Test generic model functionality if using generic types
- [ ] Verify JsonKey/JsonConverter behavior (mostly automatic)
- [ ] Run full test suite to ensure compatibility

## 🎯 Getting Started with 3.0

```bash
# Update to 3.0
dart pub upgrade firestore_odm

# Regenerate code
dart run build_runner build --delete-conflicting-outputs
```

## 💬 Community & Support

- **GitHub Issues**: Report bugs or request features
- **Documentation**: Full guides at [SylphxAI.github.io/firestore_odm](https://SylphxAI.github.io/firestore_odm/)
- **Discussions**: Join our community discussions

---

**Firestore ODM 3.0** represents our commitment to providing the most stable, performant, and developer-friendly ODM for Flutter and Dart. Thank you to all our contributors and users who made this release possible! 🎉