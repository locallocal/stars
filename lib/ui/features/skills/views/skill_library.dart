import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/bots/views/skill_description_test_dialog.dart';
import 'package:stars/ui/features/skills/view_models/skill_library_view_model.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

part 'skill_library_cards.dart';
part 'skill_library_details.dart';

class SkillLibraryPage extends StatefulWidget {
  const SkillLibraryPage({super.key, required this.viewModel});

  final SkillLibraryViewModel viewModel;

  @override
  State<SkillLibraryPage> createState() => _SkillLibraryPageState();
}

class _SkillLibraryPageState extends State<SkillLibraryPage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  SkillLibraryViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: viewModel.query);
  }

  @override
  void didUpdateWidget(covariant SkillLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != viewModel &&
        _searchController.text != viewModel.query) {
      _searchController.text = viewModel.query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    viewModel.clearSearch();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return isDesktopPlatform(context)
            ? _buildDesktop(context)
            : _buildMobile(context);
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final strings = S.of(context);
    return ColoredBox(
      color: StarsDesktopThemeSpec.workspaceSurface(context),
      child: SingleChildScrollView(
        key: ValueKey<String>('skill-library-page-${viewModel.currentPage}'),
        padding: StarsDesktopThemeSpec.formPagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: StarsDesktopThemeSpec.formContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.skillLibrary,
                            key: const ValueKey<String>('skill-library-title'),
                            style: StarsDesktopThemeSpec.pageTitleStyle(
                              context,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.skillLibraryDescription,
                            style: StarsDesktopThemeSpec.bodyStyle(
                              context,
                            )?.copyWith(
                              color: StarsDesktopThemeSpec.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (viewModel.hasConfiguredCatalogs)
                            ShadButton.outline(
                              key: const ValueKey<String>(
                                'refresh-skill-catalogs',
                              ),
                              enabled: !viewModel.isRefreshingCatalogs,
                              onPressed: () => _refreshCatalogs(context),
                              leading:
                                  viewModel.isRefreshingCatalogs
                                      ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        LucideIcons.refreshCw,
                                        size: 16,
                                      ),
                              child: Text(
                                viewModel.isRefreshingCatalogs
                                    ? strings.refreshingSkillCatalogs
                                    : strings.refreshSkillCatalogs,
                              ),
                            ),
                          ShadButton.outline(
                            key: const ValueKey<String>('import-skill-folder'),
                            enabled: !viewModel.isImporting,
                            onPressed: () => _importDirectory(context),
                            leading: const Icon(LucideIcons.folderUp, size: 16),
                            child: Text(strings.importSkillFolder),
                          ),
                          ShadButton(
                            key: const ValueKey<String>('import-skill-zip'),
                            enabled: !viewModel.isImporting,
                            onPressed: () => _importZip(context),
                            leading:
                                viewModel.isImporting
                                    ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      LucideIcons.fileArchive,
                                      size: 16,
                                    ),
                            child: Text(
                              viewModel.isImporting
                                  ? strings.importingSkill
                                  : strings.importSkillZip,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ShadAlert(
                  icon: Icon(
                    viewModel.sandboxStatus?.isAvailable == true
                        ? LucideIcons.shieldCheck
                        : LucideIcons.shieldAlert,
                  ),
                  title: Text(
                    viewModel.sandboxStatus?.isAvailable == true
                        ? strings.skillSandboxAvailable
                        : strings.skillSandboxUnavailable,
                  ),
                  description: Text(
                    viewModel.sandboxStatus?.isAvailable == true
                        ? strings.skillSandboxAvailableDescription
                        : strings.skillSandboxUnavailableDescription,
                  ),
                ),
                if (viewModel.error != null) ...[
                  const SizedBox(height: 16),
                  ShadAlert.destructive(
                    key: const ValueKey<String>('skill-error-alert'),
                    crossAxisAlignment: CrossAxisAlignment.center,
                    icon: const Icon(LucideIcons.circleAlert),
                    title: Text(
                      strings.skillImportFailed(
                        safeFailureMessage(context, viewModel.error!),
                      ),
                    ),
                    trailing: StarsDesktopIconAction(
                      key: const ValueKey<String>('close-skill-error'),
                      icon: LucideIcons.x,
                      label:
                          MaterialLocalizations.of(context).closeButtonTooltip,
                      onPressed: viewModel.clearError,
                      iconSize: 16,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildSearchField(context),
                const SizedBox(height: 24),
                if (viewModel.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: ShadProgress(),
                    ),
                  )
                else if (viewModel.skills.isEmpty)
                  _buildDesktopEmpty(context)
                else if (viewModel.filteredSkills.isEmpty)
                  _buildDesktopSearchEmpty(context)
                else
                  _buildDesktopSkills(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopEmpty(BuildContext context) {
    final strings = S.of(context);
    return DesktopEmptyStateCard(
      icon: LucideIcons.wrench,
      title: strings.noSkillsInstalled,
      description: strings.noSkillsInstalledDescription,
    );
  }

  Widget _buildDesktopSearchEmpty(BuildContext context) {
    final strings = S.of(context);
    return DesktopEmptyStateCard(
      icon: LucideIcons.search,
      title: strings.noMatchingSkills,
      description: strings.tryDifferentSearch,
      action: ShadButton(
        size: ShadButtonSize.sm,
        onPressed: _clearSearch,
        leading: const Icon(LucideIcons.x, size: 16),
        child: Text(strings.clearSearch),
      ),
    );
  }

  Widget _buildDesktopSkills(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800 ? 2 : 1;
        const gap = 14.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                mainAxisExtent: StarsDesktopThemeSpec.managementCardHeight,
              ),
              itemCount: viewModel.paginatedSkills.length,
              itemBuilder: (context, index) {
                final skill = viewModel.paginatedSkills[index];
                final update = _updateFor(skill);
                return _DesktopSkillCard(
                  skill: skill,
                  hasScriptTools: viewModel.hasScriptTools(skill.id),
                  scriptEnabled: viewModel.isScriptEnabled(skill.id),
                  update: update,
                  onOpen: () => _showDetails(context, skill),
                  onTest:
                      () =>
                          unawaited(_showSkillDescriptionTest(context, skill)),
                  onUninstall:
                      skill.scope == SkillScope.bundled
                          ? null
                          : () => _confirmUninstall(context, skill),
                  onToggleScripts: () => _confirmScriptToggle(context, skill),
                  onUpdate:
                      update == null
                          ? null
                          : () => _installUpdate(context, update),
                );
              },
            ),
            if (viewModel.totalPages > 1) ...[
              const SizedBox(height: 20),
              _buildPagination(context, desktop: true),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPagination(BuildContext context, {required bool desktop}) {
    final localizations = MaterialLocalizations.of(context);
    final pageIndicator = Semantics(
      label: '${viewModel.currentPage} / ${viewModel.totalPages}',
      child: Text(
        '${viewModel.currentPage} / ${viewModel.totalPages}',
        key: const ValueKey<String>('skill-page-indicator'),
      ),
    );
    if (!desktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const ValueKey<String>('skill-previous-page'),
            tooltip: localizations.previousPageTooltip,
            onPressed:
                viewModel.hasPreviousPage ? viewModel.previousPage : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 12),
          pageIndicator,
          const SizedBox(width: 12),
          IconButton(
            key: const ValueKey<String>('skill-next-page'),
            tooltip: localizations.nextPageTooltip,
            onPressed: viewModel.hasNextPage ? viewModel.nextPage : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShadButton.outline(
          key: const ValueKey<String>('skill-previous-page'),
          size: ShadButtonSize.sm,
          enabled: viewModel.hasPreviousPage,
          onPressed: viewModel.previousPage,
          leading: const Icon(LucideIcons.chevronLeft, size: 16),
          child: Text(localizations.previousPageTooltip),
        ),
        const SizedBox(width: 16),
        pageIndicator,
        const SizedBox(width: 16),
        ShadButton.outline(
          key: const ValueKey<String>('skill-next-page'),
          size: ShadButtonSize.sm,
          enabled: viewModel.hasNextPage,
          onPressed: viewModel.nextPage,
          trailing: const Icon(LucideIcons.chevronRight, size: 16),
          child: Text(localizations.nextPageTooltip),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context) {
    final strings = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.skillLibrary,
          key: const ValueKey<String>('skill-library-title'),
          style: const TextStyle(
            fontSize: StarsDesktopThemeSpec.pageTitleFontSize,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'folder') {
                _importDirectory(context);
              } else {
                _importZip(context);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'folder',
                    child: Text(strings.importSkillFolder),
                  ),
                  PopupMenuItem(
                    value: 'zip',
                    child: Text(strings.importSkillZip),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _buildSearchField(context),
          ),
          Expanded(child: _buildMobileBody(context)),
        ],
      ),
    );
  }

  Widget _buildMobileBody(BuildContext context) {
    final strings = S.of(context);
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.skills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_outlined, size: 40),
              const SizedBox(height: 12),
              Text(strings.noSkillsInstalled),
              const SizedBox(height: 6),
              Text(
                strings.noSkillsInstalledDescription,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (viewModel.filteredSkills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40),
              const SizedBox(height: 12),
              Text(strings.noMatchingSkills),
              const SizedBox(height: 6),
              Text(strings.tryDifferentSearch, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _clearSearch,
                child: Text(strings.clearSearch),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            key: ValueKey<String>(
              'skill-library-mobile-page-${viewModel.currentPage}',
            ),
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.paginatedSkills.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final skill = viewModel.paginatedSkills[index];
              return Card(
                child: ListTile(
                  title: Text(
                    skill.name,
                    style: const TextStyle(
                      fontSize: StarsDesktopThemeSpec.pageTitleFontSize,
                    ),
                  ),
                  subtitle: Text(
                    skill.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _showDetails(context, skill),
                  trailing: PopupMenuButton<_MobileSkillAction>(
                    key: ValueKey<String>(
                      'mobile-skill-menu-button-${skill.id}',
                    ),
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    onSelected: (action) {
                      switch (action) {
                        case _MobileSkillAction.test:
                          unawaited(_showSkillDescriptionTest(context, skill));
                        case _MobileSkillAction.uninstall:
                          unawaited(_confirmUninstall(context, skill));
                      }
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem<_MobileSkillAction>(
                            key: ValueKey<String>(
                              'mobile-skill-test-${skill.id}',
                            ),
                            value: _MobileSkillAction.test,
                            child: Row(
                              children: [
                                const Icon(Icons.science_outlined, size: 18),
                                const SizedBox(width: 10),
                                Text(strings.testSkill),
                              ],
                            ),
                          ),
                          if (skill.scope != SkillScope.bundled)
                            PopupMenuItem<_MobileSkillAction>(
                              key: ValueKey<String>(
                                'mobile-skill-uninstall-${skill.id}',
                              ),
                              value: _MobileSkillAction.uninstall,
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, size: 18),
                                  const SizedBox(width: 10),
                                  Text(strings.uninstall),
                                ],
                              ),
                            ),
                        ],
                  ),
                ),
              );
            },
          ),
        ),
        if (viewModel.totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPagination(context, desktop: false),
          ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final strings = S.of(context);
    final hasQuery = viewModel.query.isNotEmpty;
    return StarsSearchField(
      key: const ValueKey<String>('skill-search-field'),
      hintText: strings.searchSkills,
      semanticLabel: strings.searchSkills,
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: viewModel.search,
      suffixIcon:
          hasQuery
              ? StarsDesktopIconAction(
                key: const ValueKey<String>('clear-skill-search'),
                icon: LucideIcons.x,
                label: strings.clearSearch,
                onPressed: _clearSearch,
                iconSize: 16,
              )
              : null,
    );
  }

  Future<void> _importDirectory(BuildContext context) async {
    await _runImport(context, viewModel.importDirectory);
  }

  Future<void> _importZip(BuildContext context) async {
    await _runImport(context, viewModel.importZipArchive);
  }

  Future<void> _runImport(
    BuildContext context,
    Future<SkillDescriptor?> Function() action,
  ) async {
    try {
      final skill = await action();
      if (!context.mounted || skill == null) return;
      _showMessage(context, S.of(context).skillImportSucceeded);
    } catch (error) {
      if (!context.mounted) return;
      _showMessage(
        context,
        S.of(context).skillImportFailed(safeFailureMessage(context, error)),
      );
    }
  }

  OnlineSkillCatalogEntry? _updateFor(SkillDescriptor skill) {
    for (final entry in viewModel.availableUpdates) {
      if (entry.catalogId == skill.catalogId &&
          entry.id == skill.catalogEntryId) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _refreshCatalogs(BuildContext context) async {
    try {
      await viewModel.refreshCatalogs();
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, safeFailureMessage(context, error));
      }
    }
  }

  Future<void> _installUpdate(
    BuildContext context,
    OnlineSkillCatalogEntry update,
  ) async {
    try {
      await viewModel.installUpdate(update);
      if (context.mounted) {
        _showMessage(context, S.of(context).skillImportSucceeded);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, safeFailureMessage(context, error));
      }
    }
  }

  Future<void> _confirmScriptToggle(
    BuildContext context,
    SkillDescriptor skill,
  ) async {
    final strings = S.of(context);
    final enabled = viewModel.isScriptEnabled(skill.id);
    if (!enabled) {
      final confirmed = await showShadDialog<bool>(
        context: context,
        variant: ShadDialogVariant.alert,
        builder:
            (dialogContext) => ShadDialog.alert(
              title: Text(strings.enableSkillScriptsTitle),
              description: Text(
                strings.enableSkillScriptsDescription(skill.name),
              ),
              actions: [
                ShadButton.outline(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(strings.cancel),
                ),
                ShadButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(strings.enableSkillScripts),
                ),
              ],
            ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    try {
      await viewModel.setScriptEnabled(skill, !enabled);
      if (context.mounted) {
        _showMessage(context, strings.skillScriptSettingUpdated);
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, safeFailureMessage(context, error));
      }
    }
  }

  Future<void> _showSkillDescriptionTest(
    BuildContext context,
    SkillDescriptor skill,
  ) async {
    try {
      final bots = await viewModel.loadTestBots();
      if (!context.mounted) return;
      if (bots.isEmpty) {
        _showMessage(context, S.of(context).noBotsAvailable);
        return;
      }
      final bot =
          bots.length == 1
              ? bots.single
              : await _selectSkillTestBot(context, bots);
      if (bot == null || !context.mounted) return;
      final testCase = await showSkillDescriptionTestDialog(
        context: context,
        skill: skill,
        desktopMode: isDesktopPlatform(context),
      );
      if (testCase == null || !context.mounted) return;
      final report = await viewModel.testDescription(
        bot: bot,
        skill: skill,
        cases: [testCase],
      );
      if (!context.mounted) return;
      final result = report.results.single;
      showStarsNotice(
        context,
        '${S.of(context).skillDescriptionTestResult}: '
        '${result.activations}/${result.runs}',
      );
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, safeFailureMessage(context, error));
      }
    }
  }

  Future<Bot?> _selectSkillTestBot(BuildContext context, List<Bot> bots) {
    final strings = S.of(context);
    if (!isDesktopPlatform(context)) {
      return showDialog<Bot>(
        context: context,
        builder:
            (dialogContext) => SimpleDialog(
              key: const ValueKey<String>('skill-test-bot-dialog'),
              title: Text(strings.selectBot),
              children: [
                for (final bot in bots)
                  SimpleDialogOption(
                    key: ValueKey<String>('skill-test-bot-${bot.id}'),
                    onPressed: () => Navigator.pop(dialogContext, bot),
                    child: Text(bot.name),
                  ),
              ],
            ),
      );
    }
    return showShadDialog<Bot>(
      context: context,
      builder:
          (dialogContext) => ShadDialog(
            key: const ValueKey<String>('skill-test-bot-dialog'),
            title: Text(strings.selectBot),
            description: Text(strings.autoActivationDescription),
            constraints: const BoxConstraints(maxWidth: 480),
            actions: [
              ShadButton.outline(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.cancel),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final bot in bots)
                        ShadButton.ghost(
                          key: ValueKey<String>('skill-test-bot-${bot.id}'),
                          expands: true,
                          mainAxisAlignment: MainAxisAlignment.start,
                          leading: const Icon(LucideIcons.bot, size: 16),
                          onPressed: () => Navigator.pop(dialogContext, bot),
                          child: Text(bot.name),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _showDetails(BuildContext context, SkillDescriptor skill) async {
    try {
      final content = await viewModel.loadContent(skill.id);
      if (!context.mounted) return;
      if (isDesktopPlatform(context)) {
        await showShadDialog<void>(
          context: context,
          builder:
              (dialogContext) => _SkillDetailsDialog(
                content: content,
                onUpdatePolicyChanged:
                    (policy) => viewModel.setUpdatePolicy(skill, policy),
                onCopyStorageLocation:
                    () => _copyStorageLocation(
                      dialogContext,
                      content.descriptor.rootPath,
                    ),
              ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(
                  skill.name,
                  key: ValueKey<String>('skill-details-title-${skill.id}'),
                  style: const TextStyle(
                    fontSize: StarsDesktopThemeSpec.pageTitleFontSize,
                  ),
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkillStorageLocationDetail(
                          location: content.descriptor.rootPath,
                          onCopy:
                              () => _copyStorageLocation(
                                dialogContext,
                                content.descriptor.rootPath,
                              ),
                        ),
                        _SkillFilesDetail(files: content.files),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        SelectableText(content.instructions),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ),
                ],
              ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, safeFailureMessage(context, error));
      }
    }
  }

  Future<void> _copyStorageLocation(
    BuildContext context,
    String location,
  ) async {
    await Clipboard.setData(ClipboardData(text: location));
    if (!context.mounted) return;
    _showMessage(context, S.of(context).skillStorageLocationCopied);
  }

  Future<void> _confirmUninstall(
    BuildContext context,
    SkillDescriptor skill,
  ) async {
    if (skill.scope == SkillScope.bundled) return;
    final strings = S.of(context);
    final confirmed =
        isDesktopPlatform(context)
            ? await showShadDialog<bool>(
              context: context,
              variant: ShadDialogVariant.alert,
              builder:
                  (dialogContext) => ShadDialog.alert(
                    title: Text(strings.uninstallSkill),
                    description: Text(
                      strings.confirmUninstallSkill(skill.name),
                    ),
                    actions: [
                      ShadButton.outline(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(strings.cancel),
                      ),
                      ShadButton.destructive(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(strings.uninstallSkill),
                      ),
                    ],
                  ),
            )
            : await showDialog<bool>(
              context: context,
              builder:
                  (dialogContext) => AlertDialog(
                    title: Text(strings.uninstallSkill),
                    content: Text(strings.confirmUninstallSkill(skill.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(strings.cancel),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(strings.uninstallSkill),
                      ),
                    ],
                  ),
            );
    if (confirmed != true) return;
    try {
      await viewModel.uninstall(skill.id);
    } catch (error) {
      if (context.mounted) {
        _showMessage(context, safeFailureMessage(context, error));
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    showStarsNotice(context, message, tone: StarsNoticeTone.error);
  }
}

enum _MobileSkillAction { test, uninstall }
