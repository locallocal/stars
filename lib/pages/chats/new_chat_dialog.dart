import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/chat.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/pages/common/new_chat.dart';
import 'package:stars/services/bot_service.dart';
import 'package:stars/services/chat_service.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

class NewChatDialog extends StatefulWidget {
  final void Function(String chatId, Bot bot)? onChatCreated;
  final Future<List<Bot>>? botsFuture;

  const NewChatDialog({
    super.key,
    required this.onChatCreated,
    this.botsFuture,
  });

  @override
  State<NewChatDialog> createState() => _NewChatDialogState();
}

class _NewChatDialogState extends State<NewChatDialog> {
  late Future<List<Bot>> _botsFuture;
  final ScrollController _desktopScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _botsFuture = widget.botsFuture ?? BotService.getBots();
  }

  @override
  void didUpdateWidget(covariant NewChatDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botsFuture != widget.botsFuture) {
      _botsFuture = widget.botsFuture ?? BotService.getBots();
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

    return Dialog(
      insetPadding: EdgeInsets.all(inset),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: SizedBox(
          width: dialogWidth,
          child: StarsGlassSurface(
            role: StarsGlassRole.popover,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDesktopHeader(context),
                Divider(
                  height: 1,
                  thickness: 0,
                  color: DesktopThemeTokens.divider(context),
                ),
                Flexible(child: _buildDesktopContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).newChat,
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
          StarsToolbarButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
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
            child: Center(child: CircularProgressIndicator()),
          );
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tokens.selectedFill,
                        borderRadius: DesktopThemeTokens.containerRadius,
                      ),
                      child: Icon(
                        Icons.smart_toy_outlined,
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
              itemCount: bots.length,
              separatorBuilder: (context, index) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final bot = bots[index];
                return _DesktopBotChoice(
                  key: ValueKey<String>(bot.id),
                  bot: bot,
                  onTap: () => _createChat(bot),
                );
              },
            ),
          ),
        );
      },
    );
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
                          onTap: () => _createChat(bot),
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
    final chat = await createNewChat(bot);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final isDesktop = isDesktopOrTabletPlatform(context);

    widget.onChatCreated?.call(chat.id, bot);
    navigator.pop();

    if (isDesktop) {
      return;
    }

    navigator
        .push(
          MaterialPageRoute(
            builder: (context) => ChatPage(id: chat.id, bot: bot),
          ),
        )
        .then((_) {
          ChatService.notifyChatListChanged();
        });
  }
}

class _DesktopBotChoice extends StatelessWidget {
  const _DesktopBotChoice({super.key, required this.bot, required this.onTap});

  final Bot bot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      bot.provider.trim(),
      bot.model.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');

    return DesktopInteractiveListItem(
      selected: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _BotAvatar(bot: bot, radius: 20),
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
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: DesktopThemeTokens.softText(context),
          ),
        ],
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
