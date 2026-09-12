part of 'desktop_layout.dart';

class _UnifiedDesktopToolbar extends StatelessWidget {
  final int currentIndex;
  final Bot? bot;
  final bool isChat;
  final bool compact;
  final bool sidebarVisible;
  final bool conversationInfoVisible;
  final bool conversationDirectoryVisible;
  final bool conversationInfoAvailable;
  final VoidCallback onToggleSidebar;
  final VoidCallback? onToggleConversationInfo;
  final VoidCallback? onCreateChat;
  final VoidCallback? onSearchRequested;
  final VoidCallback? onBrowseConversationDirectory;
  final VoidCallback? onClearChat;

  const _UnifiedDesktopToolbar({
    required this.currentIndex,
    required this.bot,
    required this.isChat,
    required this.compact,
    required this.sidebarVisible,
    required this.conversationInfoVisible,
    required this.conversationDirectoryVisible,
    required this.conversationInfoAvailable,
    required this.onToggleSidebar,
    required this.onToggleConversationInfo,
    required this.onCreateChat,
    required this.onSearchRequested,
    required this.onBrowseConversationDirectory,
    required this.onClearChat,
  });

  @override
  Widget build(BuildContext context) {
    final activeBot = bot;
    final title = switch (currentIndex) {
      0 =>
        activeBot?.name ??
            desktopConversationText(context, S.of(context).chats),
      1 => activeBot?.name ?? S.of(context).Bots,
      2 => S.of(context).skillLibrary,
      3 => S.of(context).mcpServers,
      _ => S.of(context).profile,
    };
    final summary =
        activeBot == null
            ? null
            : [
              activeBot.provider.trim(),
              activeBot.model.trim(),
            ].where((value) => value.isNotEmpty).join(' · ');

    return Container(
      key: const ValueKey<String>('desktop-unified-toolbar'),
      height: StarsDesktopThemeSpec.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: StarsDesktopThemeSpec.toolbarSurface(context),
        border: Border(
          bottom: BorderSide(
            width: 0,
            color: StarsDesktopThemeSpec.divider(context),
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child:
                !sidebarVisible
                    ? StarsDesktopIconAction(
                      key: const ValueKey<String>('desktop-toolbar-sidebar'),
                      label: S.of(context).showSidebar,
                      onPressed: onToggleSidebar,
                      icon: LucideIcons.panelLeftOpen,
                    )
                    : const SizedBox.shrink(),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activeBot != null) ...[
                  ShadAvatar(
                    key: const ValueKey<String>(
                      'desktop-toolbar-active-bot-avatar',
                    ),
                    activeBot.avatar.isEmpty ? null : File(activeBot.avatar),
                    size: const Size.square(
                      StarsDesktopThemeSpec.toolbarAvatarSize,
                    ),
                    fit: BoxFit.cover,
                    placeholder: SizedBox.square(
                      key: const ValueKey<String>(
                        'desktop-toolbar-active-bot-logo',
                      ),
                      dimension: StarsDesktopThemeSpec.toolbarLogoSize,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: buildProviderLogo(
                          context,
                          '',
                          activeBot.provider,
                          StarsDesktopThemeSpec.toolbarLogoSize,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StarsDesktopThemeSpec.toolbarTitleStyle(context),
                  ),
                ),
                if (summary != null && summary.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StarsDesktopThemeSpec.metaStyle(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child:
                isChat
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (compact && onCreateChat != null)
                          StarsDesktopIconAction(
                            key: const ValueKey<String>(
                              'desktop-toolbar-new-chat',
                            ),
                            label: desktopConversationText(
                              context,
                              S.of(context).newChat,
                            ),
                            onPressed: onCreateChat,
                            icon: desktopStartConversationIcon,
                          ),
                        if (onClearChat != null)
                          StarsDesktopIconAction(
                            key: const ValueKey<String>(
                              'desktop-toolbar-clear-chat',
                            ),
                            label: desktopConversationText(
                              context,
                              S.of(context).clearChatHistory,
                            ),
                            onPressed: onClearChat,
                            icon: LucideIcons.eraser,
                          ),
                        if (onBrowseConversationDirectory != null)
                          StarsDesktopIconAction(
                            key: const ValueKey<String>(
                              'desktop-toolbar-conversation-directory',
                            ),
                            label: S.of(context).browseConversationDirectory,
                            onPressed: onBrowseConversationDirectory,
                            selected: conversationDirectoryVisible,
                            variant:
                                conversationDirectoryVisible
                                    ? ShadButtonVariant.secondary
                                    : ShadButtonVariant.ghost,
                            icon: LucideIcons.folderOpen,
                          ),
                        if (conversationInfoAvailable)
                          StarsDesktopIconAction(
                            key: const ValueKey<String>(
                              'desktop-toolbar-conversation-info',
                            ),
                            label:
                                conversationInfoVisible
                                    ? S.of(context).hideConversationInformation
                                    : S.of(context).showConversationInformation,
                            onPressed: onToggleConversationInfo,
                            selected: conversationInfoVisible,
                            variant:
                                conversationInfoVisible
                                    ? ShadButtonVariant.secondary
                                    : ShadButtonVariant.ghost,
                            icon: LucideIcons.info,
                          ),
                      ],
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
