part of 'conversation_memory_panel.dart';

final class _ConversationSystemPromptBlock extends StatelessWidget {
  const _ConversationSystemPromptBlock({
    required this.bot,
    required this.conversationId,
    required this.artifactsDirectoryPath,
  });

  final Bot bot;
  final String conversationId;
  final String artifactsDirectoryPath;

  @override
  Widget build(BuildContext context) {
    final label = S.of(context).applicationInjectedPrompt;
    final prompt =
        buildStarsConversationContext(
          agentId: bot.id,
          agentName: bot.name,
          conversationId: conversationId,
          artifactsDirectoryPath: artifactsDirectoryPath,
          languageCode: Localizations.localeOf(context).toLanguageTag(),
        ).trim();
    return Column(
      key: const ValueKey<String>('conversation-system-prompt-block'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 25),
        Text(
          label,
          key: const ValueKey<String>('conversation-system-prompt-title'),
          style: StarsDesktopThemeSpec.sectionTitleStyle(context),
        ),
        const SizedBox(height: 12),
        Semantics(
          key: const ValueKey<String>('conversation-system-prompt-value'),
          textField: true,
          readOnly: true,
          label: label,
          value: prompt,
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: StarsDesktopThemeSpec.statusDecoration(context),
              child: SelectableText(
                prompt,
                style: TextStyle(
                  color: StarsDesktopThemeSpec.text(context),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _ConversationSummaryDocument extends StatelessWidget {
  const _ConversationSummaryDocument({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    return ShadCard(
      key: const ValueKey<String>('conversation-summary-surface'),
      width: double.infinity,
      padding: EdgeInsets.zero,
      backgroundColor: tokens.raisedSurface,
      radius: StarsDesktopThemeSpec.containerRadius,
      border: ShadBorder.all(color: tokens.separator, width: 1),
      child: Markdown(
        key: const ValueKey<String>('conversation-summary-markdown'),
        data: _summaryMarkdownBody(markdown),
        selectable: true,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        styleSheet: _summaryMarkdownStyle(context),
      ),
    );
  }
}

MarkdownStyleSheet _summaryMarkdownStyle(BuildContext context) {
  final tokens = StarsDesktopTokens.of(context);
  final body = (StarsDesktopThemeSpec.bodyStyle(context) ??
          const TextStyle(fontSize: 14))
      .copyWith(color: tokens.primaryText, height: 1.6);
  final pageTitle = (StarsDesktopThemeSpec.pageTitleStyle(context) ?? body)
      .copyWith(color: tokens.primaryText);
  final sectionTitle = (StarsDesktopThemeSpec.toolbarTitleStyle(context) ??
          body)
      .copyWith(color: tokens.primaryText);
  final subsectionTitle = body.copyWith(fontWeight: FontWeight.w600);
  final meta = (StarsDesktopThemeSpec.metaStyle(context) ??
          const TextStyle(fontSize: 12))
      .copyWith(color: tokens.secondaryText, height: 1.5);

  return MarkdownStyleSheet(
    p: body,
    pPadding: const EdgeInsets.only(bottom: 4),
    h1: pageTitle,
    h1Padding: const EdgeInsets.only(top: 8, bottom: 8),
    h2: sectionTitle,
    h2Padding: const EdgeInsets.only(top: 12, bottom: 6),
    h3: subsectionTitle,
    h3Padding: const EdgeInsets.only(top: 10, bottom: 4),
    h4: subsectionTitle,
    h4Padding: const EdgeInsets.only(top: 8, bottom: 4),
    h5: meta.copyWith(fontWeight: FontWeight.w600),
    h5Padding: const EdgeInsets.only(top: 6, bottom: 2),
    h6: meta.copyWith(fontWeight: FontWeight.w600),
    h6Padding: const EdgeInsets.only(top: 6, bottom: 2),
    strong: const TextStyle(fontWeight: FontWeight.w600),
    em: const TextStyle(fontStyle: FontStyle.italic),
    a: TextStyle(
      color: tokens.accent,
      decoration: TextDecoration.underline,
      decorationColor: tokens.accent,
    ),
    code: meta.copyWith(
      color: tokens.primaryText,
      backgroundColor: tokens.controlFill,
      fontFamily: 'monospace',
    ),
    blockquote: body.copyWith(color: tokens.secondaryText),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    blockquoteDecoration: BoxDecoration(
      color: tokens.controlFill,
      borderRadius: StarsDesktopThemeSpec.itemRadius,
      border: Border(left: BorderSide(color: tokens.separator, width: 3)),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    codeblockDecoration: BoxDecoration(
      color: tokens.controlFill,
      borderRadius: StarsDesktopThemeSpec.itemRadius,
      border: Border.all(color: tokens.separator),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(top: BorderSide(color: tokens.separator)),
    ),
    listBullet: body.copyWith(color: tokens.secondaryText),
    listBulletPadding: const EdgeInsets.only(right: 6),
    listIndent: 22,
    tableHead: subsectionTitle,
    tableBody: body,
    tableBorder: TableBorder.all(color: tokens.separator),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    blockSpacing: 12,
  );
}

String _summaryMarkdownBody(String markdown) {
  final lines = markdown.replaceAll('\r\n', '\n').split('\n');
  final headingIndex = lines.indexWhere((line) => line.trim().isNotEmpty);
  if (headingIndex < 0 || lines[headingIndex].trim() != '# 会话摘要') {
    return markdown;
  }
  var bodyStart = headingIndex + 1;
  while (bodyStart < lines.length && lines[bodyStart].trim().isEmpty) {
    bodyStart++;
  }
  final body = lines.sublist(bodyStart).join('\n');
  return body.trim().isEmpty ? markdown : body;
}

final class _MemoryMetric extends StatelessWidget {
  const _MemoryMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidth,
    this.valueTextAlign = TextAlign.right,
  });

  final IconData icon;
  final String label;
  final String value;
  final double? valueWidth;
  final TextAlign valueTextAlign;

  @override
  Widget build(BuildContext context) => StarsInspectorInfoRow(
    icon: icon,
    label: label,
    value: value,
    trailingWidth: valueWidth,
    valueTextAlign: valueTextAlign,
  );
}

final class _AutomaticMemoryRow extends StatelessWidget {
  const _AutomaticMemoryRow({
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: StarsInspectorInfoRow(
      key: const ValueKey<String>('automatic-memory-row'),
      icon: LucideIcons.brain,
      label: S.of(context).automaticMemory,
      padding: const EdgeInsets.symmetric(vertical: 5),
      crossAxisAlignment: CrossAxisAlignment.center,
      iconLabelGapKey: const ValueKey<String>('automatic-memory-icon-gap'),
      trailingWidth: _memoryTrailingControlWidth,
      trailing: ShadSwitch(
        key: const ValueKey<String>('automatic-memory-switch'),
        width: _memoryTrailingControlWidth,
        value: value,
        enabled: enabled,
        onChanged: onChanged,
      ),
    ),
  );
}

final class _MemoryActions extends StatelessWidget {
  const _MemoryActions({
    required this.compacting,
    required this.onViewSummary,
    required this.onManage,
    required this.onCompact,
  });

  final bool compacting;
  final VoidCallback onViewSummary;
  final VoidCallback onManage;
  final VoidCallback onCompact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: const ValueKey<String>('conversation-memory-actions'),
    builder: (context, constraints) {
      const spacing = 8.0;
      final compactLayout = constraints.maxWidth < 320;
      final buttonWidth =
          ((constraints.maxWidth - spacing * 2) / 3)
              .clamp(0.0, double.infinity)
              .toDouble();
      final padding = EdgeInsets.symmetric(horizontal: compactLayout ? 3 : 8);
      final iconSize = compactLayout ? 14.0 : 15.0;
      Widget label(String value) => Flexible(
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      );

      final viewSummary = ShadButton.outline(
        key: const ValueKey<String>('memory-view-summary'),
        size: ShadButtonSize.sm,
        width: buttonWidth,
        padding: padding,
        gap: starsInspectorIconLabelGap,
        onPressed: onViewSummary,
        leading: Icon(LucideIcons.fileText, size: iconSize),
        child: label(S.of(context).viewSummary),
      );
      final manage = ShadButton.outline(
        key: const ValueKey<String>('memory-manage'),
        size: ShadButtonSize.sm,
        width: buttonWidth,
        padding: padding,
        gap: starsInspectorIconLabelGap,
        onPressed: onManage,
        leading: Icon(LucideIcons.brain, size: iconSize),
        child: label(S.of(context).manageMemory),
      );
      final compact = ShadButton.outline(
        key: const ValueKey<String>('memory-compact-now'),
        size: ShadButtonSize.sm,
        width: buttonWidth,
        padding: padding,
        gap: starsInspectorIconLabelGap,
        onPressed: compacting ? null : onCompact,
        leading:
            compacting
                ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(LucideIcons.minimize2, size: iconSize),
        child: label(S.of(context).compactNow),
      );

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [viewSummary, manage, compact],
      );
    },
  );
}
