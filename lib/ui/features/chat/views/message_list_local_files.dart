part of 'message_list.dart';

const _localTextPreviewLimit = 1024 * 1024;

enum _LocalFileKind {
  image,
  markdown,
  html,
  code,
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
    required this.syntaxLanguage,
  });

  factory _LocalFileDescriptor.fromPath(String filePath) {
    final extension = path_context.extension(filePath).toLowerCase();
    final fileName = path_context.basename(filePath);
    final syntaxLanguage = _syntaxLanguageFor(fileName, extension);
    return _LocalFileDescriptor(
      path: filePath,
      fileName: fileName,
      extension: extension,
      kind: _kindForExtension(extension, syntaxLanguage),
      syntaxLanguage: syntaxLanguage,
    );
  }

  final String path;
  final String fileName;
  final String extension;
  final _LocalFileKind kind;
  final String? syntaxLanguage;

  String get typeLabel => switch (kind) {
    _LocalFileKind.image => 'IMAGE',
    _LocalFileKind.markdown => 'MARKDOWN',
    _LocalFileKind.html => 'HTML',
    _LocalFileKind.code => _codeTypeLabel(fileName, extension, syntaxLanguage!),
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
    _LocalFileKind.html || _LocalFileKind.code => LucideIcons.fileCode2,
    _LocalFileKind.audio => Icons.audio_file_outlined,
    _LocalFileKind.video => Icons.video_file_outlined,
    _LocalFileKind.pdf => Icons.picture_as_pdf_outlined,
    _LocalFileKind.word ||
    _LocalFileKind.document => Icons.description_outlined,
    _LocalFileKind.other => Icons.insert_drive_file_outlined,
  };
}

_LocalFileKind _kindForExtension(String extension, String? syntaxLanguage) {
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
  if (syntaxLanguage != null) return _LocalFileKind.code;
  if (const {'.txt', '.log', '.csv'}.contains(extension)) {
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

const _syntaxLanguageByExtension = <String, String>{
  '.bash': 'bash',
  '.c': 'cpp',
  '.cc': 'cpp',
  '.cmake': 'cmake',
  '.cpp': 'cpp',
  '.cs': 'cs',
  '.css': 'css',
  '.cxx': 'cpp',
  '.dart': 'dart',
  '.ex': 'elixir',
  '.exs': 'elixir',
  '.go': 'go',
  '.gradle': 'gradle',
  '.gql': 'graphql',
  '.graphql': 'graphql',
  '.h': 'cpp',
  '.hh': 'cpp',
  '.hpp': 'cpp',
  '.hxx': 'cpp',
  '.ini': 'ini',
  '.java': 'java',
  '.js': 'javascript',
  '.json': 'json',
  '.jsonc': 'javascript',
  '.jsx': 'javascript',
  '.kt': 'kotlin',
  '.kts': 'kotlin',
  '.less': 'less',
  '.lua': 'lua',
  '.m': 'objectivec',
  '.mm': 'objectivec',
  '.mjs': 'javascript',
  '.php': 'php',
  '.proto': 'protobuf',
  '.ps1': 'powershell',
  '.py': 'python',
  '.pyw': 'python',
  '.r': 'r',
  '.rb': 'ruby',
  '.rs': 'rust',
  '.scala': 'scala',
  '.sc': 'scala',
  '.scss': 'scss',
  '.sh': 'bash',
  '.sol': 'solidity',
  '.sql': 'sql',
  '.swift': 'swift',
  '.toml': 'ini',
  '.ts': 'typescript',
  '.tsx': 'typescript',
  '.vue': 'vue',
  '.xml': 'xml',
  '.yaml': 'yaml',
  '.yml': 'yaml',
  '.zsh': 'bash',
};

String? _syntaxLanguageFor(String fileName, String extension) {
  final normalizedName = fileName.toLowerCase();
  if (normalizedName == 'dockerfile' ||
      normalizedName.startsWith('dockerfile.')) {
    return 'dockerfile';
  }
  if (normalizedName == 'makefile' || normalizedName == 'gnumakefile') {
    return 'makefile';
  }
  if (normalizedName == 'cmakelists.txt') return 'cmake';
  if (normalizedName == '.env' || normalizedName.startsWith('.env.')) {
    return 'bash';
  }
  return _syntaxLanguageByExtension[extension];
}

String _codeTypeLabel(String fileName, String extension, String language) {
  final normalizedName = fileName.toLowerCase();
  if (normalizedName == 'cmakelists.txt') return 'CMAKE';
  if (normalizedName == '.env' || normalizedName.startsWith('.env.')) {
    return 'ENV';
  }
  return switch (extension) {
    '.c' => 'C',
    '.cc' || '.cpp' || '.cxx' => 'C++',
    '.cs' => 'C#',
    '.h' || '.hh' || '.hpp' || '.hxx' => 'C/C++',
    '.js' || '.mjs' => 'JAVASCRIPT',
    '.jsx' => 'JSX',
    '.jsonc' => 'JSONC',
    '.kt' || '.kts' => 'KOTLIN',
    '.m' => 'OBJECTIVE-C',
    '.mm' => 'OBJECTIVE-C++',
    '.ps1' => 'POWERSHELL',
    '.py' || '.pyw' => 'PYTHON',
    '.rb' => 'RUBY',
    '.rs' => 'RUST',
    '.sh' || '.bash' || '.zsh' => 'SHELL',
    '.toml' => 'TOML',
    '.ts' => 'TYPESCRIPT',
    '.tsx' => 'TSX',
    '.yml' => 'YAML',
    _ => switch (normalizedName) {
      'dockerfile' => 'DOCKERFILE',
      'makefile' || 'gnumakefile' => 'MAKEFILE',
      _ => language.toUpperCase(),
    },
  };
}

LocalFileReferenceParser _localFileParser({String? baseDirectory}) =>
    LocalFileReferenceParser(
      baseDirectory: baseDirectory,
      homeDirectory:
          Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'],
    );

/// Resolves references once for both the bubble and its adjacent result cards.
/// The builder receives the same immutable list throughout message rendering.
class _MessageLocalFilesBuilder extends StatefulWidget {
  const _MessageLocalFilesBuilder({
    required this.content,
    required this.files,
    required this.isCurrentUser,
    required this.isStreaming,
    required this.actions,
    required this.builder,
  });

  final String content;
  final List<String> files;
  final bool isCurrentUser;
  final bool isStreaming;
  final MessageActionViewModel? actions;
  final Widget Function(BuildContext context, List<String> files) builder;

  @override
  State<_MessageLocalFilesBuilder> createState() => _MessageLocalFilesState();
}

class _MessageLocalFilesState extends State<_MessageLocalFilesBuilder> {
  List<String> _files = const [];
  int _generation = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _MessageLocalFilesBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        !listEquals(oldWidget.files, widget.files) ||
        oldWidget.isStreaming != widget.isStreaming ||
        oldWidget.isCurrentUser != widget.isCurrentUser ||
        oldWidget.actions != widget.actions) {
      _refresh(
        retainFiles:
            oldWidget.isStreaming &&
            widget.content.startsWith(oldWidget.content) &&
            listEquals(oldWidget.files, widget.files) &&
            oldWidget.isCurrentUser == widget.isCurrentUser &&
            oldWidget.actions == widget.actions,
      );
    }
  }

  void _refresh({bool retainFiles = false}) {
    final generation = ++_generation;
    _debounce?.cancel();
    if (!retainFiles) _files = List.unmodifiable(widget.files.toSet());
    if (widget.isCurrentUser) return;
    if (widget.isStreaming) {
      _debounce = Timer(const Duration(milliseconds: 200), () {
        unawaited(_resolveFiles(generation));
      });
    } else {
      unawaited(_resolveFiles(generation));
    }
  }

  Future<void> _resolveFiles(int generation) async {
    final content = widget.content;
    final explicitFiles = List<String>.of(widget.files);
    final directory = await widget.actions?.loadLocalFilesDirectory();
    if (!mounted || generation != _generation) return;
    final parser = _localFileParser(baseDirectory: directory);
    final files = <String>{
      for (final reference in explicitFiles)
        parser.resolve(reference) ?? reference,
    };
    for (final candidate in parser.pathsFromMarkdown(content)) {
      if (!mounted || generation != _generation) return;
      if (files.contains(candidate)) continue;
      try {
        if (await File(candidate).exists()) files.add(candidate);
      } on FileSystemException {
        // An inaccessible reference must not prevent other files from showing.
      }
    }
    if (!mounted || generation != _generation) return;
    final resolved = List<String>.unmodifiable(files);
    if (!listEquals(_files, resolved)) setState(() => _files = resolved);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _files);
}

class _MessageFileSection extends StatelessWidget {
  const _MessageFileSection({
    super.key,
    required this.files,
    required this.isCurrentUser,
    required this.isDesktop,
    required this.actions,
  });

  final List<String> files;
  final bool isCurrentUser;
  final bool isDesktop;
  final MessageActionViewModel? actions;

  @override
  Widget build(BuildContext context) => _StatusCardSection(
    isDesktop: isDesktop,
    icon: LucideIcons.paperclip,
    iconKey: const ValueKey<String>('message-file-section-icon'),
    title:
        isCurrentUser ? S.of(context).fileAttachment : S.of(context).fileResult,
    subtitle: S.of(context).fileCount(files.length.toString()),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(
          isDesktop ? 280.0 : 230.0,
          constraints.maxWidth,
        );
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final filePath in files)
              _LocalFileCard(
                filePath: filePath,
                isCurrentUser: isCurrentUser,
                width: cardWidth,
                actionViewModel: actions,
              ),
          ],
        );
      },
    ),
  );
}
