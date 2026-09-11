part of 'message_list.dart';

const _localTextPreviewLimit = 1024 * 1024;

enum _LocalFileKind {
  image,
  markdown,
  html,
  text,
  audio,
  video,
  pdf,
  word,
  document,
  other,
}

final class _LocalFileDescriptor {
  const _LocalFileDescriptor({
    required this.path,
    required this.fileName,
    required this.extension,
    required this.kind,
  });

  factory _LocalFileDescriptor.fromPath(String filePath) {
    final extension = path_context.extension(filePath).toLowerCase();
    return _LocalFileDescriptor(
      path: filePath,
      fileName: path_context.basename(filePath),
      extension: extension,
      kind: _kindForExtension(extension),
    );
  }

  final String path;
  final String fileName;
  final String extension;
  final _LocalFileKind kind;

  String get typeLabel => switch (kind) {
    _LocalFileKind.image => 'IMAGE',
    _LocalFileKind.markdown => 'MARKDOWN',
    _LocalFileKind.html => 'HTML',
    _LocalFileKind.text => 'TEXT',
    _LocalFileKind.audio => 'AUDIO',
    _LocalFileKind.video => 'VIDEO',
    _LocalFileKind.pdf => 'PDF',
    _LocalFileKind.word => 'WORD',
    _LocalFileKind.document => 'DOCUMENT',
    _LocalFileKind.other =>
      extension.isEmpty ? 'FILE' : extension.substring(1).toUpperCase(),
  };

  IconData get icon => switch (kind) {
    _LocalFileKind.image => Icons.image_outlined,
    _LocalFileKind.markdown ||
    _LocalFileKind.text => Icons.text_snippet_outlined,
    _LocalFileKind.html => LucideIcons.fileCode2,
    _LocalFileKind.audio => Icons.audio_file_outlined,
    _LocalFileKind.video => Icons.video_file_outlined,
    _LocalFileKind.pdf => Icons.picture_as_pdf_outlined,
    _LocalFileKind.word ||
    _LocalFileKind.document => Icons.description_outlined,
    _LocalFileKind.other => Icons.insert_drive_file_outlined,
  };
}

_LocalFileKind _kindForExtension(String extension) {
  if (const {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.bmp',
    '.webp',
  }.contains(extension)) {
    return _LocalFileKind.image;
  }
  if (const {'.md', '.markdown'}.contains(extension)) {
    return _LocalFileKind.markdown;
  }
  if (const {'.html', '.htm'}.contains(extension)) {
    return _LocalFileKind.html;
  }
  if (const {
    '.txt',
    '.log',
    '.csv',
    '.json',
    '.yaml',
    '.yml',
    '.xml',
    '.css',
    '.dart',
    '.js',
    '.ts',
    '.py',
    '.sh',
    '.sql',
    '.ini',
    '.toml',
  }.contains(extension)) {
    return _LocalFileKind.text;
  }
  if (const {
    '.mp3',
    '.wav',
    '.m4a',
    '.aac',
    '.ogg',
    '.flac',
  }.contains(extension)) {
    return _LocalFileKind.audio;
  }
  if (const {
    '.mp4',
    '.mov',
    '.m4v',
    '.webm',
    '.avi',
    '.mkv',
  }.contains(extension)) {
    return _LocalFileKind.video;
  }
  if (extension == '.pdf') return _LocalFileKind.pdf;
  if (const {'.doc', '.docx'}.contains(extension)) {
    return _LocalFileKind.word;
  }
  if (const {
    '.rtf',
    '.odt',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
  }.contains(extension)) {
    return _LocalFileKind.document;
  }
  return _LocalFileKind.other;
}

List<String> _localFilesFromMarkdown(
  String markdown,
  List<String> explicitFiles,
) {
  final files = List<String>.of(explicitFiles);
  if (markdown.trim().isEmpty) return files;

  try {
    final nodes = md.Document().parseLines(markdown.split('\n'));
    for (final node in nodes) {
      _collectMarkdownLocalFiles(node, files);
    }
  } on Object {
    return files;
  }
  return files;
}

void _collectMarkdownLocalFiles(
  md.Node node,
  List<String> files, {
  bool insideCodeBlock = false,
}) {
  if (node is! md.Element) return;
  final isInsideCodeBlock = insideCodeBlock || node.tag == 'pre';

  String? reference;
  if (node.tag == 'a') {
    reference = node.attributes['href'];
  } else if (node.tag == 'img') {
    reference = node.attributes['src'];
  } else if (node.tag == 'code' && !isInsideCodeBlock) {
    reference = node.textContent;
  }
  final localPath = _localFilePathFromReference(reference ?? '');
  if (localPath != null &&
      File(localPath).existsSync() &&
      !files.contains(localPath)) {
    files.add(localPath);
  }

  for (final child in node.children ?? const <md.Node>[]) {
    _collectMarkdownLocalFiles(
      child,
      files,
      insideCodeBlock: isInsideCodeBlock,
    );
  }
}

String? _localFilePathFromReference(String reference) {
  var normalized = reference.trim();
  if (normalized.length >= 2 &&
      ((normalized.startsWith('<') && normalized.endsWith('>')) ||
          (normalized.startsWith('"') && normalized.endsWith('"')) ||
          (normalized.startsWith("'") && normalized.endsWith("'")))) {
    normalized = normalized.substring(1, normalized.length - 1).trim();
  }
  if (normalized.isEmpty) return null;

  try {
    normalized = Uri.decodeFull(normalized);
  } on ArgumentError {
    // Native paths may contain raw Unicode that is valid for the file system
    // but is not an encoded URI. Keep that path unchanged.
  }
  if (path_context.isAbsolute(normalized)) {
    return path_context.normalize(normalized);
  }

  final uri = Uri.tryParse(normalized);
  if (uri == null) return null;
  if (uri.scheme == 'file') {
    try {
      return path_context.normalize(
        uri.toFilePath(windows: Platform.isWindows),
      );
    } on UnsupportedError {
      return null;
    } on StateError {
      return null;
    }
  }
  if (uri.scheme == 'sandbox' && path_context.isAbsolute(uri.path)) {
    return path_context.normalize(uri.path);
  }
  return null;
}

class _LocalFileCard extends StatelessWidget {
  const _LocalFileCard({
    required this.filePath,
    required this.isCurrentUser,
    required this.isDesktop,
    required this.actionViewModel,
  });

  final String filePath;
  final bool isCurrentUser;
  final bool isDesktop;
  final MessageActionViewModel? actionViewModel;

  @override
  Widget build(BuildContext context) {
    final descriptor = _LocalFileDescriptor.fromPath(filePath);
    final theme = ShadTheme.of(context);
    return ShadTooltip(
      builder:
          (context) =>
              Text('${S.of(context).openFile}: ${descriptor.fileName}'),
      child: ShadButton.outline(
        key: ValueKey<String>('message-local-file-$filePath'),
        width: isDesktop ? 280 : 230,
        height: 76,
        padding: const EdgeInsets.all(10),
        backgroundColor:
            isCurrentUser ? theme.colorScheme.accent : theme.colorScheme.card,
        foregroundColor: theme.colorScheme.cardForeground,
        hoverBackgroundColor: theme.colorScheme.accent,
        hoverForegroundColor: theme.colorScheme.accentForeground,
        mainAxisAlignment: MainAxisAlignment.start,
        expands: true,
        onPressed:
            () => showLocalFilePreviewDialog(
              context: context,
              filePath: descriptor.path,
              actions: actionViewModel,
            ),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: theme.radius,
          ),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(
              descriptor.icon,
              size: 20,
              color: theme.colorScheme.secondaryForeground,
            ),
          ),
        ),
        trailing: Icon(
          LucideIcons.externalLink,
          size: 16,
          color: theme.colorScheme.mutedForeground,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              descriptor.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: theme.textTheme.small,
            ),
            const SizedBox(height: 3),
            Text(
              descriptor.typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.muted.copyWith(
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the shared in-app preview for a local conversation artifact.
///
/// Keeping this entry point public lets the message timeline and conversation
/// directory present files consistently without duplicating preview logic.
void showLocalFilePreviewDialog({
  required BuildContext context,
  required String filePath,
  MessageActionViewModel? actions,
}) {
  _showLocalFileDialog(
    context,
    _LocalFileDescriptor.fromPath(filePath),
    actions,
  );
}

void _showLocalFileDialog(
  BuildContext context,
  _LocalFileDescriptor descriptor,
  MessageActionViewModel? actions,
) {
  unawaited(
    showChatShadDialog<void>(
      context: context,
      builder:
          (dialogContext) =>
              _LocalFilePreviewDialog(descriptor: descriptor, actions: actions),
    ),
  );
}

class _LocalFilePreviewDialog extends StatefulWidget {
  const _LocalFilePreviewDialog({
    required this.descriptor,
    required this.actions,
  });

  final _LocalFileDescriptor descriptor;
  final MessageActionViewModel? actions;

  @override
  State<_LocalFilePreviewDialog> createState() =>
      _LocalFilePreviewDialogState();
}

class _LocalFilePreviewDialogState extends State<_LocalFilePreviewDialog> {
  static const _dialogInset = 16.0;
  static const _normalWidth = 1040.0;
  static const _normalHeight = 900.0;
  static const _normalHeightFactor = 0.86;

  var _maximized = false;

  void _toggleMaximized() {
    setState(() => _maximized = !_maximized);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final viewport = MediaQuery.sizeOf(context);
    final dialogSize = _maximized ? viewport : _normalDialogSize(viewport);
    final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;

    return ShadDialog(
      key: const ValueKey<String>('message-local-file-dialog'),
      constraints: BoxConstraints.tight(dialogSize),
      scrollable: false,
      radius: _maximized ? BorderRadius.zero : null,
      shadows: _maximized ? const [] : null,
      closeIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarsDesktopIconAction(
            key: const ValueKey<String>('message-local-file-maximize'),
            icon: _maximized ? LucideIcons.minimize2 : LucideIcons.maximize2,
            iconSize: 18,
            label:
                _maximized ? strings.restorePreview : strings.maximizePreview,
            selected: _maximized,
            onPressed: _toggleMaximized,
          ),
          StarsDesktopIconAction(
            key: const ValueKey<String>('message-local-file-close-icon'),
            icon: LucideIcons.x,
            iconSize: 18,
            label: closeLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      closeIconPosition: ShadPosition.directional(
        top: 8,
        end: 8,
        textDirection: Directionality.of(context),
      ),
      title: Padding(
        padding: const EdgeInsetsDirectional.only(end: 96),
        child: Text(
          widget.descriptor.fileName,
          key: const ValueKey<String>('message-local-file-title'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: StarsDesktopThemeSpec.pageTitleStyle(context),
        ),
      ),
      description: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          key: const ValueKey<String>('message-local-file-metadata'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShadBadge.outline(
              key: const ValueKey<String>('message-local-file-type'),
              child: Text(widget.descriptor.typeLabel),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: SelectableText(
                widget.descriptor.path,
                key: const ValueKey<String>('message-local-file-path'),
                maxLines: 1,
                style: StarsDesktopThemeSpec.metaStyle(context),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.actions != null)
          ShadButton(
            key: const ValueKey<String>('message-local-file-open-external'),
            leading: const Icon(Icons.open_in_new_rounded, size: 17),
            onPressed: _openWithSystem,
            child: Text(strings.openWithSystem),
          ),
        ShadButton.outline(
          key: const ValueKey<String>('message-local-file-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox.expand(
          child: _LocalFilePreview(
            descriptor: widget.descriptor,
            actionViewModel: widget.actions,
          ),
        ),
      ),
    );
  }

  Size _normalDialogSize(Size viewport) {
    final availableWidth = math.max(0.0, viewport.width - _dialogInset * 2);
    final availableHeight = math.max(0.0, viewport.height - _dialogInset * 2);
    return Size(
      math.min(_normalWidth, availableWidth),
      math.min(
        _normalHeight,
        math.min(availableHeight, viewport.height * _normalHeightFactor),
      ),
    );
  }

  Future<void> _openWithSystem() async {
    final actions = widget.actions;
    if (actions == null) return;
    final opened = await actions.openLocalFile(widget.descriptor.path);
    if (!opened && mounted) {
      showStarsNotice(context, S.of(context).fileOpenFailed);
    }
  }
}

class _LocalFilePreview extends StatelessWidget {
  const _LocalFilePreview({
    required this.descriptor,
    required this.actionViewModel,
  });

  final _LocalFileDescriptor descriptor;
  final MessageActionViewModel? actionViewModel;

  @override
  Widget build(BuildContext context) {
    final file = File(descriptor.path);
    if (!file.existsSync()) {
      return _LocalFilePreviewPlaceholder(
        icon: Icons.file_present_outlined,
        message: S.of(context).fileMissing,
      );
    }

    return switch (descriptor.kind) {
      _LocalFileKind.image => ClipRRect(
        key: const ValueKey<String>('message-local-file-image-preview'),
        borderRadius: StarsDesktopThemeSpec.containerRadius,
        child: ColoredBox(
          color: Colors.black,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) => _LocalFilePreviewPlaceholder(
                  icon: Icons.broken_image_outlined,
                  message: S.of(context).filePreviewUnavailable,
                ),
          ),
        ),
      ),
      _LocalFileKind.markdown => _LocalTextFilePreview(
        key: const ValueKey<String>('message-local-file-markdown-preview'),
        file: file,
        markdown: true,
        actionViewModel: actionViewModel,
      ),
      _LocalFileKind.html => LocalHtmlFilePreview(file: file),
      _LocalFileKind.text => _LocalTextFilePreview(
        key: const ValueKey<String>('message-local-file-text-preview'),
        file: file,
        markdown: false,
        actionViewModel: actionViewModel,
      ),
      _LocalFileKind.audio => SingleChildScrollView(
        key: const ValueKey<String>('message-local-file-audio-preview'),
        child: AudioPlayerWidget(audioFilePath: descriptor.path),
      ),
      _LocalFileKind.video => SingleChildScrollView(
        key: const ValueKey<String>('message-local-file-video-preview'),
        child: VideoPlayerWidget(videoFilePath: descriptor.path),
      ),
      _LocalFileKind.pdf ||
      _LocalFileKind.word ||
      _LocalFileKind.document ||
      _LocalFileKind.other => _LocalFilePreviewPlaceholder(
        icon: descriptor.icon,
        typeLabel: descriptor.typeLabel,
        message: S.of(context).filePreviewUnavailable,
      ),
    };
  }
}

class _LocalTextFilePreview extends StatefulWidget {
  const _LocalTextFilePreview({
    super.key,
    required this.file,
    required this.markdown,
    required this.actionViewModel,
  });

  final File file;
  final bool markdown;
  final MessageActionViewModel? actionViewModel;

  @override
  State<_LocalTextFilePreview> createState() => _LocalTextFilePreviewState();
}

class _LocalTextFilePreviewState extends State<_LocalTextFilePreview> {
  String _content = '';
  Object? _error;

  @override
  void initState() {
    super.initState();
    try {
      _content = _readLocalText(widget.file);
    } on Object catch (error) {
      _error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _LocalFilePreviewPlaceholder(
        icon: Icons.error_outline_rounded,
        message: S.of(context).filePreviewUnavailable,
      );
    }
    if (widget.markdown) {
      return Markdown(
        data: _content,
        selectable: true,
        padding: const EdgeInsets.all(16),
        onTapLink:
            (text, href, title) => unawaited(
              _openMarkdownLink(context, href, widget.actionViewModel),
            ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StarsDesktopTokens.of(context).controlFill,
        borderRadius: StarsDesktopThemeSpec.containerRadius,
        border: Border.all(color: StarsDesktopTokens.of(context).separator),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: SelectableText(
            _content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalFilePreviewPlaceholder extends StatelessWidget {
  const _LocalFilePreviewPlaceholder({
    required this.icon,
    required this.message,
    this.typeLabel,
  });

  final IconData icon;
  final String message;
  final String? typeLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StarsDesktopTokens.of(context).controlFill,
        borderRadius: StarsDesktopThemeSpec.containerRadius,
        border: Border.all(color: StarsDesktopTokens.of(context).separator),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 52,
                color: StarsDesktopTokens.of(context).secondaryText,
              ),
              if (typeLabel != null) ...[
                const SizedBox(height: 12),
                Text(
                  typeLabel!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: StarsDesktopTokens.of(context).secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _readLocalText(File file) {
  final handle = file.openSync();
  try {
    final length = handle.lengthSync();
    final byteCount =
        length > _localTextPreviewLimit ? _localTextPreviewLimit : length;
    final bytes = handle.readSync(byteCount);
    final content = utf8.decode(bytes, allowMalformed: true);
    return length > _localTextPreviewLimit ? '$content\n\n…' : content;
  } finally {
    handle.closeSync();
  }
}
