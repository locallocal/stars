part of 'message_list.dart';

const double _mobileMessageImagePreviewSize = 136;

class _MessageContent extends StatelessWidget {
  final bool isCurrentUser;
  final bool isDesktop;
  final bool isStreaming;
  final String reasoning;
  final MessageProcessInfo processInfo;
  final ModelTokenUsage tokenUsage;
  final bool showReasoning;
  final bool showVerificationStatus;
  final bool showExecutionStatus;
  final String content;
  final List<String> images;
  final List<String> files;
  final Message? sourceMessage;
  final String audio;
  final String music;
  final String video;
  final MessageGrounding? grounding;
  final bool strictGroundingMode;
  final String strictGroundingNotice;
  final bool hasNotFactCheckedContent;
  final String exportTrustAnnotation;
  final MessageTerminalOutcome? terminalOutcome;
  final bool hasPartialContent;
  final MessageActionViewModel? actionViewModel;

  const _MessageContent({
    required this.isCurrentUser,
    required this.isDesktop,
    this.isStreaming = false,
    required this.reasoning,
    this.processInfo = const MessageProcessInfo(),
    this.tokenUsage = ModelTokenUsage.empty,
    this.showReasoning = true,
    this.showVerificationStatus = true,
    this.showExecutionStatus = true,
    required this.content,
    this.images = const [],
    this.files = const [],
    this.sourceMessage,
    this.audio = '',
    this.music = '',
    this.video = '',
    this.grounding,
    this.strictGroundingMode = false,
    this.strictGroundingNotice = '',
    this.hasNotFactCheckedContent = false,
    this.exportTrustAnnotation = '',
    this.terminalOutcome,
    this.hasPartialContent = false,
    this.actionViewModel,
  });

  @override
  Widget build(BuildContext context) => _MessageLocalFilesBuilder(
    content: content,
    files: files,
    sourceMessage: sourceMessage,
    isCurrentUser: isCurrentUser,
    isStreaming: isStreaming,
    actions: actionViewModel,
    builder: _buildContent,
  );

  Widget _buildContent(BuildContext context, List<String> localFiles) {
    final metadata = <Widget>[
      if (!isCurrentUser && localFiles.isNotEmpty)
        _MessageFileSection(
          key: const ValueKey<String>('message-file-results'),
          files: localFiles,
          isCurrentUser: false,
          isDesktop: isDesktop,
          actions: actionViewModel,
        ),
      if (strictGroundingNotice.isNotEmpty)
        ExecutionStatusCard(
          key: const ValueKey<String>('message-strict-grounding-notice'),
          isDesktop: isDesktop,
          icon: LucideIcons.shieldCheck,
          title: S.of(context).strictGroundingMode,
          subtitle: '',
          child: MarkdownBody(
            data: strictGroundingNotice,
            selectable: true,
            styleSheet: _buildMarkdownStyleSheet(
              context,
              Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14,
            ),
          ),
        ),
      if (_showTrustStatus)
        _MessageTrustStatus(
          key: const ValueKey<String>('message-verification'),
          grounding: grounding!,
          isDesktop: isDesktop,
          strictMode: strictGroundingMode,
          hasNotFactCheckedContent: hasNotFactCheckedContent,
          actionViewModel: actionViewModel,
        ),
      if (_showTerminalStatus)
        _MessageTerminalStatus(
          outcome: terminalOutcome!,
          hasPartialContent: hasPartialContent,
          reasonCode: grounding?.reasonCode ?? '',
        ),
      if (_showProcessInfo)
        ProcessInfoSection(
          key: const ValueKey<String>('message-execution'),
          processInfo: processInfo,
          tokenUsage: tokenUsage,
          isDesktop: isDesktop,
          isStreaming: isStreaming,
          hasReasoningContent: _showReasoning,
          grounding: grounding,
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        if (_showReasoning)
          ReasoningSection(
            key: const ValueKey<String>('message-reasoning'),
            reasoning: reasoning,
            isDesktop: isDesktop,
            isStreaming: isStreaming,
            durationMs: processInfo.durationMs,
            actionViewModel: actionViewModel,
          ),
        if (content.isNotEmpty || _hasStructuredMedia)
          _MessageBubbleSurface(
            isCurrentUser: isCurrentUser,
            isDesktop: isDesktop,
            child: _buildBody(context, localFiles),
          ),
        if (metadata.isNotEmpty)
          _MessageMetadata(
            key: const ValueKey<String>('message-metadata'),
            children: metadata,
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, List<String> localFiles) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14;
    final urlPreviews =
        isStreaming
            ? const <_UrlPreviewDescriptor>[]
            : _urlPreviewsFromMarkdown(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty)
          MarkdownBody(
            data: content,
            selectable: true,
            builders:
                isCurrentUser
                    ? const <String, MarkdownElementBuilder>{}
                    : <String, MarkdownElementBuilder>{
                      'pre': _CopyableCodeBlockBuilder(
                        isDesktop: isDesktop,
                        trustAnnotation: exportTrustAnnotation,
                        textStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontFamily: 'monospace',
                          fontSize: fontSize - 1,
                          height: 1.55,
                        ),
                      ),
                    },
            onTapLink:
                (text, href, title) => unawaited(
                  _openMarkdownLink(context, href, actionViewModel),
                ),
            styleSheet: _buildMarkdownStyleSheet(context, fontSize),
          ),
        if (urlPreviews.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _UrlPreviewList(
              previews: urlPreviews,
              isDesktop: isDesktop,
              actionViewModel: actionViewModel,
            ),
          ),
        if (images.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: content.isNotEmpty ? 14 : 0),
            child: _buildImageSection(context),
          ),
        if (isCurrentUser && localFiles.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: content.isNotEmpty || images.isNotEmpty ? 12 : 0,
            ),
            child: _MessageFileSection(
              files: localFiles,
              isCurrentUser: true,
              isDesktop: isDesktop,
              actions: actionViewModel,
            ),
          ),
        if (audio.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: _hasMediaAbove ? 12 : 0),
            child: ExecutionStatusCard(
              isDesktop: isDesktop,
              icon:
                  isDesktop ? LucideIcons.audioLines : Icons.graphic_eq_rounded,
              title: S.of(context).speechResult,
              subtitle: S.of(context).directPlayback,
              child: AudioPlayerWidget(audioFilePath: audio),
            ),
          ),
        if (music.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: _hasMediaAbove || audio.isNotEmpty ? 12 : 0,
            ),
            child: ExecutionStatusCard(
              isDesktop: isDesktop,
              icon: isDesktop ? LucideIcons.music : Icons.music_note_rounded,
              title: S.of(context).musicResult,
              subtitle: S.of(context).directPlayback,
              child: AudioPlayerWidget(audioFilePath: music),
            ),
          ),
        if (video.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top:
                  _hasMediaAbove || audio.isNotEmpty || music.isNotEmpty
                      ? 12
                      : 0,
            ),
            child: ExecutionStatusCard(
              isDesktop: isDesktop,
              icon:
                  isDesktop
                      ? LucideIcons.video
                      : Icons.video_camera_back_outlined,
              title: S.of(context).videoResult,
              subtitle: S.of(context).directPreview,
              child: VideoPlayerWidget(videoFilePath: video),
            ),
          ),
      ],
    );
  }

  bool get _hasMediaAbove =>
      content.isNotEmpty ||
      images.isNotEmpty ||
      (isCurrentUser && files.isNotEmpty);

  bool get _showProcessInfo =>
      showExecutionStatus &&
      (processInfo.hasData ||
          tokenUsage.inputTokens > 0 ||
          tokenUsage.outputTokens > 0);

  bool get _showReasoning => showReasoning && reasoning.isNotEmpty;

  bool get _showTrustStatus {
    if (!showVerificationStatus || isCurrentUser || isStreaming) return false;
    return grounding != null;
  }

  bool get _showTerminalStatus =>
      terminalOutcome != null &&
      (terminalOutcome != MessageTerminalOutcome.completed ||
          hasPartialContent);

  bool get _hasStructuredMedia =>
      images.isNotEmpty ||
      (isCurrentUser && files.isNotEmpty) ||
      audio.isNotEmpty ||
      music.isNotEmpty ||
      video.isNotEmpty;

  Widget _buildImageSection(BuildContext context) => Column(
    key: const ValueKey<String>('message-image-section'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExecutionStatusHeader(
        isDesktop: isDesktop,
        icon: isDesktop ? LucideIcons.image : Icons.image_outlined,
        iconKey: const ValueKey<String>('message-image-section-icon'),
        title:
            isCurrentUser
                ? S.of(context).imageAttachment
                : S.of(context).imageResult,
        subtitle: S.of(context).itemCount(images.length.toString()),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final preferredPreviewSize =
              isDesktop
                  ? StarsDesktopThemeSpec.messageImagePreviewSize
                  : _mobileMessageImagePreviewSize;
          final previewSize = math.min(
            preferredPreviewSize,
            constraints.maxWidth,
          );
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final imagePath in images)
                _buildImagePreview(context, imagePath, previewSize),
            ],
          );
        },
      ),
    ],
  );

  Widget _buildImagePreview(
    BuildContext context,
    String imagePath,
    double previewSize,
  ) {
    final radius =
        isDesktop
            ? StarsDesktopThemeSpec.containerRadius
            : BorderRadius.circular(12);
    return GestureDetector(
      key: ValueKey<String>('message-image-preview-$imagePath'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _showImageDialog(
          context,
          imagePath,
          actionViewModel,
          trustAnnotation: exportTrustAnnotation,
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        width: previewSize,
        height: previewSize,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: StarsDesktopTokens.of(context).separator),
        ),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return ColoredBox(
              color: StarsDesktopTokens.of(context).controlFill,
              child: Center(
                child: Icon(
                  isDesktop ? LucideIcons.imageOff : Icons.broken_image,
                  color: StarsDesktopTokens.of(context).secondaryText,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(
    BuildContext context,
    double fontSize,
  ) {
    return MarkdownStyleSheet(
      p: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize,
        height: 1.55,
      ),
      code: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        backgroundColor: StarsDesktopTokens.of(context).controlFill,
        fontFamily: 'monospace',
        fontSize: fontSize - 1,
      ),
      a: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: Theme.of(context).colorScheme.primary,
      ),
      h1: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize + 6,
        fontWeight: FontWeight.w700,
      ),
      h2: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize + 3,
        fontWeight: FontWeight.w700,
      ),
      h3: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize + 1,
        fontWeight: FontWeight.w600,
      ),
      blockquote: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        fontStyle: FontStyle.italic,
      ),
      codeblockDecoration: BoxDecoration(
        color: StarsDesktopTokens.of(context).controlFill,
        borderRadius:
            isDesktop
                ? StarsDesktopThemeSpec.containerRadius
                : BorderRadius.circular(14),
        border: Border.all(color: StarsDesktopTokens.of(context).separator),
      ),
      blockSpacing: 10,
      listBullet: TextStyle(
        color: StarsDesktopTokens.of(context).secondaryText,
        fontSize: fontSize,
      ),
    );
  }
}

class _MessageBubbleSurface extends StatelessWidget {
  const _MessageBubbleSurface({
    required this.isCurrentUser,
    required this.isDesktop,
    required this.child,
  });

  final bool isCurrentUser;
  final bool isDesktop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isCurrentUser
            ? StarsDesktopTokens.of(context).selectedFill
            : MessageAvatar.backgroundColorOf(context);

    if (isDesktop) {
      return ShadCard(
        key: const ValueKey<String>('message-bubble-surface'),
        padding: const EdgeInsets.all(16),
        backgroundColor: backgroundColor,
        radius: StarsDesktopThemeSpec.bubbleRadius,
        border: ShadBorder.all(color: StarsDesktopTokens.of(context).separator),
        child: child,
      );
    }

    return Container(
      key: const ValueKey<String>('message-bubble-surface'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
