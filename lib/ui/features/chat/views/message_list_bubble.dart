part of 'message_list.dart';

class _MessageBubble extends StatelessWidget {
  final bool isCurrentUser;
  final bool isDesktop;
  final bool isStreaming;
  final String reasoning;
  final MessageProcessInfo processInfo;
  final ModelTokenUsage tokenUsage;
  final bool showExecutionStatus;
  final String content;
  final List<String> images;
  final List<String> files;
  final String audio;
  final String music;
  final String video;
  final MessageTerminalOutcome? terminalOutcome;
  final bool hasPartialContent;
  final MessageActionViewModel? actionViewModel;

  const _MessageBubble({
    required this.isCurrentUser,
    required this.isDesktop,
    this.isStreaming = false,
    required this.reasoning,
    this.processInfo = const MessageProcessInfo(),
    this.tokenUsage = ModelTokenUsage.empty,
    this.showExecutionStatus = true,
    required this.content,
    this.images = const [],
    this.files = const [],
    this.audio = '',
    this.music = '',
    this.video = '',
    this.terminalOutcome,
    this.hasPartialContent = false,
    this.actionViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14;
    final useBubbleShell = !isDesktop || isCurrentUser;
    final backgroundColor =
        isCurrentUser
            ? StarsDesktopTokens.of(context).selectedFill
            : StarsDesktopTokens.of(context).contentBackground;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reasoning.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  content.isNotEmpty ||
                          _showProcessInfo ||
                          _hasStructuredMedia ||
                          _showTerminalStatus
                      ? 14
                      : 0,
            ),
            child: ReasoningSection(
              reasoning: reasoning,
              isDesktop: isDesktop,
              isStreaming: isStreaming,
              durationMs: processInfo.durationMs,
              actionViewModel: actionViewModel,
            ),
          ),
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
        if (_showsProcessInfoBeforeMedia)
          Padding(
            padding: EdgeInsets.only(top: content.isNotEmpty ? 14 : 0),
            child: ProcessInfoSection(
              processInfo: processInfo,
              tokenUsage: tokenUsage,
              isDesktop: isDesktop,
              isStreaming: isStreaming,
              hasReasoningContent: reasoning.isNotEmpty,
            ),
          ),
        if (images.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: content.isNotEmpty || _showsProcessInfoBeforeMedia ? 14 : 0,
            ),
            child: _StatusCardSection(
              isDesktop: isDesktop,
              icon: isDesktop ? LucideIcons.image : Icons.image_outlined,
              title:
                  isCurrentUser
                      ? S.of(context).imageAttachment
                      : S.of(context).imageResult,
              subtitle: S.of(context).itemCount(images.length.toString()),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    images
                        .map(
                          (imagePath) => _buildImagePreview(context, imagePath),
                        )
                        .toList(),
              ),
            ),
          ),
        if (files.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top:
                  content.isNotEmpty ||
                          _showsProcessInfoBeforeMedia ||
                          images.isNotEmpty
                      ? 12
                      : 0,
            ),
            child: _StatusCardSection(
              isDesktop: isDesktop,
              icon:
                  isDesktop ? LucideIcons.paperclip : Icons.attach_file_rounded,
              title:
                  isCurrentUser
                      ? S.of(context).fileAttachment
                      : S.of(context).fileResult,
              subtitle: S.of(context).fileCount(files.length.toString()),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    files
                        .map(
                          (filePath) => _buildFilePreview(
                            context,
                            filePath,
                            isCurrentUser,
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        if (audio.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: _hasMediaAbove ? 12 : 0),
            child: _StatusCardSection(
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
            child: _StatusCardSection(
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
            child: _StatusCardSection(
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
        if (_showTerminalStatus)
          Padding(
            padding: EdgeInsets.only(
              top:
                  content.isNotEmpty ||
                          _hasStructuredMedia ||
                          _showsProcessInfoBeforeMedia
                      ? 10
                      : 0,
            ),
            child: _MessageTerminalStatus(
              outcome: terminalOutcome!,
              hasPartialContent: hasPartialContent,
            ),
          ),
        if (_showsProcessInfoAfterMessage)
          Padding(
            padding: EdgeInsets.only(
              top:
                  content.isNotEmpty ||
                          _hasStructuredMedia ||
                          _showTerminalStatus
                      ? 14
                      : 0,
            ),
            child: ProcessInfoSection(
              processInfo: processInfo,
              tokenUsage: tokenUsage,
              isDesktop: isDesktop,
              isStreaming: isStreaming,
              hasReasoningContent: reasoning.isNotEmpty,
            ),
          ),
      ],
    );

    if (!useBubbleShell) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 8),
        child: body,
      );
    }

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.zero,
        child: ShadCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: backgroundColor,
          radius: StarsDesktopThemeSpec.bubbleRadius,
          border: ShadBorder.all(
            color: StarsDesktopTokens.of(context).separator,
          ),
          child: body,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: body,
    );
  }

  bool get _hasMediaAbove =>
      content.isNotEmpty ||
      _showsProcessInfoBeforeMedia ||
      images.isNotEmpty ||
      files.isNotEmpty;

  bool get _showProcessInfo =>
      showExecutionStatus &&
      (processInfo.hasData ||
          tokenUsage.inputTokens > 0 ||
          tokenUsage.outputTokens > 0);

  bool get _showsProcessInfoBeforeMedia => _showProcessInfo && !isDesktop;

  bool get _showsProcessInfoAfterMessage => _showProcessInfo && isDesktop;

  bool get _showTerminalStatus =>
      terminalOutcome != null &&
      (terminalOutcome != MessageTerminalOutcome.completed ||
          hasPartialContent);

  bool get _hasStructuredMedia =>
      images.isNotEmpty ||
      files.isNotEmpty ||
      audio.isNotEmpty ||
      music.isNotEmpty ||
      video.isNotEmpty;

  Widget _buildImagePreview(BuildContext context, String imagePath) {
    return GestureDetector(
      key: ValueKey<String>('message-image-preview-$imagePath'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _showImageDialog(context, imagePath, actionViewModel);
      },
      child: ClipRRect(
        borderRadius:
            isDesktop
                ? StarsDesktopThemeSpec.containerRadius
                : BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 96,
            minHeight: 96,
            maxWidth: isDesktop ? 220 : 150,
            maxHeight: isDesktop ? 240 : 200,
          ),
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 96,
                height: 96,
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
      ),
    );
  }

  Widget _buildFilePreview(
    BuildContext context,
    String filePath,
    bool isCurrentUser,
  ) => _LocalFileCard(
    filePath: filePath,
    isCurrentUser: isCurrentUser,
    isDesktop: isDesktop,
    actionViewModel: actionViewModel,
  );

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
