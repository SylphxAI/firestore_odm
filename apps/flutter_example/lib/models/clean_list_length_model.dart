import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clean_list_length_model.freezed.dart';
part 'clean_list_length_model.g.dart';

/// JsonConverter that converts between List<String> and int (list length)
/// This demonstrates bidirectional conversion: List ↔ int
class ListLengthConverter implements JsonConverter<IList<String>, int> {
  const ListLengthConverter();

  @override
  IList<String> fromJson(int json) {
    // Convert int (length) back to IList with placeholder items
    // This creates a list with the specified length filled with placeholder values
    return List.generate(json, (index) => 'item_$index').toIList();
  }

  @override
  int toJson(IList<String> object) {
    // Convert IList to int (calculate length)
    return object.length;
  }
}

/// JsonConverter for IList<int> to int (sum of all values)
class ListSumConverter implements JsonConverter<IList<int>, int> {
  const ListSumConverter();

  @override
  IList<int> fromJson(int json) {
    // Convert int (sum) back to IList with single item
    // This is a simple back-conversion strategy
    return [json].toIList();
  }

  @override
  int toJson(IList<int> object) {
    // Convert IList<int> to int (calculate sum)
    return object.fold(0, (sum, value) => sum + value);
  }
}

@freezed
abstract class CleanListLengthModel with _$CleanListLengthModel {
  const factory CleanListLengthModel({
    @DocumentIdField() required String id,
    required String name,
    required String description,

    // IList<String> that gets converted to/from int (length)
    @ListLengthConverter() @Default(IListConst([])) IList<String> items,

    // IList<int> that gets converted to/from int (sum)
    @ListSumConverter() @Default(IListConst([])) IList<int> numbers,

    // Regular IList without converter for comparison
    @Default(IListConst([])) IList<String> tags,

    @Default(0) int priority,
    @Default(false) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CleanListLengthModel;

  factory CleanListLengthModel.fromJson(Map<String, dynamic> json) =>
      _$CleanListLengthModelFromJson(json);
}
