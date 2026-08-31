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
            () => _showLocalFileDialog(context, descriptor, actionViewModel),
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

void _showLocalFileDialog(
  BuildContext context,
  _LocalFileDescriptor descriptor,
  MessageActionViewModel? actions,
) {
  unawaited(
    showChatShadDialog<void>(
      context: context,
      builder: (dialogContext) {
        final strings = S.of(dialogContext);
        final previewHeight =
            (MediaQuery.heightOf(dialogContext) * 0.55)
                .clamp(160.0, 680.0)
                .toDouble();
        return ShadDialog(
          key: const ValueKey<String>('message-local-file-dialog'),
          closeIcon: StarsDesktopIconAction(
            key: const ValueKey<String>('message-local-file-close-icon'),
            icon: LucideIcons.x,
            iconSize: 18,
            label: MaterialLocalizations.of(dialogContext).closeButtonTooltip,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          closeIconPosition: ShadPosition.directional(
            top: 12,
            end: 8,
            textDirection: Directionality.of(dialogContext),
          ),
          title: Text(
            descriptor.fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: StarsDesktopThemeSpec.pageTitleStyle(dialogContext),
          ),
          description: SelectableText(descriptor.path, maxLines: 2),
          constraints: const BoxConstraints(maxWidth: 860),
          actions: [
            if (actions != null)
              ShadButton(
                key: const ValueKey<String>('message-local-file-open-external'),
                onPressed: () async {
                  final opened = await actions.openLocalFile(descriptor.path);
                  if (!opened && dialogContext.mounted) {
                    showStarsNotice(dialogContext, strings.fileOpenFailed);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_new_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(strings.openWithSystem),
                  ],
                ),
              ),
            ShadButton.outline(
              key: const ValueKey<String>('message-local-file-close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).closeButtonLabel,
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              height: previewHeight,
              width: double.infinity,
              child: _LocalFilePreview(
                descriptor: descriptor,
                actionViewModel: actions,
              ),
            ),
          ),
        );
      },
    ),
  );
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
      _LocalFileKind.html => _LocalHtmlFilePreview(file: file),
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

final class _LocalHtmlPreviewData {
  const _LocalHtmlPreviewData({
    required this.source,
    required this.title,
    required this.description,
    required this.text,
  });

  final String source;
  final String title;
  final String description;
  final String text;
}

class _LocalHtmlFilePreview extends StatefulWidget {
  const _LocalHtmlFilePreview({required this.file});

  final File file;

  @override
  State<_LocalHtmlFilePreview> createState() => _LocalHtmlFilePreviewState();
}

class _LocalHtmlFilePreviewState extends State<_LocalHtmlFilePreview> {
  late Future<_LocalHtmlPreviewData> _preview;
  var _showSource = false;

  @override
  void initState() {
    super.initState();
    _preview = _readLocalHtmlPreview(widget.file);
  }

  @override
  void didUpdateWidget(covariant _LocalHtmlFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _preview = _readLocalHtmlPreview(widget.file);
      _showSource = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LocalHtmlPreviewData>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _LocalFilePreviewPlaceholder(
            icon: LucideIcons.fileWarning,
            message: S.of(context).filePreviewUnavailable,
          );
        }
        final preview = snapshot.data;
        if (preview == null) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        return _LocalHtmlPreviewSurface(
          preview: preview,
          showSource: _showSource,
          onModeChanged: (showSource) {
            if (_showSource == showSource) return;
            setState(() => _showSource = showSource);
          },
        );
      },
    );
  }
}

class _LocalHtmlPreviewSurface extends StatelessWidget {
  const _LocalHtmlPreviewSurface({
    required this.preview,
    required this.showSource,
    required this.onModeChanged,
  });

  final _LocalHtmlPreviewData preview;
  final bool showSource;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final theme = ShadTheme.of(context);
    final title = preview.title.isEmpty ? strings.htmlPreview : preview.title;
    return DecoratedBox(
      key: const ValueKey<String>('message-local-file-html-preview'),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: theme.radius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final identity = _HtmlPreviewIdentity(
                  title: title,
                  description: preview.description,
                );
                final controls = _HtmlPreviewModeControls(
                  showSource: showSource,
                  previewLabel: strings.preview,
                  sourceLabel: strings.sourceCode,
                  onModeChanged: onModeChanged,
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: controls,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: identity),
                    const SizedBox(width: 12),
                    controls,
                  ],
                );
              },
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.colorScheme.border),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey<String>(
                showSource
                    ? 'message-local-html-source'
                    : 'message-local-html-content',
              ),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: SelectableText(
                  showSource ? preview.source : preview.text,
                  style:
                      showSource
                          ? theme.textTheme.p.copyWith(
                            color: theme.colorScheme.cardForeground,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.55,
                          )
                          : theme.textTheme.p.copyWith(
                            color: theme.colorScheme.cardForeground,
                            height: 1.65,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HtmlPreviewIdentity extends StatelessWidget {
  const _HtmlPreviewIdentity({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: theme.radius,
          ),
          child: SizedBox.square(
            dimension: 36,
            child: Icon(
              LucideIcons.fileCode2,
              size: 18,
              color: theme.colorScheme.secondaryForeground,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.h4,
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HtmlPreviewModeControls extends StatelessWidget {
  const _HtmlPreviewModeControls({
    required this.showSource,
    required this.previewLabel,
    required this.sourceLabel,
    required this.onModeChanged,
  });

  final bool showSource;
  final String previewLabel;
  final String sourceLabel;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: [
        _HtmlPreviewModeButton(
          selected: !showSource,
          label: previewLabel,
          onPressed: () => onModeChanged(false),
        ),
        _HtmlPreviewModeButton(
          selected: showSource,
          label: sourceLabel,
          onPressed: () => onModeChanged(true),
        ),
      ],
    );
  }
}

class _HtmlPreviewModeButton extends StatelessWidget {
  const _HtmlPreviewModeButton({
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadButton.ghost(
      size: ShadButtonSize.sm,
      backgroundColor:
          selected ? theme.colorScheme.secondary : Colors.transparent,
      foregroundColor:
          selected
              ? theme.colorScheme.secondaryForeground
              : theme.colorScheme.mutedForeground,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

Future<_LocalHtmlPreviewData> _readLocalHtmlPreview(File file) =>
    Future.microtask(() {
      // Local artifacts may contain active scripts. Keep the in-app preview
      // inert by extracting metadata and readable text instead of executing
      // the document in a browser surface. Source reads remain capped at 1 MB.
      final source = _readLocalText(file);
      final document = html_parser.parse(source);
      final title = document.querySelector('title')?.text.trim() ?? '';
      final description =
          document
              .querySelectorAll('meta')
              .where(
                (element) =>
                    element.attributes['name']?.toLowerCase() == 'description',
              )
              .firstOrNull
              ?.attributes['content']
              ?.trim() ??
          '';
      final buffer = StringBuffer();
      final body = document.body;
      if (body != null) _writeHtmlPreviewText(body, buffer);
      final text = _normalizeHtmlPreviewText(buffer.toString());
      return _LocalHtmlPreviewData(
        source: source,
        title: title,
        description: description,
        text: text.isEmpty ? description : text,
      );
    });

const _htmlHiddenElements = {
  'head',
  'script',
  'style',
  'template',
  'noscript',
  'svg',
};

const _htmlBlockElements = {
  'address',
  'article',
  'aside',
  'blockquote',
  'div',
  'dl',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'hr',
  'li',
  'main',
  'nav',
  'ol',
  'p',
  'pre',
  'section',
  'table',
  'tr',
  'ul',
};

void _writeHtmlPreviewText(html_dom.Node node, StringBuffer buffer) {
  if (node is html_dom.Text) {
    var text = node.data.replaceAll(RegExp(r'\s+'), ' ');
    if (text.trim().isEmpty) return;
    if (buffer.isEmpty) text = text.trimLeft();
    buffer.write(text);
    return;
  }
  if (node is! html_dom.Element) return;
  final tag = node.localName;
  if (_htmlHiddenElements.contains(tag)) return;
  if (tag == 'br') {
    buffer.writeln();
    return;
  }
  final isBlock = _htmlBlockElements.contains(tag);
  if (isBlock && buffer.isNotEmpty) buffer.writeln();
  for (final child in node.nodes) {
    _writeHtmlPreviewText(child, buffer);
  }
  if (isBlock) buffer.writeln();
}

String _normalizeHtmlPreviewText(String source) =>
    source
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n')
        .trim();

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
