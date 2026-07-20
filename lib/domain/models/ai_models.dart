import 'package:stars/domain/models/models.dart';

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    List<String> images = const [],
    List<String> files = const [],
  }) : images = List<String>.unmodifiable(images),
       files = List<String>.unmodifiable(files);

  final String role;
  final String content;
  final List<String> images;
  final List<String> files;
}

typedef StreamResponseCallback = void Function(String text);
typedef ToolCallCallback = void Function(MessageToolCall toolCall);
typedef CommandExecutionCallback =
    void Function(MessageCommandExecution commandExecution);
typedef ProviderCompleteCallback = void Function();
typedef ProviderErrorCallback = void Function(String error);

enum ProviderTerminalType { completed, cancelled, failed }

class ProviderTerminalEvent {
  const ProviderTerminalEvent({required this.type, this.error});

  final ProviderTerminalType type;
  final String? error;
}

typedef ProviderTerminalCallback = void Function(ProviderTerminalEvent event);

enum ProviderCancellationStatus { requested, alreadyRequested, unsupported }

class ProviderCancellationResult {
  const ProviderCancellationResult(this.status);

  final ProviderCancellationStatus status;

  bool get accepted =>
      status == ProviderCancellationStatus.requested ||
      status == ProviderCancellationStatus.alreadyRequested;
}
