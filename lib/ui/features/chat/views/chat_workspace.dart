part of 'chat.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _ChatPageWorkspace on ChatPageState {
  Widget _buildDesktopWorkspace(BuildContext context, double? fontSize) {
    return Container(
      color: StarsDesktopTokens.of(context).contentBackground,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: StarsDesktopTokens.of(context).contentBackground,
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  StarsDesktopThemeSpec.formPagePadding.left,
                  0,
                  StarsDesktopThemeSpec.formPagePadding.right,
                  0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: StarsDesktopThemeSpec.contentMaxWidth,
                    ),
                    child: SizedBox(
                      key: const ValueKey<String>('desktop-chat-content'),
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildConversationBody(
                        context,
                        fontSize,
                        isDesktop: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildDesktopInputSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopInputSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        StarsDesktopThemeSpec.formPagePadding.left,
        8,
        StarsDesktopThemeSpec.formPagePadding.right,
        18,
      ),
      decoration: BoxDecoration(
        color: StarsDesktopTokens.of(context).contentBackground,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: StarsDesktopThemeSpec.contentMaxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAttachmentsBar(desktopMode: true),
              _buildToolApprovalCard(isDesktop: true),
              _buildGenerationAlert(isDesktop: true),
              MessageInput(
                provider: _provider,
                controller: _messageController,
                requestInProgress: _isTyping,
                canCancel: _isCancellable,
                isStopping: _isStopping,
                autofocus: _autofocusComposer,
                focusRequestToken: _composerFocusToken,
                hasPendingAttachments:
                    _selectedFiles.isNotEmpty || _selectedImages.isNotEmpty,
                desktopMode: true,
                onCameraPressed: getAttachImageFromCamera,
                onGalleryPressed: getAttachImageFromGallery,
                onFilePressed: getAttacheFile,
                onImageSizeSelected: (size) {
                  setState(() {
                    _selectedImageSize = size;
                  });
                },
                onImageStyleSelected: (style) {
                  setState(() {
                    _selectedImageStype = style;
                  });
                },
                onVideoRatioSelected: (ratio) {
                  setState(() {
                    _selectedVideoRatio = ratio;
                  });
                },
                onSend: _sendMessage,
                onCancelRequest: _cancelRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationBody(
    BuildContext context,
    double? fontSize, {
    bool isDesktop = false,
  }) {
    if (_isLoading) {
      return Center(
        child:
            isDesktop
                ? const SizedBox(width: 120, child: ShadProgress())
                : const CircularProgressIndicator(),
      );
    }
    if (_historyError != null && _messages.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ShadAlert.destructive(
            icon: Icon(
              isDesktop ? LucideIcons.circleAlert : Icons.error_outline,
            ),
            title: Text(S.of(context).unableToLoadMessages),
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_historyError!),
                const SizedBox(height: 12),
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: _loadMessages,
                  leading: const Icon(LucideIcons.refreshCw, size: 16),
                  child: Text(S.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final conversation =
        _messages.isEmpty
            ? WelcomeView(
              bot: widget.bot,
              fontSize: fontSize,
              isDesktop: isDesktop,
            )
            : Column(
              children: [
                MessageList(
                  messages: _messages,
                  messageRevision: _messageRevision,
                  scrollController: _scrollController,
                  isStreaming: _isStreaming,
                  streamingResponse: _streamingResponse,
                  streamingFiles: _streamingFiles,
                  streamingProcessInfo: _buildStreamingProcessInfo(),
                  streamingTokenUsage: _streamingTokenUsage,
                  currentUserId: _currentUserId,
                  deepThinking: _provider.getDeepThinking(),
                  reasoningResponse: _reasoningResponse,
                  isDesktop: isDesktop,
                  showExecutionStatus: widget.showExecutionStatus,
                  actionViewModel: _chatViewModel.messageActions,
                ),
                AssistantTypingIndicator(
                  botName: widget.bot.name,
                  isResponding: _isTyping,
                  isDesktop: isDesktop,
                ),
              ],
            );

    return Stack(
      children: [
        Positioned.fill(child: conversation),
        if (_showJumpToLatest && _messages.isNotEmpty)
          Positioned(
            right: isDesktop ? 20 : 12,
            bottom: _isTyping ? 60 : 12,
            child:
                isDesktop
                    ? ShadButton.secondary(
                      size: ShadButtonSize.sm,
                      onPressed: _jumpToLatest,
                      leading: const Icon(LucideIcons.arrowDown, size: 16),
                      child: Text(S.of(context).jumpToLatest),
                    )
                    : FilledButton.tonalIcon(
                      onPressed: _jumpToLatest,
                      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                      label: Text(S.of(context).jumpToLatest),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
          ),
      ],
    );
  }

  Widget _buildAttachmentsBar({bool desktopMode = false}) {
    if (_selectedFiles.isEmpty && _selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }
    return ImageAttachments(
      images: _selectedImages,
      files: _selectedFiles,
      desktopMode: desktopMode,
      onClearAll: () {
        setState(() {
          _selectedImages.clear();
          _selectedFiles.clear();
        });
        unawaited(_persistDraft());
      },
      onRemoveImage: (index) {
        setState(() {
          _selectedImages.removeAt(index);
        });
        unawaited(_persistDraft());
      },
      onRemoveFile: (index) {
        setState(() {
          _selectedFiles.removeAt(index);
        });
        unawaited(_persistDraft());
      },
    );
  }

  Widget _buildGenerationAlert({required bool isDesktop}) {
    final error = _generationError;
    if (error == null || error.isEmpty) return const SizedBox.shrink();

    return ChatGenerationErrorAlert(
      error: error,
      isDesktop: isDesktop,
      onDismiss: _dismissGenerationError,
    );
  }

  Widget _buildToolApprovalCard({required bool isDesktop}) {
    final approval = _generationViewModel.snapshot.pendingToolApproval;
    if (approval == null) return const SizedBox.shrink();
    return ToolApprovalCard(
      request: approval,
      desktopMode: isDesktop,
      onDecision: _generationViewModel.resolveToolApproval,
    );
  }

  void _dismissGenerationError() {
    setState(() {
      _generationError = null;
    });
  }
}
