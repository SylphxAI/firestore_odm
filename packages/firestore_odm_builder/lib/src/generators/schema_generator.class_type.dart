part of 'schema_generator.dart';

final preferInlineAnnotation = refer(
  'pragma',
).call([literalString('vm:prefer-inline')]);
final overrideAnnotation = refer('override');

enum ClassType {
  root('Root'),
  collection('Collection'),
  document('Document'),
  transactionContext('TransactionContext'),
  transactionCollection('TransactionCollection'),
  transactionDocument('TransactionDocument'),
  batchContext('BatchContext'),
  batchCollection('BatchCollection'),
  batchDocument('BatchDocument'),
  patchBuilder('PatchBuilder');

  const ClassType(this.suffix);

  final String suffix;
}
