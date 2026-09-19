import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';

enum MediaTurnKind { image, speech, music, video }

final class MediaTurnRequest {
  const MediaTurnRequest({
    required this.kind,
    required this.chatId,
    required this.bot,
    required this.currentUserId,
    required this.prompt,
    required this.generatedPreview,
    required this.resultDetail,
    this.sourceImagePaths = const [],
    this.sourceFilePaths = const [],
    this.attachmentDetail = '',
    this.imageSize = '',
    this.imageStyle = '',
    this.videoRatio = '',
    this.voiceType = '',
  });

  final MediaTurnKind kind;
  final String chatId;
  final Bot bot;
  final String currentUserId;
  final String prompt;
  final String generatedPreview;
  final String resultDetail;
  final List<String> sourceImagePaths;
  final List<String> sourceFilePaths;
  final String attachmentDetail;
  final String imageSize;
  final String imageStyle;
  final String videoRatio;
  final String voiceType;
}

final class MediaTurnResult {
  const MediaTurnResult({required this.userMessage, required this.response});

  final Message userMessage;
  final Message response;
}

final class MediaTurnFailure implements Exception {
  const MediaTurnFailure({
    required this.cause,
    this.userMessage,
    this.terminalMessage,
  });

  final Object cause;
  final Message? userMessage;
  final Message? terminalMessage;

  @override
  String toString() => cause.toString();
}

typedef MediaUserPersisted = void Function(Message message);

/// Owns the complete user/assistant lifecycle for non-text media turns.
final class GenerateMediaTurn {
  GenerateMediaTurn({
    required MessageRepository messageRepository,
    required ChatRepository chatRepository,
    required AiProviderRepository providerRepository,
    required AttachmentRepository attachmentRepository,
    required PersistConversationAssets persistConversationAssets,
  }) : _messages = messageRepository,
       _chats = chatRepository,
       _providers = providerRepository,
       _attachments = attachmentRepository,
       _persistAssets = persistConversationAssets;

  final MessageRepository _messages;
  final ChatRepository _chats;
  final AiProviderRepository _providers;
  final AttachmentRepository _attachments;
  final PersistConversationAssets _persistAssets;

  Future<MediaTurnResult> call(
    MediaTurnRequest request, {
    MediaUserPersisted? onUserPersisted,
  }) async {
    final runId = _messages.createId('run');
    final turnId = _messages.createId('turn');
    final stopwatch = Stopwatch()..start();
    Message? userMessage;
    try {
      final assets = await _persistRequestAssets(request);
      userMessage = _buildUserMessage(request, runId, turnId, assets);
      userMessage = await _messages.upsertMessage(userMessage);
      onUserPersisted?.call(userMessage);
      await _updatePreviewBestEffort(request.chatId, userMessage.content);

      final outputDirectory = await _outputDirectory(request.chatId);
      final output = await _generate(request, assets, outputDirectory);
      stopwatch.stop();
      final response = await _messages.upsertMessage(
        _buildResponseMessage(
          request,
          runId,
          turnId,
          output,
          stopwatch.elapsedMilliseconds,
        ),
      );
      await _updatePreviewBestEffort(request.chatId, request.generatedPreview);
      return MediaTurnResult(userMessage: userMessage, response: response);
    } on Object catch (error) {
      stopwatch.stop();
      Message? failed;
      if (userMessage != null) {
        try {
          failed = await _messages.upsertMessage(
            Message(
              messageId: '$runId:assistant',
              turnId: turnId,
              runId: runId,
              chatId: request.chatId,
              botId: request.bot.id,
              senderId: request.bot.id,
              content: '',
              processInfo: MessageProcessInfo(
                durationMs: stopwatch.elapsedMilliseconds,
              ),
              terminalOutcome: MessageTerminalOutcome.failed,
              timestamp: DateTime.now(),
            ),
          );
        } on Object {
          // The original provider/storage error remains the primary failure.
        }
      }
      throw MediaTurnFailure(
        cause: error,
        userMessage: userMessage,
        terminalMessage: failed,
      );
    }
  }

  Future<List<String>> _persistRequestAssets(MediaTurnRequest request) {
    final sources = switch (request.kind) {
      MediaTurnKind.image || MediaTurnKind.video => request.sourceImagePaths,
      MediaTurnKind.music => request.sourceFilePaths,
      MediaTurnKind.speech => const <String>[],
    };
    return _persistAssets(chatId: request.chatId, sourcePaths: sources);
  }

  Message _buildUserMessage(
    MediaTurnRequest request,
    String runId,
    String turnId,
    List<String> assets,
  ) {
    final type = switch (request.kind) {
      MediaTurnKind.image || MediaTurnKind.video => 'image',
      MediaTurnKind.music => 'music',
      MediaTurnKind.speech => '',
    };
    return Message(
      messageId: '$runId:user',
      turnId: turnId,
      runId: runId,
      chatId: request.chatId,
      botId: request.bot.id,
      senderId: request.currentUserId,
      content: request.prompt,
      images:
          request.kind == MediaTurnKind.image ||
                  request.kind == MediaTurnKind.video
              ? assets
              : const [],
      music:
          request.kind == MediaTurnKind.music && assets.isNotEmpty
              ? assets.first
              : '',
      processInfo: MessageProcessInfo(
        fileEdits: [
          for (final asset in assets)
            MessageFileEdit(
              path: asset,
              type: type,
              status: 'attached',
              detail: request.attachmentDetail,
            ),
        ],
      ),
      timestamp: DateTime.now(),
    );
  }

  Future<Object> _generate(
    MediaTurnRequest request,
    List<String> assets,
    String outputDirectory,
  ) {
    final providers = _providers.forConversation(request.chatId);
    return switch (request.kind) {
      MediaTurnKind.image => providers.generateImage(
        bot: request.bot,
        prompt: request.prompt,
        size: request.imageSize,
        outputDirectory: outputDirectory,
        referenceImages: assets,
        style: request.imageStyle,
      ),
      MediaTurnKind.speech => providers.generateSpeech(
        bot: request.bot,
        prompt: request.prompt,
        voiceType: _voiceType(request),
        outputDirectory: outputDirectory,
      ),
      MediaTurnKind.music => providers.generateMusic(
        bot: request.bot,
        prompt: request.prompt,
        outputDirectory: outputDirectory,
        referenceMusic: assets.isEmpty ? '' : assets.first,
      ),
      MediaTurnKind.video => providers.generateVideo(
        bot: request.bot,
        prompt: request.prompt,
        ratio: request.videoRatio,
        outputDirectory: outputDirectory,
        referenceImages: assets,
      ),
    };
  }

  String _voiceType(MediaTurnRequest request) {
    if (request.voiceType.isNotEmpty) return request.voiceType;
    try {
      final voices = _providers.create(request.bot).getSupportVoicTypes();
      return voices.isEmpty ? '' : voices.first;
    } on Object {
      return '';
    }
  }

  Message _buildResponseMessage(
    MediaTurnRequest request,
    String runId,
    String turnId,
    Object output,
    int durationMs,
  ) {
    final paths = output is List<String> ? output : <String>[output as String];
    final type = request.kind.name;
    return Message(
      messageId: '$runId:assistant',
      turnId: turnId,
      runId: runId,
      chatId: request.chatId,
      botId: request.bot.id,
      senderId: request.bot.id,
      content: '',
      images: request.kind == MediaTurnKind.image ? paths : const [],
      audio:
          request.kind == MediaTurnKind.speech ||
                  request.kind == MediaTurnKind.music
              ? paths.first
              : '',
      video: request.kind == MediaTurnKind.video ? paths.first : '',
      processInfo: MessageProcessInfo(
        durationMs: durationMs,
        fileEdits: [
          for (final path in paths)
            MessageFileEdit(
              path: path,
              type: type,
              status: 'created',
              detail: request.resultDetail,
            ),
        ],
      ),
      terminalOutcome: MessageTerminalOutcome.completed,
      timestamp: DateTime.now(),
    );
  }

  Future<String> _outputDirectory(String chatId) {
    final attachments = _attachments;
    if (attachments is! ConversationAssetRepository) {
      throw const AppFailure.storage('conversation_asset_store_unavailable');
    }
    return attachments.getOutputDirectory(chatId);
  }

  Future<void> _updatePreviewBestEffort(String chatId, String content) async {
    try {
      await _chats.updateLastMessage(chatId, content);
    } on Object {
      // Message persistence is authoritative; preview can be rebuilt later.
    }
  }
}
