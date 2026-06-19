import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_length_model.freezed.dart';
part 'list_length_model.g.dart';

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
@firestoreOdm
abstract class ListLengthModel with _$ListLengthModel {
  const factory ListLengthModel({
    @DocumentIdField() required String id,
    required String name,
    required String description,

    @Default(IListConst([])) IList<Profile> nestedProfiles,

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
  }) = _ListLengthModel;
  const ListLengthModel._();

  factory ListLengthModel.fromJson(Map<String, dynamic> json) =>
      _$ListLengthModelFromJson(json);

  // Helper methods to demonstrate the conversion functionality
  int get itemsLength => items.length;
  int get numbersSum => numbers.fold(0, (sum, value) => sum + value);

  // Method to add items and see how conversion works
  ListLengthModel addItem(String item) {
    return copyWith(items: items.add(item));
  }

  ListLengthModel addNumber(int number) {
    return copyWith(numbers: numbers.add(number));
  }

  ListLengthModel addTag(String tag) {
    return copyWith(tags: tags.add(tag));
  }
}
