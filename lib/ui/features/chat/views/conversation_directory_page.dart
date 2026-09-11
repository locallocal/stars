import 'package:flutter/material.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_directory_dialog.dart';
import 'package:stars/utils/theme.dart';

/// Full-page conversation directory used by the desktop chat workspace.
final class ConversationDirectoryPage extends StatelessWidget {
  const ConversationDirectoryPage({
    super.key,
    required this.viewModel,
    this.actionViewModel,
  });

  final ConversationDirectoryViewModel viewModel;
  final MessageActionViewModel? actionViewModel;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return ColoredBox(
      key: const ValueKey<String>('desktop-conversation-directory'),
      color: StarsDesktopThemeSpec.workspaceSurface(context),
      child: Padding(
        padding: StarsDesktopThemeSpec.profilePagePadding,
        child: Center(
          child: ConstrainedBox(
            key: const ValueKey<String>(
              'desktop-conversation-directory-content',
            ),
            constraints: const BoxConstraints(
              maxWidth: StarsDesktopThemeSpec.contentMaxWidth,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.conversationDirectory,
                    key: const ValueKey<String>(
                      'desktop-conversation-directory-title',
                    ),
                    style: StarsDesktopThemeSpec.pageTitleStyle(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.conversationDirectoryDescription,
                    style: StarsDesktopThemeSpec.bodyStyle(context)?.copyWith(
                      color: StarsDesktopThemeSpec.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ConversationDirectoryBrowser(
                      viewModel: viewModel,
                      actionViewModel: actionViewModel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
