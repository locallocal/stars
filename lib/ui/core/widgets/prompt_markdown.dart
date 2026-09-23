import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:stars/utils/theme.dart';

/// A selectable Markdown document using the existing prompt surface and typography.
class PromptMarkdown extends StatelessWidget {
  const PromptMarkdown({
    super.key,
    required this.data,
    required this.semanticLabel,
    this.decoration,
  });

  final String data;
  final String semanticLabel;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(
      color: StarsDesktopThemeSpec.text(context),
      fontFamily: 'monospace',
      fontSize: 12,
      fontWeight: FontWeight.normal,
      height: 1.5,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration:
            decoration ?? StarsDesktopThemeSpec.statusDecoration(context),
        child: SelectionArea(
          child: MarkdownBody(
            data: data,
            styleSheet: MarkdownStyleSheet(
              p: body,
              h1: body,
              h2: body,
              h3: body,
              h4: body,
              h5: body,
              h6: body,
              listBullet: body,
              listIndent: 18,
              blockSpacing: 18,
            ),
          ),
        ),
      ),
    );
  }
}
