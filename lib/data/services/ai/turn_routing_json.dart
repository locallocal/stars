part of 'turn_routing_protocol.dart';

/// dart:convert accepts duplicate keys. Reject them (including escaped aliases)
/// and excessive nesting before decoding, so a later field cannot change kind.
Map<String, Object?> _strictObject(String source) {
  final stack = <Set<String>?>[];
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (char == '{' || char == '[') {
      stack.add(char == '{' ? <String>{} : null);
      if (stack.length > 8) _invalid();
    } else if (char == '}' || char == ']') {
      if (stack.isEmpty) _invalid();
      stack.removeLast();
    } else if (char == '"') {
      final start = i++;
      while (i < source.length && source[i] != '"') {
        if (source[i] == '\\') i++;
        i++;
      }
      if (i >= source.length) _invalid();
      var after = i + 1;
      while (after < source.length && source[after].trim().isEmpty) {
        after++;
      }
      if (after < source.length && source[after] == ':') {
        if (stack.isEmpty || stack.last == null) _invalid();
        final key = jsonDecode(source.substring(start, i + 1));
        if (key is! String || !stack.last!.add(key)) _invalid();
      }
    }
  }
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, Object?>) _invalid();
  return decoded;
}
