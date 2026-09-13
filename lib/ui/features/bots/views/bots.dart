import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_transfer_repository.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/ui/core/widgets/model_modalities.dart';
import 'package:stars/ui/features/bots/views/add_bot.dart';
import 'package:stars/ui/features/bots/views/edit_bot.dart';
import 'package:stars/ui/features/chat/views/chat.dart';
import 'package:stars/utils/time.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:stars/ui/features/bots/view_models/bot_list_view_model.dart';
import 'package:stars/utils/utils.dart';
import 'package:stars/utils/theme.dart';

part 'bots_desktop_card.dart';
part 'bots_mobile_card.dart';

class ContactsPage extends StatefulWidget {
  final String? selectedBotId;
  final ValueChanged<Bot> onBotSelected;
  final ValueChanged<Bot>? onBotEditSelected;
  final void Function(String chatId, Bot bot)? onChatCreated;
  final VoidCallback? onSelectionCleared;
  final BotListViewModel viewModel;

  const ContactsPage({
    super.key,
    required this.viewModel,
    this.selectedBotId,
    required this.onBotSelected,
    this.onBotEditSelected,
    this.onChatCreated,
    this.onSelectionCleared,
  });

  @override
  State<ContactsPage> createState() => ContactsPageState();
}

class ContactsPageState extends State<ContactsPage> {
  final FocusNode _searchFocusNode = FocusNode();

  List<Bot> get contacts => widget.viewModel.bots;
  List<Bot> get filteredBots => widget.viewModel.filteredBots;
  String get searchQuery => widget.viewModel.query;
  bool get isLoading => widget.viewModel.isLoading;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void focusSearch() => _searchFocusNode.requestFocus();

  Future<void> openAddBotPage() => _openAddBotPage();

  // 过滤联系人列表
  void _filterBots(String query) => widget.viewModel.search(query);

  Future<void> _startChat(Bot bot) async {
    final chat = await widget.viewModel.startChat(bot);
    if (!mounted) return;

    if (isDesktopPlatform(context)) {
      widget.onChatCreated?.call(chat.id, bot);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ChatPage(id: chat.id, bot: bot),
      ),
    );
  }

  void _openBotDetails(Bot bot) {
    if (isDesktopPlatform(context)) {
      widget.onBotSelected(bot);
      return;
    }

    _pushBotPage(bot, readOnly: true);
  }

  void _editBot(Bot bot) {
    if (isDesktopPlatform(context)) {
      (widget.onBotEditSelected ?? widget.onBotSelected)(bot);
      return;
    }

    _pushBotPage(bot);
  }

  void _pushBotPage(Bot bot, {bool readOnly = false}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (context) => EditBotPage(
              bot: bot,
              readOnly: readOnly,
              avatarPicker: widget.viewModel.pickAvatar,
              onBotUpdated: (updatedBot) async {
                await widget.viewModel.updateBot(updatedBot);
              },
              onBotDeleted: () async {
                await widget.viewModel.deleteBot(bot.id);
              },
            ),
      ),
    );
  }

  Future<void> _deleteBot(Bot bot) async {
    final wasSelected = widget.selectedBotId == bot.id;
    final deletedIndex = contacts.indexWhere((item) => item.id == bot.id);
    final confirm = await showShadDialog<bool>(
      context: context,
      variant: ShadDialogVariant.alert,
      builder:
          (context) => ShadDialog.alert(
            title: Text(S.of(context).confirmDelete),
            description: Text(
              desktopConversationText(
                context,
                S.of(context).confirmDeleteBot(bot.name),
              ),
            ),
            actions: [
              ShadButton.outline(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).cancel),
              ),
              ShadButton.destructive(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).delete),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;
    try {
      await widget.viewModel.deleteBot(bot.id);
    } on Object {
      return;
    }
    if (!mounted) return;
    final remainingBots = contacts
        .where((item) => item.id != bot.id)
        .toList(growable: false);
    if (wasSelected) {
      if (remainingBots.isEmpty) {
        widget.onSelectionCleared?.call();
      } else {
        final adjacentIndex =
            deletedIndex.clamp(0, remainingBots.length - 1).toInt();
        widget.onBotSelected(remainingBots[adjacentIndex]);
      }
    }
  }

  Future<void> _exportBot(Bot bot) async {
    try {
      final result = await widget.viewModel.exportBot(
        bot,
        dialogTitle: S.of(context).exportBot,
      );
      if (!mounted || result != BotExportResult.saved) return;
      showStarsNotice(
        context,
        S.of(context).botExportSucceeded,
        description: S.of(context).botExportedWithoutSecrets,
        tone: StarsNoticeTone.success,
      );
    } on Object {
      // The shared inline error alert renders the product-safe failure.
    }
  }

  Future<void> _importBot() async {
    try {
      final importedBot = await widget.viewModel.importBot(
        dialogTitle: S.of(context).importBot,
      );
      if (!mounted || importedBot == null) return;
      showStarsNotice(
        context,
        S.of(context).botImportSucceeded,
        description: S.of(context).botImportedWithoutApiKey,
        tone: StarsNoticeTone.success,
        actionLabel: S.of(context).configureApiKey,
        onAction: () => _editBot(importedBot),
      );
    } on Object {
      // The shared inline error alert renders the product-safe failure.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final isDesktop = isDesktopPlatform(context);
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    final content = isLoading ? _buildLoadingState() : _buildBody(isDesktop);
    final failure =
        widget.viewModel.commandState.failure ?? widget.viewModel.error;
    final body = Column(
      children: [
        if (failure != null)
          StarsInlineErrorAlert(
            error: safeFailureMessage(context, failure),
            isDesktop: isDesktop,
            onDismiss: widget.viewModel.clearError,
            alertKey: const ValueKey<String>('bot-command-error'),
          ),
        Expanded(child: content),
      ],
    );

    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            S.of(context).Bots,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          scrolledUnderElevation: 0,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              key: const ValueKey<String>('mobile-import-bot'),
              tooltip: S.of(context).importBot,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                maximumSize: const Size.square(48),
              ),
              icon: Icon(
                LucideIcons.fileUp,
                semanticLabel: S.of(context).importBot,
              ),
              onPressed:
                  widget.viewModel.commandState.isSubmitting
                      ? null
                      : _importBot,
            ),
            IconButton(
              tooltip: S.of(context).addBot,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                maximumSize: const Size.square(48),
              ),
              icon: Icon(
                Icons.add_circle_rounded,
                semanticLabel: S.of(context).addBot,
              ),
              onPressed:
                  widget.viewModel.commandState.isSubmitting
                      ? null
                      : _openAddBotPage,
            ),
          ],
        ),
        body: body,
      );
    }

    return DesktopListPanel(
      title: '',
      description: '',
      searchHintText: S.of(context).searchBots,
      searchFocusNode: _searchFocusNode,
      onSearchChanged: _filterBots,
      contentMaxWidth: StarsDesktopThemeSpec.formContentMaxWidth,
      padding: StarsDesktopThemeSpec.formPagePadding,
      backgroundColor: StarsDesktopThemeSpec.workspaceSurface(context),
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadButton.outline(
            key: const ValueKey<String>('desktop-import-bot'),
            onPressed:
                widget.viewModel.commandState.isSubmitting ? null : _importBot,
            leading: const Icon(LucideIcons.fileUp, size: 16),
            child: Text(S.of(context).importBot),
          ),
          const SizedBox(width: 8),
          ShadButton(
            onPressed:
                widget.viewModel.commandState.isSubmitting
                    ? null
                    : _openAddBotPage,
            leading: const Icon(LucideIcons.plus, size: 16),
            child: Text(S.of(context).addBot),
          ),
        ],
      ),
      child: body,
    );
  }

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildBody(bool isDesktop) {
    if (filteredBots.isEmpty) {
      return _buildEmptyBotsView(isDesktop);
    }
    return _buildBotsList(isDesktop);
  }

  Widget _buildBotsList(bool isDesktop) {
    return isDesktop ? _buildDesktopGrid() : _buildMobileList();
  }

  Widget _buildDesktopGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 212,
          ),
          itemCount: filteredBots.length,
          itemBuilder: (context, index) {
            final bot = filteredBots[index];
            return _DesktopBotCard(
              bot: bot,
              metrics: widget.viewModel.metricsFor(bot.id),
              subtitle:
                  bot.model.isEmpty
                      ? bot.provider
                      : '${bot.provider} · ${bot.model}',
              onOpen: () => _openBotDetails(bot),
              onEdit: () => _editBot(bot),
              onStartChat: () => _startChat(bot),
              onExport: () => _exportBot(bot),
              onDelete: () => _deleteBot(bot),
            );
          },
        );
      },
    );
  }

  Widget _buildMobileList() {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filteredBots.length,
      separatorBuilder: (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final bot = filteredBots[index];
        return Slidable(
          key: Key(bot.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              CustomSlidableAction(
                onPressed: (context) async {
                  final chat = await widget.viewModel.startChat(bot);
                  if (!context.mounted) return;
                  if (isDesktopPlatform(context)) {
                    widget.onChatCreated?.call(chat.id, bot);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => ChatPage(id: chat.id, bot: bot),
                    ),
                  );
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Icon(Icons.chat_bubble_rounded, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (context) {
                  _editBot(bot);
                },
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: Icon(Icons.edit_square, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (_) => unawaited(_exportBot(bot)),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                child: const Icon(LucideIcons.download, size: 18),
              ),
              CustomSlidableAction(
                onPressed: (_) => _deleteBot(bot),
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                child: Icon(Icons.delete_rounded, size: 20),
              ),
            ],
          ),
          child: _BotListItem(
            bot: bot,
            metrics: widget.viewModel.metricsFor(bot.id),
            timestamp: formatTimestamp(context, bot.createTimestamp),
            subtitle:
                bot.model.isEmpty
                    ? bot.provider
                    : '${bot.provider} - ${bot.model}',
            isSelected: false,
            onTap: () => _openBotDetails(bot),
            fontSize: fontSize ?? 16,
          ),
        );
      },
    );
  }

  Widget _buildEmptyBotsView(bool isDesktop) {
    if (isDesktop) {
      return DesktopEmptyStateCard(
        icon:
            searchQuery.isNotEmpty ? Icons.search_off_rounded : desktopBotIcon,
        title:
            searchQuery.isNotEmpty
                ? S.of(context).noMatchingBots
                : S.of(context).noBotsAvailable,
        description:
            searchQuery.isNotEmpty
                ? S.of(context).tryDifferentSearch
                : S.of(context).clickToCreateBot,
        supportingText:
            searchQuery.isNotEmpty ? S.of(context).botSearchScope : null,
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/profile/no_bots_v2.png',
                width: 256,
                height: 256,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).noBotsAvailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).clickToCreateBot,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openAddBotPage,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(S.of(context).addBot),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddBotPage() async {
    if (isDesktopPlatform(context)) {
      final botId = 'bot_${DateTime.now().millisecondsSinceEpoch}';
      final skillViewModel = AppScope.of(
        context,
      ).createDraftBotSkillViewModel(botId);
      try {
        await showShadDialog<void>(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => AddBotDialog(
                botId: botId,
                skillViewModel: skillViewModel,
                modelLoader: widget.viewModel.listModels,
                avatarPicker: widget.viewModel.pickAvatar,
                onBotAdded: (newBot, skillBindings) async {
                  await widget.viewModel.addBot(
                    newBot,
                    skillBindings: skillBindings,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
        );
      } finally {
        skillViewModel.dispose();
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (context) => AddBotPage(
              modelLoader: widget.viewModel.listModels,
              avatarPicker: widget.viewModel.pickAvatar,
              onBotAdded: (newBot, _) async {
                await widget.viewModel.addBot(newBot);
              },
            ),
      ),
    );
  }
}
