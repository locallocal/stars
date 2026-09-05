import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/strict_grounding_policy.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/ui/features/chat/views/clear_chat_dialog.dart';
import 'package:stars/ui/features/chats/views/chat_item.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/utils/time.dart';
import 'package:stars/utils/theme.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ChatListBuilder extends StatelessWidget {
  final List<Chat> chatList;
  final List<Bot> bots;
  final String? selectedChatId;
  final bool selectionVisible;
  final bool showExecutionStatus;
  final bool strictGroundingMode;
  final ValueChanged<String> onChatDeleted;
  final void Function(String chatId, Bot bot) onChatSelected;
  final Future<void> Function(String chatId) onDeleteChat;
  final ChatGenerationRegistry generationRegistry;

  const ChatListBuilder({
    super.key,
    required this.chatList,
    required this.bots,
    this.selectedChatId,
    this.selectionVisible = true,
    this.showExecutionStatus = true,
    this.strictGroundingMode = false,
    required this.onChatDeleted,
    required this.onChatSelected,
    required this.onDeleteChat,
    required this.generationRegistry,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDesktopPlatform(context);
    return ListView.separated(
      padding: EdgeInsets.only(bottom: isDesktop ? 8 : 0),
      itemCount: chatList.length,
      separatorBuilder: (context, index) => SizedBox(height: isDesktop ? 8 : 0),
      itemBuilder: (context, index) {
        final chat = chatList[index];
        final matchingBots = bots.where((bot) => bot.id == chat.botId);
        final isOrphaned = matchingBots.isEmpty;
        final bot =
            matchingBots.firstOrNull ??
            Bot(
              id: '',
              name: S.of(context).unavailableBot,
              avatar: '',
              provider: '',
              baseURL: '',
              apiKey: '',
              apiType: '',
              systemPrompt: '',
              model: '',
              createTimestamp: DateTime.now(),
              modifyTimestamp: DateTime.now(),
            );
        void openChat({bool refreshAfterClose = false}) {
          if (isOrphaned) {
            showStarsNotice(
              context,
              S.of(context).botUnavailableTitle,
              description: S.of(context).orphanedChatGuidance,
              tone: StarsNoticeTone.error,
            );
            return;
          }
          if (isDesktop) {
            onChatSelected(chat.id, bot);
            return;
          }

          final navigation = Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder:
                  (context) => ChatPage(
                    id: chat.id,
                    bot: bot,
                    showExecutionStatus: showExecutionStatus,
                    strictGroundingMode: strictGroundingMode,
                  ),
            ),
          );
          if (refreshAfterClose) {
            navigation.then((_) => onChatDeleted(''));
          }
        }

        Future<void> deleteChat() async {
          final registry = generationRegistry;
          final confirm =
              isDesktop
                  ? await showChatShadDialog<bool>(
                    context: context,
                    variant: ShadDialogVariant.alert,
                    builder:
                        (dialogContext) => ShadDialog.alert(
                          title: Text(
                            desktopConversationText(
                              dialogContext,
                              S.of(dialogContext).deleteChat,
                            ),
                          ),
                          description: Text(
                            desktopConversationText(
                              dialogContext,
                              S.of(dialogContext).confirmDeleteChat(bot.name),
                            ),
                          ),
                          actions: [
                            ShadButton.outline(
                              onPressed:
                                  () => Navigator.pop(dialogContext, false),
                              child: Text(S.of(dialogContext).cancel),
                            ),
                            ShadButton.destructive(
                              onPressed:
                                  () => Navigator.pop(dialogContext, true),
                              child: Text(S.of(dialogContext).delete),
                            ),
                          ],
                        ),
                  )
                  : await showDialog<bool>(
                    context: context,
                    builder:
                        (dialogContext) => AlertDialog(
                          title: Center(
                            child: Text(
                              S.of(dialogContext).deleteChat,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    Theme.of(
                                      dialogContext,
                                    ).textTheme.bodyLarge?.fontSize,
                              ),
                            ),
                          ),
                          content: Text(
                            S.of(dialogContext).confirmDeleteChat(bot.name),
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.pop(dialogContext, false),
                              child: Text(S.of(dialogContext).cancel),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.pop(dialogContext, true),
                              child: Text(
                                S.of(dialogContext).delete,
                                style: TextStyle(
                                  color: StarsDesktopThemeSpec.error(
                                    dialogContext,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  );

          if (confirm != true || !context.mounted) return;
          if (isDesktop && registry.hasBlockingRun(chat.id)) {
            if (!registry.supportsCancellationForRun(chat.id)) {
              showStarsNotice(
                context,
                S.of(context).activeRequestCannotStop,
                description: S.of(context).waitForGenerationToFinish,
                tone: StarsNoticeTone.error,
              );
              return;
            }
            final shouldStop = await showStopGenerationBeforeLeavingDialog(
              context,
            );
            if (!shouldStop || !context.mounted) return;
            final stopped = await registry.stopForNavigation(chat.id);
            if (!stopped || !context.mounted) {
              if (context.mounted) {
                showStarsNotice(
                  context,
                  S.of(context).activeRequestCannotStop,
                  description: S.of(context).waitForGenerationToFinish,
                  tone: StarsNoticeTone.error,
                );
              }
              return;
            }
          }

          try {
            final canDelete = await registry.stopForNavigation(chat.id);
            if (!canDelete || !context.mounted) {
              if (context.mounted) {
                showStarsNotice(
                  context,
                  S.of(context).activeRequestCannotStop,
                  description: S.of(context).waitForGenerationToFinish,
                  tone: StarsNoticeTone.error,
                );
              }
              return;
            }

            await onDeleteChat(chat.id);
          } catch (error) {
            if (!context.mounted) return;
            final message = S
                .of(context)
                .deleteChatFailed(safeFailureMessage(context, error));
            showStarsNotice(
              context,
              message,
              tone: StarsNoticeTone.error,
              actionLabel: S.of(context).retry,
              onAction: deleteChat,
            );
            return;
          }

          if (!context.mounted) return;
          generationRegistry.remove(chat.id);
          onChatDeleted(chat.id);
        }

        ChatListItem buildListItem({Widget? trailing}) {
          final storedPreview = chat.lastMessage;
          final localizedPreview =
              storedPreview == strictGroundingPreviewMarker
                  ? S.of(context).strictGroundingUnableToVerify
                  : storedPreview;
          return ChatListItem(
            bot: bot,
            isSelected:
                isDesktop && selectionVisible && selectedChatId == chat.id,
            lastMessage:
                localizedPreview.isEmpty
                    ? desktopConversationText(
                      context,
                      S.of(context).startChatting,
                    )
                    : localizedPreview.length > 25
                    ? '${localizedPreview.substring(0, 25)}...'
                    : localizedPreview,
            timestamp: formatTimestamp(context, chat.lastMessageTimestamp),
            trailing: trailing,
            onTap: () => openChat(refreshAfterClose: !isDesktop),
          );
        }

        if (isDesktop) {
          final contextItems = <Widget>[
            ShadContextMenuItem(
              leading: const Icon(LucideIcons.messageCircle, size: 16),
              enabled: !isOrphaned,
              onPressed: openChat,
              child: Text(
                desktopConversationText(context, S.of(context).startChatting),
              ),
            ),
            const ShadSeparator.horizontal(
              margin: EdgeInsets.symmetric(vertical: 4),
            ),
            ShadContextMenuItem(
              leading: Icon(
                LucideIcons.trash2,
                size: 16,
                color: ShadTheme.of(context).colorScheme.destructive,
              ),
              textStyle: TextStyle(
                color: ShadTheme.of(context).colorScheme.destructive,
              ),
              onPressed: deleteChat,
              child: Text(S.of(context).delete),
            ),
          ];
          return StarsContextMenu(
            key: ValueKey('chat-menu-${chat.id}'),
            items: contextItems,
            child: buildListItem(
              trailing: _ChatRowActions(
                canOpen: !isOrphaned,
                onOpen: openChat,
                onDelete: deleteChat,
              ),
            ),
          );
        }

        return Slidable(
          key: Key(chat.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              CustomSlidableAction(
                onPressed: (_) => openChat(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_rounded, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (_) {},
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: const Icon(Icons.edit_square, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (_) => deleteChat(),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: const Icon(Icons.delete_rounded, size: 20),
              ),
            ],
          ),
          child: buildListItem(),
        );
      },
    );
  }
}

class _ChatRowActions extends StatefulWidget {
  const _ChatRowActions({
    required this.canOpen,
    required this.onOpen,
    required this.onDelete,
  });

  final bool canOpen;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  State<_ChatRowActions> createState() => _ChatRowActionsState();
}

class _ChatRowActionsState extends State<_ChatRowActions> {
  final ShadPopoverController _controller = ShadPopoverController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'chat-row-actions');
  bool _menuItemPressedWithPointer = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _invoke(VoidCallback action) {
    final shouldRestoreFocus =
        !_menuItemPressedWithPointer &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    _menuItemPressedWithPointer = false;
    _controller.hide();
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldRestoreFocus) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
      }
    });
  }

  void _toggleMenu() {
    if (!_controller.isOpen) {
      _menuItemPressedWithPointer = false;
    }
    _controller.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    return ShadPopover(
      controller: _controller,
      popover:
          (context) => SizedBox(
            width: 184,
            child: Listener(
              onPointerDown: (_) => _menuItemPressedWithPointer = true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    enabled: widget.canOpen,
                    onPressed: () => _invoke(widget.onOpen),
                    mainAxisAlignment: MainAxisAlignment.start,
                    leading: const Icon(LucideIcons.messageCircle, size: 16),
                    child: Text(
                      desktopConversationText(
                        context,
                        S.of(context).startChatting,
                      ),
                    ),
                  ),
                  ShadButton.raw(
                    variant: ShadButtonVariant.ghost,
                    size: ShadButtonSize.sm,
                    foregroundColor: colors.destructive,
                    onPressed: () => _invoke(widget.onDelete),
                    mainAxisAlignment: MainAxisAlignment.start,
                    leading: const Icon(LucideIcons.trash2, size: 16),
                    child: Text(S.of(context).delete),
                  ),
                ],
              ),
            ),
          ),
      child: StarsDesktopIconAction(
        icon: LucideIcons.ellipsis,
        label: MaterialLocalizations.of(context).showMenuTooltip,
        focusNode: _focusNode,
        onPressed: _toggleMenu,
        hoverBackgroundColor: Colors.transparent,
      ),
    );
  }
}
