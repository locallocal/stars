import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as path;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/core/widgets/syntax_highlighted_code.dart';
import 'package:stars/utils/theme.dart';
import 'package:webview_all/webview_all.dart';

const _sourcePreviewLimit = 1024 * 1024;

/// Runs a local HTML artifact in an embedded browser while keeping source
/// inspection and a readable fallback available on unsupported platforms.
class LocalHtmlFilePreview extends StatefulWidget {
  const LocalHtmlFilePreview({super.key, required this.file});

  final File file;

  @override
  State<LocalHtmlFilePreview> createState() => _LocalHtmlFilePreviewState();
}

class _LocalHtmlFilePreviewState extends State<LocalHtmlFilePreview> {
  late Future<_HtmlPreviewData> _preview;
  late Future<WebViewController?> _webView;
  WebViewController? _controller;
  Object? _runtimeError;
  var _loadingProgress = 0;
  var _showSource = false;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(covariant LocalHtmlFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) _loadFile();
  }

  void _loadFile() {
    _showSource = false;
    _controller = null;
    _runtimeError = null;
    _loadingProgress = 0;
    _preview = _readHtmlPreview(widget.file);
    _webView = _createWebViewController(widget.file.path);
  }

  Future<WebViewController?> _createWebViewController(String filePath) async {
    if (WebViewPlatform.instance == null) return null;

    try {
      final controller = WebViewController(
        onPermissionRequest:
            (request) => unawaited(_ignoreWebViewError(request.deny())),
      );
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.enableZoom(true);
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _navigationDecision,
          onPageStarted: (_) => _setLoadingProgress(0),
          onProgress: _setLoadingProgress,
          onPageFinished: (_) => _setLoadingProgress(100),
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            _setRuntimeError(error);
          },
          onSslAuthError:
              (error) => unawaited(_ignoreWebViewError(error.cancel())),
        ),
      );
      await controller.loadFile(filePath);
      if (!mounted || widget.file.path != filePath) return null;
      _controller = controller;
      return controller;
    } on Object {
      // Keep source and readable-content inspection available when the native
      // browser engine is missing or fails to initialize.
      return null;
    }
  }

  NavigationDecision _navigationDecision(NavigationRequest request) {
    if (!request.isMainFrame) return NavigationDecision.navigate;
    final uri = Uri.tryParse(request.url);
    if (uri == null || !_isPreviewPageAllowed(uri)) {
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  bool _isPreviewPageAllowed(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'about' || scheme == 'blob' || scheme == 'data') return true;
    if (scheme != 'file') return false;

    final previewRoot = _resolvedPath(widget.file.parent);
    final requestedFile = _resolvedPath(File(uri.toFilePath()));
    return path.equals(previewRoot, requestedFile) ||
        path.isWithin(previewRoot, requestedFile);
  }

  void _setLoadingProgress(int progress) {
    if (!mounted || _loadingProgress == progress) return;
    setState(() {
      _loadingProgress = progress.clamp(0, 100);
      if (progress < 100) _runtimeError = null;
    });
  }

  void _setRuntimeError(Object error) {
    if (!mounted) return;
    setState(() => _runtimeError = error);
  }

  void _setSourceMode(bool showSource) {
    if (_showSource == showSource) return;
    setState(() => _showSource = showSource);
  }

  void _reload() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _runtimeError = null;
      _loadingProgress = 0;
    });
    unawaited(_reloadController(controller));
  }

  Future<void> _reloadController(WebViewController controller) async {
    try {
      await controller.reload();
    } on Object catch (error) {
      _setRuntimeError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HtmlPreviewData>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _HtmlPreviewPlaceholder(
            icon: LucideIcons.fileWarning,
            message: S.of(context).filePreviewUnavailable,
          );
        }
        final preview = snapshot.data;
        if (preview == null) {
          return const Center(
            child: SizedBox(width: 160, child: ShadProgress()),
          );
        }
        return _HtmlPreviewSurface(
          preview: preview,
          webView: _webView,
          runtimeError: _runtimeError,
          loadingProgress: _loadingProgress,
          showSource: _showSource,
          onReload: _reload,
          onModeChanged: _setSourceMode,
        );
      },
    );
  }
}

String _resolvedPath(FileSystemEntity entity) {
  try {
    return entity.resolveSymbolicLinksSync();
  } on FileSystemException {
    return path.normalize(path.absolute(entity.path));
  }
}

Future<void> _ignoreWebViewError(Future<void> operation) async {
  try {
    await operation;
  } on Object {
    // Permission and TLS requests are denied by default. A native teardown can
    // race these callbacks, and does not need to surface an app-level error.
  }
}

final class _HtmlPreviewData {
  const _HtmlPreviewData({
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

class _HtmlPreviewSurface extends StatelessWidget {
  const _HtmlPreviewSurface({
    required this.preview,
    required this.webView,
    required this.runtimeError,
    required this.loadingProgress,
    required this.showSource,
    required this.onReload,
    required this.onModeChanged,
  });

  final _HtmlPreviewData preview;
  final Future<WebViewController?> webView;
  final Object? runtimeError;
  final int loadingProgress;
  final bool showSource;
  final VoidCallback onReload;
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
                final controls = _HtmlPreviewControls(
                  showSource: showSource,
                  previewLabel: strings.preview,
                  sourceLabel: strings.sourceCode,
                  refreshLabel: strings.refresh,
                  onReload: onReload,
                  onModeChanged: onModeChanged,
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      const SizedBox(height: 10),
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
          if (!showSource && loadingProgress < 100)
            ShadProgress(value: loadingProgress / 100),
          Expanded(
            child:
                showSource
                    ? _HtmlSourceView(source: preview.source)
                    : _HtmlRuntimeView(
                      preview: preview,
                      webView: webView,
                      runtimeError: runtimeError,
                      onReload: onReload,
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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.h4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ShadBadge.outline(child: Text('JS')),
                ],
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

class _HtmlPreviewControls extends StatelessWidget {
  const _HtmlPreviewControls({
    required this.showSource,
    required this.previewLabel,
    required this.sourceLabel,
    required this.refreshLabel,
    required this.onReload,
    required this.onModeChanged,
  });

  final bool showSource;
  final String previewLabel;
  final String sourceLabel;
  final String refreshLabel;
  final VoidCallback onReload;
  final ValueChanged<bool> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        if (!showSource)
          StarsDesktopIconAction(
            key: const ValueKey<String>('message-local-html-reload'),
            icon: LucideIcons.refreshCw,
            iconSize: 16,
            label: refreshLabel,
            onPressed: onReload,
          ),
        _HtmlPreviewModeButton(
          selected: !showSource,
          icon: LucideIcons.eye,
          label: previewLabel,
          onPressed: () => onModeChanged(false),
        ),
        _HtmlPreviewModeButton(
          selected: showSource,
          icon: LucideIcons.code2,
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
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
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
      leading: Icon(icon, size: 15),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _HtmlRuntimeView extends StatelessWidget {
  const _HtmlRuntimeView({
    required this.preview,
    required this.webView,
    required this.runtimeError,
    required this.onReload,
  });

  final _HtmlPreviewData preview;
  final Future<WebViewController?> webView;
  final Object? runtimeError;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController?>(
      future: webView,
      builder: (context, snapshot) {
        final controller = snapshot.data;
        if (runtimeError != null) {
          return _HtmlPreviewPlaceholder(
            icon: LucideIcons.triangleAlert,
            message: S.of(context).filePreviewUnavailable,
            action: ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: onReload,
              child: Text(S.of(context).refresh),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(width: 160, child: ShadProgress()),
          );
        }
        if (controller == null) {
          return _HtmlReadableFallback(text: preview.text);
        }
        return ColoredBox(
          key: const ValueKey<String>('message-local-html-runtime'),
          color: Colors.white,
          child: WebViewWidget(controller: controller),
        );
      },
    );
  }
}

class _HtmlSourceView extends StatelessWidget {
  const _HtmlSourceView({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) => StarsSyntaxHighlightedCode(
    key: const ValueKey<String>('message-local-html-source'),
    source: source,
    language: 'xml',
    framed: false,
  );
}

class _HtmlReadableFallback extends StatelessWidget {
  const _HtmlReadableFallback({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SingleChildScrollView(
      key: const ValueKey<String>('message-local-html-content'),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: SelectableText(
          text,
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.cardForeground,
            height: 1.65,
          ),
        ),
      ),
    );
  }
}

class _HtmlPreviewPlaceholder extends StatelessWidget {
  const _HtmlPreviewPlaceholder({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.controlFill,
        borderRadius: StarsDesktopThemeSpec.containerRadius,
        border: Border.all(color: tokens.separator),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: tokens.secondaryText),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.secondaryText),
              ),
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          ),
        ),
      ),
    );
  }
}

Future<_HtmlPreviewData> _readHtmlPreview(File file) =>
    Isolate.run(() => _readHtmlPreviewInWorker(file.path));

_HtmlPreviewData _readHtmlPreviewInWorker(String filePath) {
  final source = _readSource(File(filePath));
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
  if (body != null) _writeReadableText(body, buffer);
  final text = _normalizeReadableText(buffer.toString());
  return _HtmlPreviewData(
    source: source,
    title: title,
    description: description,
    text: text.isEmpty ? description : text,
  );
}

String _readSource(File file) {
  final handle = file.openSync();
  try {
    final length = handle.lengthSync();
    final byteCount = length.clamp(0, _sourcePreviewLimit);
    final content = utf8.decode(
      handle.readSync(byteCount),
      allowMalformed: true,
    );
    return length > _sourcePreviewLimit ? '$content\n\n…' : content;
  } finally {
    handle.closeSync();
  }
}

const _hiddenElements = {
  'head',
  'script',
  'style',
  'template',
  'noscript',
  'svg',
};

const _blockElements = {
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

void _writeReadableText(html_dom.Node node, StringBuffer buffer) {
  if (node is html_dom.Text) {
    var text = node.data.replaceAll(RegExp(r'\s+'), ' ');
    if (text.trim().isEmpty) return;
    if (buffer.isEmpty) text = text.trimLeft();
    buffer.write(text);
    return;
  }
  if (node is! html_dom.Element) return;
  final tag = node.localName;
  if (_hiddenElements.contains(tag)) return;
  if (tag == 'br') {
    buffer.writeln();
    return;
  }
  final isBlock = _blockElements.contains(tag);
  if (isBlock && buffer.isNotEmpty) buffer.writeln();
  for (final child in node.nodes) {
    _writeReadableText(child, buffer);
  }
  if (isBlock) buffer.writeln();
}

String _normalizeReadableText(String source) =>
    source
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n\n')
        .trim();
