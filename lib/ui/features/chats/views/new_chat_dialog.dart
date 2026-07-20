import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/ui/features/chats/view_models/new_chat_view_model.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

class NewChatDialog extends StatefulWidget {
  final void Function(String chatId, Bot bot)? onChatCreated;
  final Future<List<Bot>>? botsFuture;
  final NewChatViewModel? viewModel;

  const NewChatDialog({
    super.key,
    required this.onChatCreated,
    this.botsFuture,
    this.viewModel,
  }) : assert(
         botsFuture != null || viewModel != null,
         'Provide a NewChatViewModel or a botsFuture.',
       );

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  late Future<List<Bot>> _botsFuture;
  final ScrollController _desktopScrollController = ScrollController();
  bool _creating = false;
  String? _creatingBotId;
  String? _creationError;

  @override
  void initState() {
    super.initState();
    _botsFuture = widget.botsFuture ?? widget.viewModel!.loadBots();
  }

  @override
  void didUpdateWidget(covariant NewChatDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botsFuture != widget.botsFuture) {
      _botsFuture = widget.botsFuture ?? widget.viewModel!.loadBots();
      _creationError = null;
    }
  }

  @override
  void dispose() {
    _desktopScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDesktopOrTabletPlatform(context)) {
      return _buildMobileDialog(context);
    }

    final windowSize = MediaQuery.sizeOf(context);
    final inset =
        windowSize.width < 720 || windowSize.height < 640 ? 16.0 : 24.0;
    final dialogWidth = math.max(
      0.0,
      math.min(480.0, windowSize.width - inset * 2),
    );
    final dialogMaxHeight = math.max(
      0.0,
      math.min(560.0, windowSize.height - inset * 2),
    );

    return ShadDialog(
      constraints: BoxConstraints(
        maxWidth: dialogWidth,
        maxHeight: dialogMaxHeight,
      ),
      padding: EdgeInsets.zero,
      gap: 0,
      scrollable: false,
      useSafeArea: false,
      removeBorderRadiusWhenTiny: false,
      closeIcon: const SizedBox.shrink(),
      child: SizedBox(
        key: const ValueKey<String>('new-chat-dialog-content'),
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDesktopHeader(context),
            ShadSeparator.horizontal(
              thickness: 1,
              color: DesktopThemeTokens.divider(context),
            ),
            Flexible(child: _buildDesktopContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desktopConversationText(context, S.of(context).newChat),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopThemeTokens.toolbarTitleStyle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  S.of(context).selectBot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesktopThemeTokens.metaStyle(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StarsDesktopIconAction(
            icon: LucideIcons.x,
            label: closeLabel,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return FutureBuilder<List<Bot>>(
      future: _botsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: SizedBox(width: 120, child: ShadProgress())),
          );
        }

        if (snapshot.hasError) {
          return _buildDesktopLoadError(context, snapshot.error);
        }

        final bots = snapshot.data ?? const <Bot>[];
        if (bots.isEmpty) {
          final tokens = StarsDesktopTokens.of(context);
          return SizedBox(
            height: 220,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShadAvatar(
                      null,
                      size: const Size.square(40),
                      backgroundColor: tokens.selectedFill,
                      placeholder: Icon(
                        LucideIcons.bot,
                        size: 18,
                        color: tokens.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.of(context).noBotsAvailable,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 220),
          child: Scrollbar(
            controller: _desktopScrollController,
            child: ListView.separated(
              controller: _desktopScrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: bots.length + (_creationError == null ? 0 : 1),
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                if (_creationError != null && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
                    child: ShadAlert.destructive(
                      icon: const Icon(LucideIcons.circleAlert, size: 18),
                      title: Text(_creationError!),
                    ),
                  );
                }

                final botIndex = index - (_creationError == null ? 0 : 1);
                final bot = bots[botIndex];
                return _DesktopBotChoice(
                  key: ValueKey<String>(bot.id),
                  bot: bot,
                  enabled: !_creating,
                  creating: _creatingBotId == bot.id,
                  onTap: () => _createChat(bot),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLoadError(BuildContext context, Object? error) {
    return SizedBox(
      height: 220,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: ShadAlert.destructive(
            icon: const Icon(LucideIcons.circleAlert),
            title: Text(S.of(context).unableToLoadBots),
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error?.toString() ?? ''),
                const SizedBox(height: 12),
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: _retryLoadBots,
                  leading: const Icon(LucideIcons.refreshCw, size: 16),
                  child: Text(S.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _retryLoadBots() {
    setState(() {
      _creationError = null;
      _botsFuture = widget.viewModel?.loadBots() ?? widget.botsFuture!;
    });
  }

  Widget _buildMobileDialog(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  S.of(context).newChat,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 6,
                radius: const Radius.circular(10),
                child: FutureBuilder<List<Bot>>(
                  future: _botsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(S.of(context).noBotsAvailable));
                    }

                    final bots = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: bots.length,
                      itemBuilder: (context, index) {
                        final bot = bots[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: _BotAvatar(bot: bot, radius: 24),
                          title: Text(
                            bot.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${bot.provider}-${bot.model}'),
                          onTap: _creating ? null : () => _createChat(bot),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _createChat(Bot bot) async {
    if (_creating) return;

    setState(() {
      _creating = true;
      _creatingBotId = bot.id;
      _creationError = null;
    });

    late final Chat chat;
    try {
      final viewModel = widget.viewModel;
      if (viewModel == null) {
        throw StateError('Chat creation requires a NewChatViewModel.');
      }
      chat = await viewModel.create(bot);
    } catch (error) {
      if (!mounted) return;
      final message = desktopConversationText(
        context,
        S.of(context).createChatFailed(error.toString()),
      );
      setState(() {
        _creating = false;
        _creatingBotId = null;
        _creationError = message;
      });
      if (!isDesktopOrTabletPlatform(context)) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    if (!mounted) return;
    ChatPageState.requestComposerFocus(chat.id);
    final navigator = Navigator.of(context);
    final isDesktop = isDesktopOrTabletPlatform(context);

    widget.onChatCreated?.call(chat.id, bot);
    navigator.pop();

    if (isDesktop) {
      return;
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => ChatPage(id: chat.id, bot: bot),
      ),
    );
  }
}

class _DesktopBotChoice extends StatelessWidget {
  const _DesktopBotChoice({
    super.key,
    required this.bot,
    required this.onTap,
    required this.enabled,
    required this.creating,
  });

  final Bot bot;
  final VoidCallback onTap;
  final bool enabled;
  final bool creating;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      bot.provider.trim(),
      bot.model.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');

    return Semantics(
      enabled: enabled,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled || creating ? 1 : 0.55,
          child: DesktopInteractiveListItem(
            selected: false,
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                ShadAvatar(
                  bot.avatar.isEmpty ? null : File(bot.avatar),
                  size: const Size.square(40),
                  backgroundColor:
                      bot.avatar.isEmpty
                          ? getFrostedProviderColor(
                            bot.provider,
                            Theme.of(context).colorScheme.primary,
                          )
                          : Theme.of(context).colorScheme.primary,
                  placeholder: buildProviderLogo(context, '', bot.provider, 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesktopThemeTokens.bodyStyle(
                          context,
                        )?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesktopThemeTokens.metaStyle(context),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (creating)
                  SizedBox(
                    width: 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          S.of(context).creatingChat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesktopThemeTokens.metaStyle(context),
                        ),
                        const SizedBox(height: 5),
                        ShadProgress(
                          minHeight: 3,
                          semanticsLabel: S.of(context).creatingChat,
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: DesktopThemeTokens.softText(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar({required this.bot, required this.radius});

  final Bot bot;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          bot.avatar.isEmpty
              ? getFrostedProviderColor(
                bot.provider,
                Theme.of(context).colorScheme.primary,
              )
              : Theme.of(context).colorScheme.primary,
      backgroundImage:
          bot.avatar.isNotEmpty ? FileImage(File(bot.avatar)) : null,
      child:
          bot.avatar.isEmpty
              ? buildProviderLogo(context, '', bot.provider, radius)
              : null,
    );
  }
}
