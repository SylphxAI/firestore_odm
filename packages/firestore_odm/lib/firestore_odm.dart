/// Type-safe Firestore ODM with code generation support
library firestore_odm;

// Re-export cloud_firestore for convenience
export 'package:cloud_firestore/cloud_firestore.dart' show Timestamp, Blob;

export 'src/firestore_collection.dart';
export 'src/firestore_document.dart';
export 'src/firestore_odm.dart';
export 'src/filter_builder.dart';
export 'src/model_converter.dart';
export 'src/schema.dart';
export 'src/query.dart';
export 'src/transaction.dart';
export 'src/batch.dart';
export 'src/aggregate.dart';
export 'src/orderby.dart';
export 'src/types.dart';
export 'src/exceptions.dart';

export 'src/services/update_operations_service.dart';

export 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
