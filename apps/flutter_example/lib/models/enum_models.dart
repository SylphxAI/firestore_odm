import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enum_models.freezed.dart';
part 'enum_models.g.dart';

enum AccountType {
  @JsonValue('free')
  free,
  @JsonValue('pro')
  pro,
  @JsonValue('enterprise')
  enterprise,
}

/// Priority enum with numeric @JsonValue
enum Priority {
  @JsonValue(1)
  low,
  @JsonValue(2)
  medium,
  @JsonValue(3)
  high,
  @JsonValue(4)
  critical,
}

/// Status enum with mixed types for testing
enum TaskStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

@freezed
@firestoreOdm
abstract class EnumUser with _$EnumUser {
  const factory EnumUser({
    @DocumentIdField() required String id,
    required String name,
    required AccountType accountType,
    @Default(AccountType.free) AccountType plan,
    AccountType? optional,
  }) = _EnumUser;

  factory EnumUser.fromJson(Map<String, dynamic> json) =>
      _$EnumUserFromJson(json);
}

/// EnumTask model with numeric priority enum and status enum for comprehensive testing
@freezed
@firestoreOdm
abstract class EnumTask with _$EnumTask {
  const factory EnumTask({
    @DocumentIdField() required String id,
    required String title,
    required Priority priority,
    required TaskStatus status,
    @Default(Priority.medium) Priority defaultPriority,
    Priority? optionalPriority,
    @Default(TaskStatus.pending) TaskStatus defaultStatus,
    TaskStatus? optionalStatus,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _EnumTask;

  factory EnumTask.fromJson(Map<String, dynamic> json) =>
      _$EnumTaskFromJson(json);
}

/// Test model for simplified enum orderBy (no annotation needed)
@freezed
@firestoreOdm
abstract class SimpleEnumTask with _$SimpleEnumTask {
  const factory SimpleEnumTask({
    @DocumentIdField() required String id,
    required String title,
    required Priority priority,
    required TaskStatus status,
    required DateTime createdAt,
  }) = _SimpleEnumTask;

  factory SimpleEnumTask.fromJson(Map<String, dynamic> json) =>
      _$SimpleEnumTaskFromJson(json);
}
