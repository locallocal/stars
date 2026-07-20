import 'dart:async';

import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';

abstract class AiProvider {
  AiProvider(this.bot);

  final Bot bot;
  StreamController<bool>? cancelController;
  bool isCancelled = false;
  bool webSearch = false;
  bool deepThinking = false;
  StreamResponseCallback onResponse = _ignoreResponse;
  StreamResponseCallback? onReasoningResponse;
  ToolCallCallback? onToolCall;
  CommandExecutionCallback? onCommandExecution;
  ProviderCompleteCallback? onComplete;
  ProviderErrorCallback? onError;
  ProviderTerminalCallback? onTerminal;
  ProviderTerminalType? _emittedTerminal;

  bool supportStreamResponse() => true;

  bool get supportsCancellation => true;

  bool supportWebSearch() => false;

  bool supportDeepThinking() => false;

  bool supportDeepResearch() => false;

  void setWebSearch(bool enabled) => webSearch = enabled;

  bool getWebSearch() => webSearch;

  void setDeepThinking(bool enabled) => deepThinking = enabled;

  bool getDeepThinking() => deepThinking;

  void setCallbacks({
    required StreamResponseCallback onResponse,
    StreamResponseCallback? onReasoningResponse,
    ToolCallCallback? onToolCall,
    CommandExecutionCallback? onCommandExecution,
    ProviderCompleteCallback? onComplete,
    ProviderErrorCallback? onError,
    ProviderTerminalCallback? onTerminal,
  }) {
    this.onResponse = onResponse;
    this.onReasoningResponse = onReasoningResponse;
    this.onToolCall = onToolCall;
    this.onCommandExecution = onCommandExecution;
    this.onTerminal = onTerminal;
    this.onComplete = () {
      final type =
          isCancelled
              ? ProviderTerminalType.cancelled
              : ProviderTerminalType.completed;
      _emitTerminalOnce(ProviderTerminalEvent(type: type));
      onComplete?.call();
    };
    this.onError = (String error) {
      final type =
          isCancelled
              ? ProviderTerminalType.cancelled
              : ProviderTerminalType.failed;
      _emitTerminalOnce(ProviderTerminalEvent(type: type, error: error));
      onError?.call(error);
    };
  }

  void _emitTerminalOnce(ProviderTerminalEvent event) {
    if (_emittedTerminal != null) return;
    _emittedTerminal = event.type;
    onTerminal?.call(event);
  }

  void emitToolCall(MessageToolCall toolCall) => onToolCall?.call(toolCall);

  void emitCommandExecution(MessageCommandExecution commandExecution) =>
      onCommandExecution?.call(commandExecution);

  List<InputModality> getInputModalites() => const [InputModality.text];

  List<OutputModality> getOutputModalites() => const [OutputModality.text];

  Future<List<String>> listModels() async => const [];

  Future<void> generateText(List<ChatMessage> messages);

  List<String> getSupportImageStyles() => const [];

  List<String> getSupportedImageSizes() => const [];

  Future<List<String>> generateImage(
    String prompt,
    String size,
    String imageDirPath, {
    List<String> referenceImages = const [],
    String style = '',
  }) {
    throw UnsupportedError('${bot.apiType} does not support image generation');
  }

  List<String> getSupportVoicTypes() => const [];

  Future<String> generateSpeech(
    String prompt,
    String voiceType,
    String outputDirPath,
  ) {
    throw UnsupportedError('${bot.apiType} does not support speech generation');
  }

  Future<String> generateMusic(
    String lyrics,
    String outputDirPath,
    String referMusic,
  ) {
    throw UnsupportedError('${bot.apiType} does not support music generation');
  }

  List<String> getSupportVideoResolutions() => const [];

  List<String> getSupportVideoRatios() => const [];

  Future<String> generateVideo(
    String prompt,
    String ratio,
    String outputDirPath,
    List<String> referImages,
  ) {
    throw UnsupportedError('${bot.apiType} does not support video generation');
  }

  Future<ProviderCancellationResult> cancelRequest() async {
    if (!supportsCancellation) {
      return const ProviderCancellationResult(
        ProviderCancellationStatus.unsupported,
      );
    }
    if (isCancelled) {
      return const ProviderCancellationResult(
        ProviderCancellationStatus.alreadyRequested,
      );
    }
    isCancelled = true;
    final controller = cancelController;
    if (controller != null && !controller.isClosed) controller.add(true);
    return const ProviderCancellationResult(
      ProviderCancellationStatus.requested,
    );
  }

  void resetCancelState() {
    isCancelled = false;
    _emittedTerminal = null;
    cancelController = StreamController<bool>();
  }
}

abstract interface class AiProviderRepository {
  AiProvider create(Bot bot);

  Future<List<String>> listModels(Bot bot);

  Future<List<String>> generateImage({
    required Bot bot,
    required String prompt,
    required String size,
    required String outputDirectory,
    required List<String> referenceImages,
    required String style,
  });

  Future<String> generateSpeech({
    required Bot bot,
    required String prompt,
    required String voiceType,
    required String outputDirectory,
  });

  Future<String> generateMusic({
    required Bot bot,
    required String prompt,
    required String outputDirectory,
    required String referenceMusic,
  });

  Future<String> generateVideo({
    required Bot bot,
    required String prompt,
    required String ratio,
    required String outputDirectory,
    required List<String> referenceImages,
  });
}

void _ignoreResponse(String _) {}
