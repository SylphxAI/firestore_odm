import 'package:code_builder/code_builder.dart';

class TypeDefinition {
  final TypeReference type;
  final Reference instance;
  final List<Expression> positionalArguments;
  final Map<String, Expression> namedArguments;

  const TypeDefinition({
    required this.type,
    Reference? instance,
    this.positionalArguments = const [],
    this.namedArguments = const {},
  }) : instance = instance ?? type;
}
