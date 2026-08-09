/// Type-safe Firestore ODM for Dart/Flutter — code generation, zero
/// reflection, exact Firestore semantics (see `docs/adr/0002`).
library firestore_odm;

export 'package:firestore_odm_annotation/firestore_odm_annotation.dart';

export 'src/aggregate.dart';
export 'src/batch.dart';
export 'src/exceptions.dart';
export 'src/field_selector.dart';
export 'src/filter_builder.dart';
export 'src/firestore_collection.dart';
export 'src/firestore_document.dart';
export 'src/firestore_odm.dart';
export 'src/orderby.dart';
export 'src/pagination.dart';
export 'src/patch.dart';
export 'src/pipeline.dart';
export 'src/query.dart';
export 'src/record_utils.dart';
export 'src/schema.dart';
export 'src/transaction.dart';
export 'src/types.dart';
export 'src/utils.dart' show defaultValue, identity, dateTimeFromJson, durationToJson, durationFromJson;
