/// Minimal Dart source scanning for the migration codemod: find the closing
/// bracket of a call and split its arguments, skipping strings and comments.
library;

/// Returns the index of the bracket that closes the one at [open], or -1.
int closingBracket(String source, int open) {
  const pairs = {'(': ')', '[': ']', '{': '}'};
  final stack = <String>[pairs[source[open]]!];
  var i = open + 1;
  while (i < source.length) {
    final c = source[i];
    if (c == '/' && i + 1 < source.length && source[i + 1] == '/') {
      final end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end;
      continue;
    }
    if (c == '/' && i + 1 < source.length && source[i + 1] == '*') {
      final end = source.indexOf('*/', i + 2);
      i = end < 0 ? source.length : end + 2;
      continue;
    }
    if (c == "'" || c == '"') {
      i = _skipString(source, i);
      continue;
    }
    if (pairs.containsKey(c)) {
      stack.add(pairs[c]!);
    } else if (c == stack.last) {
      stack.removeLast();
      if (stack.isEmpty) return i;
    }
    i++;
  }
  return -1;
}

int _skipString(String source, int start) {
  final quote = source[start];
  final raw = start > 0 && source[start - 1] == 'r';
  final triple = source.startsWith(quote * 3, start);
  final delimiter = triple ? quote * 3 : quote;
  var i = start + delimiter.length;
  while (i < source.length) {
    if (!raw && source[i] == r'\') {
      i += 2;
      continue;
    }
    if (source.startsWith(delimiter, i)) return i + delimiter.length;
    i++;
  }
  return source.length;
}

/// One call argument: `name: value` or a positional `value`.
class Argument {
  const Argument(this.name, this.value);

  /// The argument name, or null for a positional argument.
  final String? name;

  /// The argument expression, trimmed.
  final String value;
}

final _namedArgument = RegExp(r'^([A-Za-z_]\w*)\s*:(?!:)');

/// Splits the text between a call's parentheses into its arguments.
List<Argument> splitArguments(String inner) {
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  var i = 0;
  while (i < inner.length) {
    final c = inner[i];
    if (c == "'" || c == '"') {
      i = _skipString(inner, i);
      continue;
    }
    if ('([{'.contains(c)) depth++;
    if (')]}'.contains(c)) depth--;
    if (c == ',' && depth == 0) {
      parts.add(inner.substring(start, i));
      start = i + 1;
    }
    i++;
  }
  parts.add(inner.substring(start));
  return [
    for (final part in parts.map((p) => p.trim()).where((p) => p.isNotEmpty))
      if (_namedArgument.firstMatch(part) case final m?)
        Argument(m.group(1), part.substring(m.end).trim())
      else
        Argument(null, part),
  ];
}
