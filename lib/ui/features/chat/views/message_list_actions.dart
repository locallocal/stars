part of 'message_list.dart';

class _DesktopMessageActions extends StatefulWidget {
  const _DesktopMessageActions({
    required this.content,
    required this.isCurrentUser,
    required this.timestamp,
    required this.child,
  });

  final String content;
  final bool isCurrentUser;
  final DateTime timestamp;
  final Widget child;

  @override
  State<_DesktopMessageActions> createState() => _DesktopMessageActionsState();
}

class _DesktopMessageActionsState extends State<_DesktopMessageActions> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'desktop-message');
  bool _hovered = false;

  bool get _canCopy => widget.content.isNotEmpty;
  bool get _showActions => _hovered || _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _copyMessage() async {
    if (!_canCopy) return;
    await Clipboard.setData(ClipboardData(text: widget.content));
    if (!mounted) return;
    showStarsNotice(context, S.of(context).messageCopied);
  }

  @override
  Widget build(BuildContext context) {
    final copyLabel = MaterialLocalizations.of(context).copyButtonLabel;
    final locale = Localizations.localeOf(context).toString();
    final timestamp = intl.DateFormat.yMd(
      locale,
    ).add_Hms().format(widget.timestamp.toLocal());
    final actions = <Widget>[
      if (_canCopy)
        ShadContextMenuItem(
          leading: const Icon(LucideIcons.copy, size: 16),
          onPressed: _copyMessage,
          child: Text(copyLabel),
        ),
    ];

    return StarsContextMenu(
      focusNode: _focusNode,
      enabled: _canCopy,
      items: actions,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Column(
          crossAxisAlignment:
              widget.isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.child,
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: AnimatedOpacity(
                opacity: _showActions ? 1 : 0,
                duration:
                    MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 100),
                child: ExcludeFocus(
                  excluding: !_showActions,
                  child: IgnorePointer(
                    ignoring: !_showActions,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isCurrentUser) ...[
                          _MessageTimestamp(timestamp: timestamp),
                          if (_canCopy) const SizedBox(width: 4),
                        ],
                        if (_canCopy)
                          StarsDesktopIconAction(
                            key: const ValueKey<String>(
                              'desktop-message-copy-action',
                            ),
                            icon: LucideIcons.copy,
                            label: copyLabel,
                            onPressed: _copyMessage,
                          ),
                        if (!widget.isCurrentUser) ...[
                          if (_canCopy) const SizedBox(width: 4),
                          _MessageTimestamp(timestamp: timestamp),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTimestamp extends StatelessWidget {
  const _MessageTimestamp({required this.timestamp});

  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Text(
      timestamp,
      key: const ValueKey<String>('desktop-message-timestamp'),
      style: StarsDesktopThemeSpec.metaStyle(context),
    );
  }
}

class _CopyableCodeBlockBuilder extends MarkdownElementBuilder {
  _CopyableCodeBlockBuilder({
    required this.isDesktop,
    required this.textStyle,
    required this.trustAnnotation,
  });

  final bool isDesktop;
  final TextStyle textStyle;
  final String trustAnnotation;
  String _language = '';

  @override
  void visitElementBefore(md.Element element) {
    _language = _codeBlockLanguage(element);
  }

  @override
  Widget visitText(md.Text text, TextStyle? preferredStyle) {
    return _CopyableCodeBlock(
      source: _codeBlockSource(text.text),
      language: _language,
      isDesktop: isDesktop,
      textStyle: textStyle,
      trustAnnotation: trustAnnotation,
    );
  }
}

class _CopyableCodeBlock extends StatefulWidget {
  const _CopyableCodeBlock({
    required this.source,
    required this.language,
    required this.isDesktop,
    required this.textStyle,
    required this.trustAnnotation,
  });

  final String source;
  final String language;
  final bool isDesktop;
  final TextStyle textStyle;
  final String trustAnnotation;

  @override
  State<_CopyableCodeBlock> createState() => _CopyableCodeBlockState();
}

class _CopyableCodeBlockState extends State<_CopyableCodeBlock> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _copyCode() async {
    if (widget.source.isEmpty) return;
    final copiedText = <String>[
      widget.source,
      if (widget.trustAnnotation.isNotEmpty) ...['---', widget.trustAnnotation],
    ].join('\n\n');
    await Clipboard.setData(ClipboardData(text: copiedText));
    if (!mounted) return;
    showStarsNotice(context, S.of(context).messageCopied);
  }

  @override
  Widget build(BuildContext context) {
    final copyLabel = MaterialLocalizations.of(context).copyButtonLabel;
    final language = widget.language.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.04),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.isDesktop ? 12 : 10,
              right: widget.isDesktop ? 6 : 4,
              top: 2,
              bottom: 2,
            ),
            child: Row(
              children: [
                if (language.isNotEmpty)
                  Expanded(
                    child: Text(
                      language,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: StarsDesktopTokens.of(context).secondaryText,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (widget.isDesktop)
                  StarsDesktopIconAction(
                    key: const ValueKey<String>('message-code-copy-button'),
                    icon: LucideIcons.copy,
                    label: copyLabel,
                    onPressed: widget.source.isEmpty ? null : _copyCode,
                    enabled: widget.source.isNotEmpty,
                    iconSize: 16,
                    foregroundColor:
                        StarsDesktopTokens.of(context).secondaryText,
                  )
                else
                  IconButton(
                    key: const ValueKey<String>('message-code-copy-button'),
                    tooltip: copyLabel,
                    onPressed: widget.source.isEmpty ? null : _copyCode,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: StarsDesktopTokens.of(context).separator,
        ),
        Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(widget.isDesktop ? 12 : 10),
            child: SelectableText(
              widget.source,
              key: const ValueKey<String>('message-code-block-content'),
              style: widget.textStyle,
            ),
          ),
        ),
      ],
    );
  }
}

String _codeBlockSource(String source) =>
    source.replaceFirst(RegExp(r'\n$'), '');

String _codeBlockLanguage(md.Element element) {
  final children = element.children;
  if (children == null) return '';

  for (final child in children) {
    if (child is! md.Element || child.tag != 'code') continue;
    final classes =
        child.attributes['class']?.split(RegExp(r'\s+')) ?? const [];
    for (final className in classes) {
      if (className.startsWith('language-')) {
        return className.substring('language-'.length);
      }
    }
  }
  return '';
}
