/// Structural golden for the generated surface (ADR-0002).
///
/// The generated combined part (`user.g.dart`) is not committed, so these
/// assertions pin the *contract* of the generated code: the presence and
/// shape of every generated declaration for the User model. A structural
/// regression in the builder fails here at compile/test time.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String userPart;

  setUpAll(() {
    userPart = File('lib/models/user.g.dart').readAsStringSync();
  });

  test('generates the ODM storage converters (owned serialization)', () {
    expect(userPart, contains('Map<String, dynamic>? UserToJson('));
    expect(userPart, contains('User UserFromJson('));
    // DateTime must be native, not ISO-string munged.
    expect(userPart, contains('createdAt'));
  });

  test('generates the patch builder with the six-op handles', () {
    expect(userPart, contains('class UserPatchBuilder'));
    expect(userPart, contains('NumericFieldUpdate<int> age'));
    expect(userPart, contains('DateTimeFieldUpdate'));
    expect(userPart, contains('ListFieldUpdate<String> tags'));
    expect(userPart, contains('FieldUpdate<Profile> profile'));
  });

  test('generates filter/orderBy/aggregate builders with documentId', () {
    expect(userPart, contains('class UserFilterBuilder'));
    expect(userPart, contains('FilterField<String, String> documentId'));
    expect(userPart, contains('class UserOrderByBuilder'));
    expect(userPart, contains('OrderByField<String> documentId'));
    expect(userPart, contains('class UserAggregateBuilder'));
    expect(userPart, contains('int count()'));
  });

  test('generates the pipeline selector for non-generic models', () {
    expect(userPart, contains('class UserPipelineSelector'));
    expect(userPart, contains('UserPipelineExtension'));
  });
}
