part of 'chat.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _ChatPageDraftAndMedia on ChatPageState {
  void _restorePendingDraft() {
    final text = _pendingDraftText;
    if (text != null && _messageController.text.isEmpty) {
      _messageController.text = text;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    }
    if (_selectedImages.isEmpty) {
      _selectedImages.addAll(_pendingDraftImages);
    }
    if (_selectedFiles.isEmpty) {
      _selectedFiles.addAll(_pendingDraftFiles);
    }
    _pendingDraftText = null;
    _pendingDraftImages = const [];
    _pendingDraftFiles = const [];
    unawaited(_persistDraft());
  }

  void _clearPendingDraft() {
    _pendingDraftText = null;
    _pendingDraftImages = const [];
    _pendingDraftFiles = const [];
    if (_messageController.text.isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedFiles.isNotEmpty) {
      unawaited(_persistDraft());
    } else {
      unawaited(_chatViewModel.deleteDraft());
    }
  }

  Future<(List<String>, List<String>)> _persistSelectedAttachments() async {
    final imageSources = _selectedImages.map((image) => image.path).toList();
    final fileSources = _selectedFiles.map((file) => file.path).toList();
    final persisted = await _chatViewModel.persistAssets([
      ...imageSources,
      ...fileSources,
    ]);
    return (
      List<String>.unmodifiable(persisted.take(imageSources.length)),
      List<String>.unmodifiable(persisted.skip(imageSources.length)),
    );
  }

  Future<void> _generateImage() => _runMediaTurn(
    kind: MediaTurnKind.image,
    emptyPromptMessage: S.of(context).pleaseEnterImageDescription,
    attachmentDetail: S.of(context).imageAttachment,
    resultDetail: S.of(context).imageResult,
    generatedPreview: S.of(context).generatedImage,
  );

  Future<void> _generateSpeech() => _runMediaTurn(
    kind: MediaTurnKind.speech,
    emptyPromptMessage: S.of(context).pleaseEnterSpeechDescription,
    resultDetail: S.of(context).speechResult,
    generatedPreview: S.of(context).speechGenerated,
  );

  Future<void> _generateMusic() => _runMediaTurn(
    kind: MediaTurnKind.music,
    emptyPromptMessage: S.of(context).pleaseEnterMusicDescription,
    attachmentDetail: S.of(context).referenceAudio,
    resultDetail: S.of(context).musicResult,
    generatedPreview: S.of(context).musicGenerated,
  );

  Future<void> _generateVideo() => _runMediaTurn(
    kind: MediaTurnKind.video,
    emptyPromptMessage: S.of(context).pleaseEnterVideoDescription,
    attachmentDetail: S.of(context).imageAttachment,
    resultDetail: S.of(context).videoResult,
    generatedPreview: S.of(context).videoGenerated,
  );

  Future<void> _runMediaTurn({
    required MediaTurnKind kind,
    required String emptyPromptMessage,
    required String resultDetail,
    required String generatedPreview,
    String attachmentDetail = '',
  }) async {
    final prompt = _messageController.text.trim();
    if (prompt.isEmpty) {
      showStarsNotice(context, emptyPromptMessage);
      return;
    }
    final originalImages = List<File>.of(_selectedImages);
    final originalFiles = List<File>.of(_selectedFiles);
    _beginMediaRun(widget.id);
    var userShown = false;

    try {
      final result = await _chatViewModel.generateMediaTurn(
        MediaTurnRequest(
          kind: kind,
          chatId: widget.id,
          bot: widget.bot,
          currentUserId: _currentUserId,
          prompt: prompt,
          generatedPreview: generatedPreview,
          resultDetail: resultDetail,
          attachmentDetail: attachmentDetail,
          sourceImagePaths: [for (final image in originalImages) image.path],
          sourceFilePaths: [for (final file in originalFiles) file.path],
          imageSize: _selectedImageSize,
          imageStyle: _selectedImageStype,
          videoRatio: _selectedVideoRatio,
        ),
        onUserPersisted: (message) {
          userShown = true;
          if (!mounted) return;
          setState(() {
            _messages.add(message);
            _messageRevision += 1;
            _messageController.clear();
            if (kind == MediaTurnKind.image || kind == MediaTurnKind.video) {
              _selectedImages.clear();
            }
            if (kind == MediaTurnKind.music) _selectedFiles.clear();
          });
          if (_messageController.text.isNotEmpty ||
              _selectedImages.isNotEmpty ||
              _selectedFiles.isNotEmpty) {
            unawaited(_persistDraft());
          } else {
            unawaited(_chatViewModel.deleteDraft());
          }
          _scheduleScrollToLatest(animate: true);
        },
      );
      if (!mounted) return;
      setState(() {
        if (!userShown) {
          _messages.add(result.userMessage);
        }
        _messages.add(result.response);
        _messageRevision += userShown ? 1 : 2;
      });
      _chatViewModel.notifyChatListChanged();
      _scheduleScrollToLatest(animate: true);
    } on MediaTurnFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        if (!userShown && failure.userMessage == null) {
          if (_messageController.text.isEmpty) {
            _messageController.text = prompt;
          }
          if (_selectedImages.isEmpty) {
            _selectedImages.addAll(originalImages);
          }
          if (_selectedFiles.isEmpty) {
            _selectedFiles.addAll(originalFiles);
          }
        }
        final terminal = failure.terminalMessage;
        if (terminal != null &&
            !_messages.any(
              (message) => message.messageId == terminal.messageId,
            )) {
          _messages.add(terminal);
          _messageRevision += 1;
        }
        _generationError = switch (kind) {
          MediaTurnKind.image => S
              .of(context)
              .generateImageFailed(safeFailureMessage(context, failure.cause)),
          MediaTurnKind.speech => S
              .of(context)
              .generateSpeechFailed(safeFailureMessage(context, failure.cause)),
          MediaTurnKind.music => S
              .of(context)
              .generateMusicFailed(safeFailureMessage(context, failure.cause)),
          MediaTurnKind.video => S
              .of(context)
              .generateVideoFailed(safeFailureMessage(context, failure.cause)),
        };
      });
      unawaited(_persistDraft());
    } finally {
      _finishMediaRun(widget.id);
    }
  }
}
