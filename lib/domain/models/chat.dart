class Chat {
  static const int maxNameLength = 80;

  const Chat({
    required this.id,
    required this.botId,
    this.name = '',
    this.lastMessage = '',
    required this.lastMessageTimestamp,
    required this.createTimestamp,
    required this.modifyTimestamp,
  });

  final String id;
  final String botId;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final DateTime createTimestamp;
  final DateTime modifyTimestamp;

  String displayName(String fallback) {
    final normalizedName = name.trim();
    return normalizedName.isEmpty ? fallback : normalizedName;
  }

  Chat copyWith({
    String? name,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    DateTime? modifyTimestamp,
  }) {
    return Chat(
      id: id,
      botId: botId,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      createTimestamp: createTimestamp,
      modifyTimestamp: modifyTimestamp ?? this.modifyTimestamp,
    );
  }
}
