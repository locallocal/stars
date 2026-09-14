/// Explicit message semantics; null denotes a non-task message.
enum TaskMessageKind {
  directReply,
  acknowledgement,
  status,
  result;

  String get storageName => switch (this) {
    directReply => 'directReply',
    acknowledgement => 'taskAcknowledgement',
    status => 'taskStatus',
    result => 'taskResult',
  };

  static TaskMessageKind fromStorage(String value) => switch (value) {
    'directReply' => directReply,
    'taskAcknowledgement' => acknowledgement,
    'taskStatus' => status,
    'taskResult' => result,
    _ => throw FormatException('Unknown task message kind.'),
  };

  bool get participatesInAnswerTrust => this == directReply || this == result;
}

abstract final class ConversationMessageIdentity {
  static String directReply(String turnId) => '${_id(turnId)}:assistant';
  static String acknowledgement(String taskId) => '${_id(taskId)}:ack';
  static String result(String taskId) => '${_id(taskId)}:result';

  static String _id(String value) {
    if (value.isEmpty || value.trim() != value) {
      throw ArgumentError('Message identity requires a normalized identifier.');
    }
    return value;
  }
}
