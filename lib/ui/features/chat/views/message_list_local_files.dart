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
