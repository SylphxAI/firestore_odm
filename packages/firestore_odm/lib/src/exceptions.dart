/// Custom exceptions for Firestore ODM operations.
///
/// These exceptions provide more specific error information than
/// standard Dart exceptions, allowing for better error handling
/// in client code.
library;

/// Base exception for all Firestore ODM errors.
///
/// Catch this to handle any Firestore ODM-specific error.
///
/// ```dart
/// try {
///   await odm.users.doc('123').get();
/// } on FirestoreODMException catch (e) {
///   print('ODM error: ${e.message}');
/// }
/// ```
sealed class FirestoreODMException implements Exception {
  /// Human-readable error message.
  String get message;

  /// Optional error code for programmatic handling.
  String? get code;

  @override
  String toString() => 'FirestoreODMException: $message';
}

/// Exception thrown when document validation fails.
///
/// This includes:
/// - Invalid document ID
/// - Missing required fields
/// - Type mismatches during serialization
class FirestoreODMValidationException implements FirestoreODMException {
  @override
  final String message;

  @override
  final String? code;

  /// The field that failed validation, if applicable.
  final String? field;

  const FirestoreODMValidationException(this.message, {this.code, this.field});

  @override
  String toString() {
    final buffer = StringBuffer('FirestoreODMValidationException: $message');
    if (field != null) buffer.write(' (field: $field)');
    if (code != null) buffer.write(' [code: $code]');
    return buffer.toString();
  }
}

/// Exception thrown when a document operation fails.
///
/// This includes:
/// - Document not found
/// - Permission denied (wrapped from Firestore)
/// - Network errors (wrapped from Firestore)
class FirestoreODMDocumentException implements FirestoreODMException {
  @override
  final String message;

  @override
  final String? code;

  /// The document path that caused the error.
  final String? documentPath;

  /// The underlying cause, if any.
  final Object? cause;

  const FirestoreODMDocumentException(
    this.message, {
    this.code,
    this.documentPath,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FirestoreODMDocumentException: $message');
    if (documentPath != null) buffer.write(' (path: $documentPath)');
    if (code != null) buffer.write(' [code: $code]');
    return buffer.toString();
  }
}

/// Exception thrown when path resolution fails.
///
/// This occurs when accessing nested fields that don't exist
/// or have unexpected types.
class FirestoreODMPathException implements FirestoreODMException {
  @override
  final String message;

  @override
  final String? code;

  /// The path that failed to resolve.
  final String? path;

  /// The component where resolution failed.
  final String? failedComponent;

  const FirestoreODMPathException(
    this.message, {
    this.code,
    this.path,
    this.failedComponent,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FirestoreODMPathException: $message');
    if (path != null) buffer.write(' (path: $path)');
    if (failedComponent != null) buffer.write(' (at: $failedComponent)');
    if (code != null) buffer.write(' [code: $code]');
    return buffer.toString();
  }
}

/// Exception thrown when type conversion fails.
///
/// This occurs during serialization or deserialization when
/// the actual type doesn't match the expected type.
class FirestoreODMTypeException implements FirestoreODMException {
  @override
  final String message;

  @override
  final String? code;

  /// The expected type.
  final Type? expectedType;

  /// The actual type encountered.
  final Type? actualType;

  const FirestoreODMTypeException(
    this.message, {
    this.code,
    this.expectedType,
    this.actualType,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FirestoreODMTypeException: $message');
    if (expectedType != null && actualType != null) {
      buffer.write(' (expected: $expectedType, got: $actualType)');
    }
    if (code != null) buffer.write(' [code: $code]');
    return buffer.toString();
  }
}
