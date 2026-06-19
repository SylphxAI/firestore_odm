import 'package:build/build.dart';
import 'package:firestore_odm_builder/src/model_builder_generator.dart';
import 'package:firestore_odm_builder/src/schema_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Creates a builder for Firestore ODM code generation
Builder firestoreOdmBuilder(BuilderOptions options) => SharedPartBuilder([
  const SchemaGenerator2(),
  ModelBuilderGenerator(),
], 'odm');
