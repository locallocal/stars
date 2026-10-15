import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

/// A full-width legal document header using the desktop conversation toolbar's
/// layout and theme tokens.
class LegalDocumentHeader extends StatelessWidget {
  const LegalDocumentHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: StarsDesktopThemeSpec.toolbarHeight,
      padding: StarsDesktopThemeSpec.toolbarPadding,
      decoration: StarsDesktopThemeSpec.toolbarDecoration(context),
      child: Row(
        children: [
          StarsDesktopIconAction(
            icon: LucideIcons.arrowLeft,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: StarsDesktopThemeSpec.toolbarTitleStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}
