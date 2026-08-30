import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path_context;
import 'package:intl/intl.dart' as intl;
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/views/audio_player_widget.dart';
import 'package:stars/ui/features/chat/views/video_player_widget.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:shadcn_ui/shadcn_ui.dart';

part 'message_list_actions.dart';
part 'message_list_bubble.dart';
part 'message_list_file_preview.dart';
part 'message_list_media_preview.dart';
part 'message_list_process.dart';
part 'message_list_process_labels.dart';
part 'message_list_reasoning.dart';
part 'message_list_status.dart';

class MessageList extends StatefulWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final bool isStreaming;
  final String streamingResponse;
  final List<String> streamingFiles;
  final MessageProcessInfo streamingProcessInfo;
  final ModelTokenUsage streamingTokenUsage;
  final String currentUserId;
  final bool? deepThinking;
  final String? reasoningResponse;
  final bool isDesktop;
  final bool showExecutionStatus;
  final int messageRevision;
  final MessageActionViewModel? actionViewModel;

  const MessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isStreaming,
    required this.streamingResponse,
    this.streamingFiles = const [],
    this.streamingProcessInfo = const MessageProcessInfo(),
    this.streamingTokenUsage = ModelTokenUsage.empty,
    required this.currentUserId,
    this.deepThinking = false,
    this.reasoningResponse = '',
    this.isDesktop = false,
    this.showExecutionStatus = true,
    this.messageRevision = 0,
    this.actionViewModel,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late List<MessageProcessInfo> _displayedProcessInfo;
  List<MessageSkillActivation> _streamingSkillActivations = const [];
  List<MessageToolCall> _streamingSkillToolCalls = const [];

  List<Message> get messages => widget.messages;
  ScrollController get scrollController => widget.scrollController;
  bool get isStreaming => widget.isStreaming;
  String get streamingResponse => widget.streamingResponse;
  MessageProcessInfo get streamingProcessInfo => widget.streamingProcessInfo;
  ModelTokenUsage get streamingTokenUsage => widget.streamingTokenUsage;
  String get currentUserId => widget.currentUserId;
  bool? get deepThinking => widget.deepThinking;
  String? get reasoningResponse => widget.reasoningResponse;
  bool get isDesktop => widget.isDesktop;
  bool get showExecutionStatus => widget.showExecutionStatus;

  @override
  void initState() {
    super.initState();
    _indexMessagePresentation();
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageRevision != widget.messageRevision ||
        oldWidget.currentUserId != widget.currentUserId ||
        !identical(oldWidget.messages, widget.messages)) {
      _indexMessagePresentation();
    }
  }

  void _indexMessagePresentation() {
    final displayedProcessInfo = <MessageProcessInfo>[
      for (final message in messages) message.processInfo,
    ];
    var streamingSkillActivations = const <MessageSkillActivation>[];
    var streamingSkillToolCalls = const <MessageToolCall>[];

    Message? pendingUserMessage;
    var pendingSkillActivations = const <MessageSkillActivation>[];
    var pendingSkillToolCalls = const <MessageToolCall>[];

    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      final isCurrentUser = message.senderId == currentUserId;

      if (isCurrentUser) {
        pendingUserMessage = message;
        pendingSkillActivations = message.processInfo.skillActivations;
        pendingSkillToolCalls = _skillToolCalls(message.processInfo.toolCalls);
        displayedProcessInfo[index] = _replaceSkillActivations(
          message.processInfo,
          const [],
        );
        continue;
      }

      if (pendingUserMessage != null &&
          _messagesBelongToSameTurn(pendingUserMessage, message)) {
        displayedProcessInfo[index] = _replaceSkillActivations(
          _replaceToolCalls(
            message.processInfo,
            _mergeToolCalls(
              message.processInfo.toolCalls,
              pendingSkillToolCalls,
            ),
          ),
          _mergeSkillActivations(
            message.processInfo.skillActivations,
            pendingSkillActivations,
          ),
        );
        pendingUserMessage = null;
        pendingSkillActivations = const [];
        pendingSkillToolCalls = const [];
      }
    }
    streamingSkillActivations = pendingSkillActivations;
    streamingSkillToolCalls = pendingSkillToolCalls;
    _displayedProcessInfo = displayedProcessInfo;
    _streamingSkillActivations = streamingSkillActivations;
    _streamingSkillToolCalls = streamingSkillToolCalls;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        reverse: true,
        itemCount: messages.length + (isStreaming ? 1 : 0),
        padding: EdgeInsets.fromLTRB(
          0,
          isDesktop ? 12 : 8,
          0,
          isDesktop ? 36 : 8,
        ),
        itemBuilder: (context, index) {
          if (isStreaming && index == 0) {
            return RepaintBoundary(
              key: const ValueKey<String>('streaming-message'),
              child: _buildMessageRow(
                context,
                bubble: _MessageBubble(
                  isCurrentUser: false,
                  isDesktop: isDesktop,
                  isStreaming: true,
                  reasoning:
                      deepThinking == true ? reasoningResponse ?? '' : '',
                  processInfo: _replaceSkillActivations(
                    _replaceToolCalls(
                      streamingProcessInfo,
                      _mergeToolCalls(
                        streamingProcessInfo.toolCalls,
                        _streamingSkillToolCalls,
                      ),
                    ),
                    _mergeSkillActivations(
                      streamingProcessInfo.skillActivations,
                      _streamingSkillActivations,
                    ),
                  ),
                  tokenUsage: streamingTokenUsage,
                  showExecutionStatus: showExecutionStatus,
                  content: streamingResponse,
                  files: _localFilesFromMarkdown(
                    streamingResponse,
                    widget.streamingFiles,
                  ),
                  actionViewModel: widget.actionViewModel,
                ),
              ),
            );
          }

          final messageIndex =
              messages.length - 1 - index + (isStreaming ? 1 : 0);
          final message = messages[messageIndex];
          final isMe = message.senderId == currentUserId;
          final bubble = _MessageBubble(
            isCurrentUser: isMe,
            isDesktop: isDesktop,
            reasoning: message.reasoning,
            processInfo: _displayedProcessInfo[messageIndex],
            tokenUsage: message.tokenUsage,
            showExecutionStatus: showExecutionStatus && !isMe,
            content: message.content,
            images: message.images,
            files:
                isMe
                    ? message.files
                    : _localFilesFromMarkdown(message.content, message.files),
            audio: message.audio,
            music: message.music,
            video: message.video,
            terminalOutcome: message.terminalOutcome,
            hasPartialContent: message.hasPartialContent,
            actionViewModel: widget.actionViewModel,
          );
          return RepaintBoundary(
            key: ValueKey<String>(
              message.messageId.isEmpty
                  ? 'legacy-${message.timestamp.microsecondsSinceEpoch}-$messageIndex'
                  : message.messageId,
            ),
            child: _buildMessageRow(
              context,
              isCurrentUser: isMe,
              bubble:
                  isDesktop
                      ? _DesktopMessageActions(
                        content: message.content,
                        isCurrentUser: isMe,
                        timestamp: message.timestamp,
                        child: bubble,
                      )
                      : GestureDetector(
                        onLongPress:
                            message.content.isEmpty
                                ? null
                                : () {
                                  Clipboard.setData(
                                    ClipboardData(text: message.content),
                                  );
                                },
                        child: bubble,
                      ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context, {
    required Widget bubble,
    bool isCurrentUser = false,
  }) {
    final viewportMaxWidth =
        isDesktop ? StarsDesktopThemeSpec.contentMaxWidth : double.infinity;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 10 : 4),
      child: Center(
        child: ConstrainedBox(
          key:
              isDesktop
                  ? const ValueKey<String>('desktop-message-viewport')
                  : null,
          constraints: BoxConstraints(maxWidth: viewportMaxWidth),
          child: Align(
            alignment:
                isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    isDesktop
                        ? (isCurrentUser
                            ? StarsDesktopThemeSpec.messageBubbleMaxWidth
                            : StarsDesktopThemeSpec.contentMaxWidth)
                        : MediaQuery.of(context).size.width * 0.8,
              ),
              child: bubble,
            ),
          ),
        ),
      ),
    );
  }
}

MessageProcessInfo _replaceSkillActivations(
  MessageProcessInfo processInfo,
  List<MessageSkillActivation> skillActivations,
) {
  if (identical(processInfo.skillActivations, skillActivations)) {
    return processInfo;
  }
  return MessageProcessInfo(
    reasoningStatus: processInfo.reasoningStatus,
    durationMs: processInfo.durationMs,
    toolCalls: processInfo.toolCalls,
    commandExecutions: processInfo.commandExecutions,
    fileEdits: processInfo.fileEdits,
    skillActivations: skillActivations,
  );
}

MessageProcessInfo _replaceToolCalls(
  MessageProcessInfo processInfo,
  List<MessageToolCall> toolCalls,
) {
  if (identical(processInfo.toolCalls, toolCalls)) return processInfo;
  return MessageProcessInfo(
    reasoningStatus: processInfo.reasoningStatus,
    durationMs: processInfo.durationMs,
    toolCalls: toolCalls,
    commandExecutions: processInfo.commandExecutions,
    fileEdits: processInfo.fileEdits,
    skillActivations: processInfo.skillActivations,
  );
}

List<MessageToolCall> _skillToolCalls(List<MessageToolCall> toolCalls) =>
    List<MessageToolCall>.unmodifiable(
      toolCalls.where(
        (call) =>
            call.name == 'activate_skill' || call.name == 'read_skill_resource',
      ),
    );

List<MessageToolCall> _mergeToolCalls(
  List<MessageToolCall> responseCalls,
  List<MessageToolCall> userSkillCalls,
) {
  if (userSkillCalls.isEmpty) return responseCalls;
  if (responseCalls.isEmpty) return userSkillCalls;

  final merged = <MessageToolCall>[...responseCalls];
  for (final call in userSkillCalls) {
    final alreadyIncluded = merged.any(
      (item) =>
          item.callId == call.callId &&
          item.name == call.name &&
          item.status == call.status &&
          item.detail == call.detail,
    );
    if (!alreadyIncluded) merged.add(call);
  }
  return List<MessageToolCall>.unmodifiable(merged);
}

List<MessageSkillActivation> _mergeSkillActivations(
  List<MessageSkillActivation> responseActivations,
  List<MessageSkillActivation> userActivations,
) {
  if (userActivations.isEmpty) return responseActivations;
  if (responseActivations.isEmpty) return userActivations;

  final merged = <MessageSkillActivation>[...responseActivations];
  for (final activation in userActivations) {
    final alreadyIncluded = merged.any(
      (item) =>
          item.name == activation.name &&
          item.contentDigest == activation.contentDigest &&
          item.trigger == activation.trigger,
    );
    if (!alreadyIncluded) merged.add(activation);
  }
  return List<MessageSkillActivation>.unmodifiable(merged);
}

bool _messagesBelongToSameTurn(Message userMessage, Message responseMessage) {
  if (userMessage.turnId.isNotEmpty && responseMessage.turnId.isNotEmpty) {
    return userMessage.turnId == responseMessage.turnId;
  }
  if (userMessage.runId.isNotEmpty && responseMessage.runId.isNotEmpty) {
    return userMessage.runId == responseMessage.runId;
  }
  return true;
}
