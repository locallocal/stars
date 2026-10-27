import 'dart:math';

/// Random identities do not depend on clock resolution or a stale inventory.
String newMcpServerId() {
  final random = Random.secure();
  final suffix =
      List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
  return 'mcp-$suffix';
}
