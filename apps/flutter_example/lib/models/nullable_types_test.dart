/// Nullable type handling models.
///
/// Issue #3 regression coverage: nullable map/list/enum fields.
library;

/// Models for nullable type handling.
/// 1. Nullable Map types in map field updates
/// 2. Nullable return type in MapFilterField.toJson
/// 3. Type mismatch in fromJson for nested objects
/// 4. Enum lookup returns nullable but field is non-nullable

import 'package:firestore_odm/firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'nullable_types_test.g.dart';

/// Test enum for issue #4
@JsonEnum()
enum TestStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
}

/// Test enum with numeric values
@JsonEnum()
enum Priority {
  @JsonValue(1)
  low,
  @JsonValue(2)
  medium,
  @JsonValue(3)
  high,
}

/// Nested class for issue #3 testing
@JsonSerializable()
@firestoreOdm
class NestedData {
  const NestedData({required this.name, this.value});

  factory NestedData.fromJson(Map<String, Object?> json) =>
      _$NestedDataFromJson(json);

  final String name;
  final int? value;

  Map<String, dynamic> toJson() => _$NestedDataToJson(this);
}

/// Main test model that exercises all nullable type scenarios
@JsonSerializable()
@firestoreOdm
class NullableTypesTestModel {
  const NullableTypesTestModel({
    required this.id,
    required this.name,
    // Issue #1 & #2: Nullable map fields
    this.nullableMap,
    this.nullableStringMap,
    // Non-nullable map for comparison
    this.requiredMap = const {},
    // Issue #3: Nullable nested objects
    this.nullableNested,
    this.nestedList = const [],
    // Issue #4: Non-nullable enum fields
    required this.status,
    required this.priority,
    // Nullable enum for comparison
    this.nullableStatus,
  });

  factory NullableTypesTestModel.fromJson(Map<String, Object?> json) =>
      _$NullableTypesTestModelFromJson(json);

  @DocumentIdField()
  final String id;

  final String name;

  /// Nullable dynamic map - tests DartMapFieldUpdate nullable support
  final Map<String, dynamic>? nullableMap;

  /// Nullable typed map - tests MapFilterField nullable support
  final Map<String, String>? nullableStringMap;

  /// Required map for comparison
  final Map<String, int> requiredMap;

  /// Nullable nested object - tests fromJson type casting
  final NestedData? nullableNested;

  /// List of nested objects
  final List<NestedData> nestedList;

  /// Non-nullable enum - tests enum map lookup null safety
  final TestStatus status;

  /// Non-nullable numeric enum
  final Priority priority;

  /// Nullable enum for comparison
  final TestStatus? nullableStatus;

  Map<String, dynamic> toJson() => _$NullableTypesTestModelToJson(this);
}
