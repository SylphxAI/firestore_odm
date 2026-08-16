/// Exceptions raised by Firestore ODM.
///
/// All ODM errors implement [FirestoreODMException]. Where an underlying
/// [FirebaseException] from `cloud_firestore` exists (permission denied,
/// not-found, failed-precondition, ...), it is preserved in [cause] and its
/// `code` is forwarded to [FirestoreODMException.code] so callers can branch
/// on the same codes they already use with the raw SDK.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

sealed class FirestoreODMException implements Exception {
  String get message;
  String? get code;
  Object? get cause;

  @override
  String toString() => 'FirestoreODMException: $message';
}

/// Raised when a document or its data fails validation.
class FirestoreODMValidationException implements FirestoreODMException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final Object? cause;
  final String? field;

  const FirestoreODMValidationException(
    this.message, {
    this.code,
    this.field,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FirestoreODMValidationException: $message');
    if (field != null) buffer.write(' (field: $field)');
    if (code != null) buffer.write(' [code: $code]');
    return buffer.toString();
  }
}

/// Raised when a document-level operation fails (missing document, malformed
/// snapshot, wrapped platform error).
class FirestoreODMDocumentException implements FirestoreODMException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final Object? cause;

  /// The document path that caused the error, when known.
  final String? documentPath;

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

/// Raised when a nested field path cannot be resolved on a document map.
class FirestoreODMPathException implements FirestoreODMException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final Object? cause;
  final String? path;

  const FirestoreODMPathException(
    this.message, {
    this.code,
    this.path,
    this.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('FirestoreODMPathException: $message');
    if (path != null) buffer.write(' (path: $path)');
    if (code != null) buffer.write(' [code: $code]');
    return buffer.toString();
  }
}

/// Raised when a Firestore value does not match the expected Dart type.
class FirestoreODMTypeException implements FirestoreODMException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final Object? cause;
  final Type? expectedType;
  final Type? actualType;

  const FirestoreODMTypeException(
    this.message, {
    this.code,
    this.expectedType,
    this.actualType,
    this.cause,
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

/// Wraps a platform [FirebaseException] with ODM context while preserving the
/// original code and message so existing Firebase-style handling keeps working.
class FirestoreODMPlatformException implements FirestoreODMException {
  @override
  final String message;
  @override
  final String? code;
  @override
  final Object? cause;

  const FirestoreODMPlatformException(this.message, {this.code, this.cause});

  factory FirestoreODMPlatformException.from(FirebaseException error) =>
      FirestoreODMPlatformException(
        error.message ?? 'Firestore platform error',
        code: error.code,
        cause: error,
      );

  @override
  String toString() => 'FirestoreODMPlatformException: $message [code: $code]';
}
