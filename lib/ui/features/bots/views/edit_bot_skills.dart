part of 'edit_bot.dart';

extension _EditBotSkills on _EditAIBotPageState {
  Widget _buildTokenUsage() {
    final viewModel = _tokenUsageViewModel;
    if (viewModel?.isLoading ?? false) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final usage = viewModel?.usage ?? ModelTokenUsage.empty;
    if (!widget.embedded) {
      return TokenUsageIndicator(usage: usage, showBreakdown: true);
    }
    return BotTokenUsagePanel(
      usage: usage,
      conversationUsages: viewModel?.conversationUsages ?? const [],
      dailyBuckets: viewModel?.dailyBuckets ?? const [],
      visibleBuckets: viewModel?.visibleBuckets ?? const [],
      granularity: viewModel?.granularity ?? TokenUsageGranularity.day,
      selectedDay: viewModel?.selectedDay,
      onShowDaily: viewModel?.showDaily,
      onBucketSelected:
          viewModel == null ||
                  viewModel.granularity == TokenUsageGranularity.hour
              ? null
              : (bucket) => viewModel.selectDay(bucket.start),
    );
  }

  Widget _buildBotSkills() {
    final viewModel = _skillViewModel;
    final strings = S.of(context);
    if (viewModel?.isLoading ?? false) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (viewModel == null || viewModel.skills.isEmpty) {
      return Text(
        strings.noSkillsInstalledDescription,
        style:
            widget.embedded
                ? StarsDesktopThemeSpec.bodyStyle(
                  context,
                )?.copyWith(color: StarsDesktopThemeSpec.mutedText(context))
                : Theme.of(context).textTheme.bodyMedium,
      );
    }

    final addButton =
        widget.embedded
            ? ShadButton.outline(
              key: const ValueKey<String>('add-bot-skill'),
              size: ShadButtonSize.sm,
              width: 0,
              enabled: !widget.readOnly && viewModel.availableSkills.isNotEmpty,
              onPressed: widget.readOnly ? null : _showAddSkillDialog,
              leading: const Icon(LucideIcons.plus, size: 15),
              child: Text(strings.addSkill),
            )
            : OutlinedButton.icon(
              key: const ValueKey<String>('add-bot-skill'),
              onPressed:
                  widget.readOnly || viewModel.availableSkills.isEmpty
                      ? null
                      : _showAddSkillDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(strings.addSkill),
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                strings.botSkillsDescription,
                style:
                    widget.embedded
                        ? StarsDesktopThemeSpec.metaStyle(context)
                        : Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(width: 12),
              if (viewModel.availableSkills.isEmpty)
                Tooltip(message: strings.allSkillsAdded, child: addButton)
              else
                addButton,
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (viewModel.addedSkills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.noBotSkillsAdded,
                  style:
                      widget.embedded
                          ? ShadTheme.of(context).textTheme.small
                          : Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  strings.noBotSkillsAddedDescription,
                  style:
                      widget.embedded
                          ? StarsDesktopThemeSpec.metaStyle(context)
                          : Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else ...[
          for (
            var index = 0;
            index < viewModel.paginatedAddedSkills.length;
            index++
          ) ...[
            _buildBotSkillRow(viewModel.paginatedAddedSkills[index], viewModel),
            if (index != viewModel.paginatedAddedSkills.length - 1)
              if (widget.embedded)
                const ShadSeparator.horizontal()
              else
                const Divider(height: 1),
          ],
          if (viewModel.totalAddedPages > 1) ...[
            const SizedBox(height: 12),
            _buildSkillPagination(
              keyPrefix: 'bot-skills',
              currentPage: viewModel.currentAddedPage,
              totalPages: viewModel.totalAddedPages,
              hasPreviousPage: viewModel.hasPreviousAddedPage,
              hasNextPage: viewModel.hasNextAddedPage,
              onPreviousPage: viewModel.previousAddedPage,
              onNextPage: viewModel.nextAddedPage,
              embedded: widget.embedded,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBotSkillRow(SkillDescriptor skill, BotSkillViewModel viewModel) {
    final strings = S.of(context);
    final binding = viewModel.bindingFor(skill.id);
    final enabled = binding?.enabled ?? false;
    final switchWidget = Semantics(
      label: strings.autoActivation,
      toggled: enabled,
      enabled: !widget.readOnly,
      child:
          widget.embedded
              ? ShadSwitch(
                key: ValueKey<String>('bot-skill-toggle-${skill.id}'),
                value: enabled,
                enabled: !widget.readOnly,
                onChanged:
                    widget.readOnly
                        ? null
                        : (value) => _setSkillEnabled(skill.id, value),
              )
              : Switch(
                key: ValueKey<String>('bot-skill-toggle-${skill.id}'),
                value: enabled,
                onChanged:
                    widget.readOnly
                        ? null
                        : (value) => _setSkillEnabled(skill.id, value),
              ),
    );
    final removeButton =
        widget.embedded
            ? StarsDesktopIconAction(
              key: ValueKey<String>('remove-bot-skill-${skill.id}'),
              icon: LucideIcons.trash2,
              label: strings.removeSkill,
              iconSize: 16,
              enabled: !widget.readOnly,
              onPressed:
                  widget.readOnly ? null : () => _removeBotSkill(skill.id),
            )
            : IconButton(
              key: ValueKey<String>('remove-bot-skill-${skill.id}'),
              tooltip: strings.removeSkill,
              onPressed:
                  widget.readOnly ? null : () => _removeBotSkill(skill.id),
              icon: const Icon(Icons.delete_outline_rounded),
            );

    return Padding(
      key: ValueKey<String>('bot-skill-${skill.id}'),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style:
                          widget.embedded
                              ? ShadTheme.of(context).textTheme.small
                              : Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      skill.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          widget.embedded
                              ? StarsDesktopThemeSpec.metaStyle(context)
                              : Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              switchWidget,
              if (!widget.readOnly) ...[const SizedBox(width: 8), removeButton],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillPagination({
    required String keyPrefix,
    required int currentPage,
    required int totalPages,
    required bool hasPreviousPage,
    required bool hasNextPage,
    required VoidCallback onPreviousPage,
    required VoidCallback onNextPage,
    required bool embedded,
  }) {
    final localizations = MaterialLocalizations.of(context);
    final indicator = Text(
      '$currentPage / $totalPages',
      key: ValueKey<String>('$keyPrefix-page-indicator'),
    );
    if (!embedded) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: ValueKey<String>('$keyPrefix-previous-page'),
            tooltip: localizations.previousPageTooltip,
            onPressed: hasPreviousPage ? onPreviousPage : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 10),
          indicator,
          const SizedBox(width: 10),
          IconButton(
            key: ValueKey<String>('$keyPrefix-next-page'),
            tooltip: localizations.nextPageTooltip,
            onPressed: hasNextPage ? onNextPage : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StarsDesktopIconAction(
          key: ValueKey<String>('$keyPrefix-previous-page'),
          icon: LucideIcons.chevronLeft,
          label: localizations.previousPageTooltip,
          variant: ShadButtonVariant.outline,
          iconSize: 16,
          enabled: hasPreviousPage,
          onPressed: onPreviousPage,
        ),
        const SizedBox(width: 12),
        indicator,
        const SizedBox(width: 12),
        StarsDesktopIconAction(
          key: ValueKey<String>('$keyPrefix-next-page'),
          icon: LucideIcons.chevronRight,
          label: localizations.nextPageTooltip,
          variant: ShadButtonVariant.outline,
          iconSize: 16,
          enabled: hasNextPage,
          onPressed: onNextPage,
        ),
      ],
    );
  }

  Future<void> _showAddSkillDialog() async {
    if (widget.readOnly) return;
    final viewModel = _skillViewModel;
    if (viewModel == null || viewModel.availableSkills.isEmpty) return;
    _skillSearchController.clear();
    viewModel.clearAvailableSearch();
    viewModel.resetAvailablePage();
    if (widget.embedded) {
      try {
        await showShadDialog<void>(
          context: context,
          builder:
              (dialogContext) => StatefulBuilder(
                builder:
                    (dialogContext, setDialogState) => ShadDialog(
                      key: const ValueKey<String>('bot-add-skill-dialog'),
                      closeIcon: StarsDesktopIconAction(
                        key: const ValueKey<String>('bot-add-skill-close'),
                        icon: LucideIcons.x,
                        iconSize: 18,
                        label:
                            MaterialLocalizations.of(
                              dialogContext,
                            ).closeButtonTooltip,
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      closeIconPosition: ShadPosition.directional(
                        top: 12,
                        end: 8,
                        textDirection: Directionality.of(dialogContext),
                      ),
                      title: Text(S.of(context).addSkill),
                      description: Text(S.of(context).botSkillsDescription),
                      constraints: const BoxConstraints(maxWidth: 620),
                      actions: [
                        ShadButton.outline(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text(S.of(context).cancel),
                        ),
                      ],
                      child: _buildAvailableSkillPicker(
                        dialogContext,
                        viewModel,
                        embedded: true,
                        refresh: setDialogState,
                      ),
                    ),
              ),
        );
      } finally {
        viewModel.clearAvailableSearch();
      }
      return;
    }
    try {
      await showDialog<void>(
        context: context,
        builder:
            (dialogContext) => StatefulBuilder(
              builder:
                  (dialogContext, setDialogState) => AlertDialog(
                    title: Text(S.of(context).addSkill),
                    content: SizedBox(
                      width: 520,
                      child: _buildAvailableSkillPicker(
                        dialogContext,
                        viewModel,
                        embedded: false,
                        refresh: setDialogState,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(S.of(context).cancel),
                      ),
                    ],
                  ),
            ),
      );
    } finally {
      viewModel.clearAvailableSearch();
    }
  }

  Widget _buildAvailableSkillPicker(
    BuildContext dialogContext,
    BotSkillViewModel viewModel, {
    required bool embedded,
    required StateSetter refresh,
  }) {
    final strings = S.of(context);
    final skills = viewModel.paginatedAvailableSkills;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (embedded) ...[
            StarsSearchField(
              key: const ValueKey<String>('bot-skill-search-field'),
              hintText: strings.searchSkills,
              semanticLabel: strings.searchSkills,
              controller: _skillSearchController,
              autofocus: true,
              onChanged: (query) {
                viewModel.searchAvailableSkills(query);
                refresh(() {});
              },
              suffixIcon:
                  viewModel.availableQuery.isEmpty
                      ? null
                      : StarsDesktopIconAction(
                        key: const ValueKey<String>('clear-bot-skill-search'),
                        icon: LucideIcons.x,
                        label: strings.clearSearch,
                        onPressed: () {
                          _skillSearchController.clear();
                          viewModel.clearAvailableSearch();
                          refresh(() {});
                        },
                        iconSize: 16,
                      ),
            ),
            const SizedBox(height: 12),
          ],
          if (skills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                strings.noMatchingSkills,
                textAlign: TextAlign.center,
                style:
                    embedded
                        ? StarsDesktopThemeSpec.metaStyle(context)
                        : Theme.of(context).textTheme.bodySmall,
              ),
            ),
          for (var index = 0; index < skills.length; index++) ...[
            Padding(
              key: ValueKey<String>('available-bot-skill-${skills[index].id}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skills[index].name,
                          style:
                              embedded
                                  ? ShadTheme.of(context).textTheme.small
                                  : Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          skills[index].description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              embedded
                                  ? StarsDesktopThemeSpec.metaStyle(context)
                                  : Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (embedded)
                    ShadButton(
                      key: ValueKey<String>(
                        'add-bot-skill-${skills[index].id}',
                      ),
                      size: ShadButtonSize.sm,
                      width: 0,
                      onPressed:
                          () => _addBotSkillFromDialog(
                            dialogContext,
                            skills[index].id,
                          ),
                      leading: const Icon(LucideIcons.plus, size: 14),
                      child: Text(strings.addSkill),
                    )
                  else
                    FilledButton.tonalIcon(
                      key: ValueKey<String>(
                        'add-bot-skill-${skills[index].id}',
                      ),
                      onPressed:
                          () => _addBotSkillFromDialog(
                            dialogContext,
                            skills[index].id,
                          ),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: Text(strings.addSkill),
                    ),
                ],
              ),
            ),
            if (index != skills.length - 1)
              if (embedded)
                const ShadSeparator.horizontal()
              else
                const Divider(height: 1),
          ],
          if (viewModel.totalAvailablePages > 1) ...[
            const SizedBox(height: 12),
            _buildSkillPagination(
              keyPrefix: 'available-skills',
              currentPage: viewModel.currentAvailablePage,
              totalPages: viewModel.totalAvailablePages,
              hasPreviousPage: viewModel.hasPreviousAvailablePage,
              hasNextPage: viewModel.hasNextAvailablePage,
              onPreviousPage: () {
                viewModel.previousAvailablePage();
                refresh(() {});
              },
              onNextPage: () {
                viewModel.nextAvailablePage();
                refresh(() {});
              },
              embedded: embedded,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _setSkillEnabled(String skillId, bool enabled) async {
    if (widget.readOnly) return;
    try {
      await _skillViewModel?.setEnabled(skillId, enabled);
    } catch (error) {
      if (mounted) showStarsNotice(context, safeFailureMessage(context, error));
    }
  }

  Future<void> _addBotSkillFromDialog(
    BuildContext dialogContext,
    String skillId,
  ) async {
    if (widget.readOnly) return;
    try {
      await _skillViewModel?.addSkill(skillId);
      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    } catch (error) {
      if (mounted) showStarsNotice(context, safeFailureMessage(context, error));
    }
  }

  Future<void> _removeBotSkill(String skillId) async {
    if (widget.readOnly) return;
    try {
      await _skillViewModel?.removeSkill(skillId);
    } catch (error) {
      if (mounted) showStarsNotice(context, safeFailureMessage(context, error));
    }
  }

  Widget _buildFormSection(
    BuildContext context,
    String title,
    List<Widget> children, {
    Key? sectionKey,
  }) {
    if (!widget.embedded) {
      return buildSectionContainer(
        context,
        title,
        widget.readOnly && children.length > 1
            ? [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const Divider(height: 16),
              ],
            ]
            : children,
      );
    }
    final tokens = StarsDesktopTokens.of(context);
    return ShadCard(
      key: sectionKey,
      width: double.infinity,
      padding: const EdgeInsets.all(
        StarsDesktopThemeSpec.botFormSectionPadding,
      ),
      backgroundColor: tokens.raisedSurface,
      border: ShadBorder.all(
        color: tokens.separator,
        width: StarsDesktopThemeSpec.botFormSectionBorderWidth,
      ),
      columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(
        title,
        style: StarsDesktopThemeSpec.sectionTitleStyle(context)?.copyWith(
          fontSize: StarsDesktopThemeSpec.botFormSectionTitleFontSize,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: widget.readOnly ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index != children.length - 1)
                if (widget.readOnly) ...[
                  const SizedBox(height: 8),
                  const ShadSeparator.horizontal(
                    margin: StarsDesktopThemeSpec.settingsRowSeparatorMargin,
                  ),
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
