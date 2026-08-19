part of 'chat.dart';

extension ChatPageSendCommands on ChatPageState {
  // 从相机获取图片
  Future<void> getAttachImageFromCamera() async {
    await _addSelectedImage(_chatViewModel.captureImage);
  }

  // 从相册获取图片
  Future<void> getAttachImageFromGallery() async {
    await _addSelectedImage(_chatViewModel.selectImage);
  }

  Future<void> _addSelectedImage(Future<String?> Function() pickImage) async {
    try {
      final imagePath = await pickImage();
      if (imagePath != null && mounted) {
        _updateState(() {
          _selectedImages.add(File(imagePath));
        });
        unawaited(_persistDraft());
      }
    } on Object catch (error) {
      if (mounted) {
        showStarsNotice(
          context,
          safeFailureMessage(context, error),
          tone: StarsNoticeTone.error,
        );
      }
    }
  }

  // 获取文件
  Future<void> getAttacheFile() async {
    final filePath = await _chatViewModel.selectFile();
    if (filePath != null && mounted) {
      _updateState(() {
        _selectedFiles.add(File(filePath));
      });
      unawaited(_persistDraft());
    }
  }

  Future<void> _sendMessage() async {
    if (_isTyping) {
      return;
    }
    if (_generationError != null) {
      _updateState(() {
        _generationError = null;
      });
    }
    if (_provider.getOutputModalites().contains(OutputModality.image) &&
        _selectedImageSize.isNotEmpty) {
      await _generateImage();
      return;
    } else if (_provider.getOutputModalites().contains(OutputModality.speech)) {
      await _generateSpeech();
      return;
    } else if (_provider.getOutputModalites().contains(OutputModality.music)) {
      await _generateMusic();
      return;
    } else if (_provider.getOutputModalites().contains(OutputModality.video)) {
      await _generateVideo();
      return;
    }
    await _generateText();
  }

  Future<void> _generateText() async {
    final bool hasText = _messageController.text.trim().isNotEmpty;
    final bool hasImages = _selectedImages.isNotEmpty;
    final bool hasFiles = _selectedFiles.isNotEmpty;
    if (!hasText && !hasImages && !hasFiles) return;

    final messageText = _messageController.text;
    final imageAttachmentDetail = S.of(context).imageAttachment;
    final fileAttachmentDetail = S.of(context).fileAttachment;
    final history = List<Message>.of(_messages);
    _pendingDraftText = messageText;
    _pendingDraftImages = List<File>.of(_selectedImages);
    _pendingDraftFiles = List<File>.of(_selectedFiles);
    await _persistDraft();
    String? optimisticMessageId;
    try {
      final (imagePaths, filePaths) = await _persistSelectedAttachments();

      final userMessage = _chatViewModel.createUserMessage(
        currentUserId: _currentUserId,
        content: messageText,
        imagePaths: imagePaths,
        filePaths: filePaths,
        imageDetail: imageAttachmentDetail,
        fileDetail: fileAttachmentDetail,
      );
      optimisticMessageId = userMessage.messageId;

      if (mounted) {
        _updateState(() {
          _messages.add(userMessage);
          _messageRevision += 1;
          _messageController.clear();
          _generationError = null;
          _streamingResponse = '';
          _selectedImages.clear();
          _selectedFiles.clear();
          _followLatest = true;
          _showJumpToLatest = false;
        });
        _scheduleScrollToLatest(force: true, animate: true);
      }

      final started = await _generationViewModel.startTextWithPreparation(
        userMessage: userMessage,
        prepare:
            (identifiedUserMessage) => _chatViewModel.prepareTextGeneration(
              history: history,
              userMessage: identifiedUserMessage,
              currentUserId: _currentUserId,
            ),
      );
      if (started || _generationViewModel.snapshot.userPersisted) {
        _clearPendingDraft();
      }
    } catch (error) {
      if (mounted) {
        _updateState(() {
          if (optimisticMessageId != null) {
            final previousLength = _messages.length;
            _messages.removeWhere(
              (message) => message.messageId == optimisticMessageId,
            );
            if (_messages.length != previousLength) _messageRevision += 1;
          }
          _restorePendingDraft();
          _generationError = safeFailureMessage(context, error);
        });
      }
    } finally {
      if (mounted && !_generationViewModel.snapshot.lifecycle.isRunning) {
        _updateState(() {
          _isTyping = false;
          _isCancellable = false;
          _isStopping = false;
        });
      }
    }
  }
}
