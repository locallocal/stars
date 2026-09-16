import 'package:markdown/markdown.dart' as md;
import 'package:path/path.dart' as path;

/// Extracts local references without performing file system work.
final class LocalFileReferenceParser {
  LocalFileReferenceParser({
    path.Context? pathContext,
    this.baseDirectory,
    this.homeDirectory,
  }) : _path = pathContext ?? path.context;

  final path.Context _path;
  final String? baseDirectory;
  final String? homeDirectory;

  List<String> pathsFromMarkdown(String markdown) {
    final paths = <String>{};
    void add(String reference) {
      final resolved = resolve(reference);
      if (resolved != null) paths.add(resolved);
    }

    void visit(md.Node node) {
      if (node is md.Text) {
        for (final match in _plainReference.allMatches(node.text)) {
          add(_trimPunctuation(match.group(0)!));
        }
        return;
      }
      if (node is! md.Element || node.tag == 'pre') return;
      switch (node.tag) {
        case 'a':
          add(node.attributes['href'] ?? '');
          return;
        case 'img':
          add(node.attributes['src'] ?? '');
          return;
        case 'code':
          add(node.textContent);
          return;
      }
      for (final child in node.children ?? const <md.Node>[]) {
        visit(child);
      }
    }

    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    for (final node in document.parseLines(markdown.split('\n'))) {
      visit(node);
    }
    return List.unmodifiable(paths);
  }

  /// Resolves native paths, local URIs and source locations against this chat.
  /// Relative references never fall back to the application's working directory.
  String? resolve(String reference) {
    var value = reference.trim();
    if (value.length >= 2 &&
        const {'<': '>', '"': '"', "'": "'"}[value[0]] ==
            value[value.length - 1]) {
      value = value.substring(1, value.length - 1).trim();
    }
    if (value.isEmpty || value.startsWith('#')) return null;
    value = value.replaceFirst(_sourceLocation, '');

    try {
      // Check native absolute paths before parsing a URI (Windows drive letters
      // otherwise look like URI schemes). Decode URI paths only once.
      if (!_path.isAbsolute(value)) {
        final uri = Uri.tryParse(value);
        if (uri == null) return null;
        if (uri.hasScheme) {
          if (uri.scheme == 'file') {
            return _path.normalize(
              uri
                  .removeFragment()
                  .replace(query: '')
                  .toFilePath(windows: _path.style == path.Style.windows),
            );
          }
          if (uri.scheme != 'sandbox' || uri.hasAuthority) return null;
          value = Uri.decodeComponent(uri.path);
          return _path.isAbsolute(value) ? _path.normalize(value) : null;
        }
      }
      value = Uri.decodeComponent(value);
    } on ArgumentError {
      // A native filename can contain a literal percent sign.
    } on UnsupportedError {
      return null;
    } on StateError {
      return null;
    }

    if (_path.isAbsolute(value)) return _path.normalize(value);
    final segments = _path.split(value);
    if (segments.isNotEmpty && segments.first == '~') {
      final home = homeDirectory;
      if (home == null || !_path.isAbsolute(home)) return null;
      return _path.normalize(_path.joinAll([home, ...segments.skip(1)]));
    }
    final base = baseDirectory;
    if (base == null || !_path.isAbsolute(base)) return null;
    // Inline prose/code such as `hello world` is not a file reference.
    if (!_path.extension(value).contains(RegExp(r'[a-zA-Z0-9]')) &&
        segments.length < 2) {
      return null;
    }
    return _path.normalize(_path.join(base, value));
  }
}

// Consume complete tokens so an HTTP URL cannot yield a local path from its
// suffix. Markdown links and inline code preserve paths containing spaces.
final _plainReference = RegExp(
  r'''"[^"\r\n]+"|'[^'\r\n]+'|[^\s<>\[\]{}"'`|，。；！？、（）【】《》“”‘’：]+''',
);
final _sourceLocation = RegExp(r'(?::\d+(?::\d+)?(?:-\d+)?|#L\d+(?:-L?\d+)?)$');

String _trimPunctuation(String reference) {
  var value = reference;
  while (value.isNotEmpty && '.,;:!?'.contains(value[value.length - 1])) {
    value = value.substring(0, value.length - 1);
  }
  if (value.startsWith('(')) value = value.substring(1);
  while (value.endsWith(')') &&
      '('.allMatches(value).length < ')'.allMatches(value).length) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}
