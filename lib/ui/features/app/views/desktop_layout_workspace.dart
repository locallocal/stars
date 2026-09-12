part of 'desktop_layout.dart';

// State mutations remain owned by the host State object in this library part.
// ignore_for_file: invalid_use_of_protected_member

extension _DesktopLayoutWorkspace on _DesktopLayoutState {
  Widget _buildSidebar(BuildContext context, {VoidCallback? onToggleSidebar}) {
    return DecoratedBox(
      decoration: StarsDesktopThemeSpec.sidebarDecoration(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: desktopAppIconBorderRadius(26),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 26,
                    height: 26,
                    cacheWidth: 52,
                    cacheHeight: 52,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Stars',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onToggleSidebar != null)
                  StarsDesktopIconAction(
                    label: S.of(context).hideSidebar,
                    onPressed: onToggleSidebar,
                    selected: true,
                    variant: ShadButtonVariant.ghost,
                    icon: LucideIcons.panelLeftClose,
                  ),
              ],
            ),
          ),
          Padding(
            key: const ValueKey<String>('desktop-primary-navigation'),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    size: ShadButtonSize.sm,
                    height: StarsDesktopThemeSpec.botFormFieldHeight,
                    mainAxisAlignment: MainAxisAlignment.start,
                    expands: true,
                    onPressed: widget.onCreateChat,
                    child: _SidebarButtonContent(
                      icon: desktopStartConversationIcon,
                      label: desktopConversationText(
                        context,
                        S.of(context).newChat,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _SidebarDestination(
                  label: S.of(context).Bots,
                  icon: desktopBotIcon,
                  selected: widget.currentIndex == 1,
                  onTap: () => _selectPage(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const ShadSeparator.horizontal(),
          Expanded(
            // The conversation list remains the stable navigation context.
            // Agents and settings are rendered in the workspace instead of
            // replacing the sidebar's lower section.
            child: StarsConversationClearScope(
              onClear: _requestClearChatFromSidebar,
              child: StarsConversationDirectoryScope(
                onShow: _showConversationDirectory,
                child: StarsConversationInformationScope(
                  onShow: _showConversationInfo,
                  child: widget.pages[0],
                ),
              ),
            ),
          ),
          const ShadSeparator.horizontal(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              8,
              8,
              8,
              StarsDesktopThemeSpec.sidebarFooterBottomInset,
            ),
            child: _AccountButton(
              selected: widget.currentIndex >= 2,
              useLucideIcon: widget.currentIndex == 0,
              onTap: () => _selectPage(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarOverlay(BuildContext context, double availableWidth) {
    final width = math.min(
      StarsDesktopThemeSpec.sidebarWidth,
      math.max(0.0, availableWidth - 48.0),
    );
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              button: true,
              label: MaterialLocalizations.of(context).closeButtonTooltip,
              child: GestureDetector(
                onTap: () => setState(() => _compactSidebarOpen = false),
                child: ColoredBox(
                  color: StarsDesktopTokens.of(
                    context,
                  ).scrim.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: width,
            child: Material(
              elevation: 8,
              shadowColor: StarsDesktopTokens.of(
                context,
              ).scrim.withValues(alpha: 0.22),
              color: StarsDesktopThemeSpec.sidebarSurface(context),
              child: _buildSidebar(context),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPage(int index) {
    widget.onPageChanged(index);
    if (_compactSidebarOpen) {
      setState(() => _compactSidebarOpen = false);
    }
  }

  Widget _buildWorkspace(BuildContext context) {
    final skillPage =
        widget.pages.length > 2 ? widget.pages[2] : const SizedBox.shrink();
    final mcpPage =
        widget.pages.length > 3 ? widget.pages[3] : const SizedBox.shrink();
    final profilePage =
        widget.pages.length > 4 ? widget.pages[4] : const SizedBox.shrink();
    return ColoredBox(
      color: StarsDesktopThemeSpec.workspaceSurface(context),
      child: IndexedStack(
        index: widget.currentIndex,
        children: [
          _buildChatWorkspace(context),
          widget.selectedBot == null
              ? widget.pages[1]
              : _buildBotDetail(context),
          skillPage,
          mcpPage,
          profilePage,
        ],
      ),
    );
  }

  Widget _buildChatWorkspace(BuildContext context) {
    final bot = widget.selectedChatBot;
    if (bot == null) {
      return _conversationDirectoryOpen
          ? _buildConversationDirectoryPage(context)
          : _buildChatDetail(context);
    }
    return IndexedStack(
      key: const ValueKey<String>('desktop-chat-view-switcher'),
      index: _chatWorkspacePane.index,
      children: [
        _buildChatDetail(context),
        _buildConversationInfoPage(context, bot),
        _buildConversationDirectoryPage(context),
      ],
    );
  }

  Widget _buildConversationDirectoryPage(BuildContext context) {
    final viewModel = _conversationDirectoryViewModel;
    if (viewModel == null) return const SizedBox.shrink();
    return ConversationDirectoryPage(
      viewModel: viewModel,
      actionViewModel: _conversationDirectoryActionViewModel,
    );
  }

  Widget _buildChatDetail(BuildContext context) {
    if (widget.selectedChatId != null && widget.selectedChatBot != null) {
      if (_chatPageKeyId != widget.selectedChatId) {
        _chatPageKeyId = widget.selectedChatId;
        _chatPageKey = GlobalKey<ChatPageState>(
          debugLabel: 'chat-${widget.selectedChatId}',
        );
      }
      return ChatPage(
        key: _chatPageKey,
        id: widget.selectedChatId!,
        bot: widget.selectedChatBot!,
        showReasoning: widget.showReasoning,
        showVerificationStatus: widget.showVerificationStatus,
        showExecutionStatus: widget.showExecutionStatus,
        strictGroundingMode: widget.strictGroundingMode,
      );
    }
    return DesktopEmptyStateCard(
      icon: desktopStartConversationIcon,
      title: desktopConversationText(context, S.of(context).chats),
      description: desktopConversationText(
        context,
        S.of(context).clickToStartChat,
      ),
      imageAsset: 'assets/icon/app_icon.png',
      imageBorderRadius: desktopAppIconBorderRadius(
        DesktopEmptyStateCard.imageSize,
      ),
    );
  }

  Widget _buildBotDetail(BuildContext context) {
    if (widget.selectedBot != null) {
      return EditBotPage(
        key: ValueKey<String>(
          '${widget.selectedBot!.id}-${widget.isEditingBot ? 'edit' : 'detail'}',
        ),
        bot: widget.selectedBot!,
        embedded: true,
        readOnly: !widget.isEditingBot,
        avatarPicker: widget.avatarPicker,
        onBotUpdated: widget.onBotUpdated,
        onBotDeleted: widget.onBotDeleted,
      );
    }
    return DesktopEmptyStateCard(
      icon: LucideIcons.sparkles,
      title: S.of(context).Bots,
      description: S.of(context).selectBot,
      imageAsset: 'assets/icon/app_icon.png',
    );
  }

  Widget _buildConversationInfoPage(BuildContext context, Bot bot) {
    return ColoredBox(
      key: const ValueKey<String>('desktop-conversation-information'),
      color: StarsDesktopThemeSpec.workspaceSurface(context),
      child: _buildConversationInfo(context, bot),
    );
  }

  Widget _buildConversationInfo(BuildContext context, Bot bot) {
    final selectedChatName = widget.selectedChatName?.trim();
    final conversationName =
        selectedChatName?.isNotEmpty == true ? selectedChatName! : bot.name;
    final generationViewModel =
        widget.selectedChatId != null && _dependencies != null
            ? _dependencies!.generationRegistry.viewModelFor(
              widget.selectedChatId!,
              bot,
            )
            : null;
    return ListView(
      key: const PageStorageKey<String>(
        'desktop-conversation-information-list',
      ),
      controller: _conversationInfoScrollController,
      padding: StarsDesktopThemeSpec.profilePagePadding,
      children: [
        Center(
          child: ConstrainedBox(
            key: const ValueKey<String>(
              'desktop-conversation-information-content',
            ),
            constraints: const BoxConstraints(
              maxWidth: StarsDesktopThemeSpec.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ConversationInformationHeader(bot: bot),
                const SizedBox(height: 32),
                StarsDesktopSectionCard(
                  key: const ValueKey<String>(
                    'desktop-conversation-basic-section',
                  ),
                  title: S.of(context).basicInformation,
                  leadingIcon: LucideIcons.info,
                  children: [
                    _ConversationInfoRow(
                      icon: LucideIcons.messageSquareText,
                      label: S.of(context).conversationName,
                      description: S.of(context).conversationNameDescription,
                      value: conversationName,
                    ),
                    _ConversationInfoRow(
                      icon: LucideIcons.bot,
                      label: S.of(context).botName,
                      description: S.of(context).conversationBotDescription,
                      value: bot.name,
                    ),
                    _ConversationInfoRow(
                      icon: LucideIcons.server,
                      label: S.of(context).provider,
                      description:
                          S.of(context).conversationProviderDescription,
                      value: bot.provider.isEmpty ? '—' : bot.provider,
                    ),
                    _ConversationInfoRow(
                      icon: LucideIcons.cpu,
                      label: S.of(context).model,
                      description: S.of(context).conversationModelDescription,
                      value: bot.model.isEmpty ? '—' : bot.model,
                    ),
                    ModelModalitiesView(
                      inputModalities:
                          generationViewModel?.capabilityProvider
                              .getInputModalites() ??
                          bot.configuredInputModalities ??
                          const [InputModality.text],
                      outputModalities:
                          generationViewModel?.capabilityProvider
                              .getOutputModalites() ??
                          bot.configuredOutputModalities ??
                          const [OutputModality.text],
                      keyPrefix: 'conversation-model-modalities',
                      inputDescription:
                          S.of(context).modelInputModalitiesDescription,
                      outputDescription:
                          S.of(context).modelOutputModalitiesDescription,
                    ),
                    if (generationViewModel != null)
                      _buildConversationModelControls(generationViewModel),
                  ],
                ),
                if (_tokenUsageViewModel != null) ...[
                  const SizedBox(height: 32),
                  StarsDesktopSectionCard(
                    key: const ValueKey<String>(
                      'desktop-conversation-token-usage-section',
                    ),
                    title: S.of(context).tokenUsage,
                    titleKey: const ValueKey<String>(
                      'token-usage-section-title',
                    ),
                    leadingIcon: LucideIcons.chartBar,
                    children: [
                      ConversationTokenUsagePanel(
                        viewModel: _tokenUsageViewModel!,
                        showSectionHeader: false,
                      ),
                    ],
                  ),
                ],
                if (_memoryViewModel != null) ...[
                  const SizedBox(height: 32),
                  StarsDesktopSectionCard(
                    key: const ValueKey<String>(
                      'desktop-conversation-memory-section',
                    ),
                    title: S.of(context).contextAndMemory,
                    titleKey: const ValueKey<String>(
                      'conversation-memory-section-title',
                    ),
                    leadingIcon: LucideIcons.brain,
                    children: [
                      ConversationMemoryPanel(
                        viewModel: _memoryViewModel!,
                        generationViewModel: _dependencies?.generationRegistry
                            .maybeViewModel(widget.selectedChatId),
                        showSectionHeader: false,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationModelControls(
    ChatGenerationViewModel generationViewModel,
  ) {
    final memoryViewModel = _memoryViewModel;
    if (memoryViewModel == null) {
      return ConversationModelControls(
        provider: generationViewModel.capabilityProvider,
        showReasoning: widget.showReasoning,
        showVerificationStatus: widget.showVerificationStatus,
        showExecutionStatus: widget.showExecutionStatus,
        strictGroundingMode: widget.strictGroundingMode,
        onShowReasoningChanged: widget.onShowReasoningChanged,
        onShowExecutionStatusChanged: widget.onShowExecutionStatusChanged,
        onShowVerificationStatusChanged: widget.onShowVerificationStatusChanged,
        onStrictGroundingModeChanged: widget.onStrictGroundingModeChanged,
        maxModelTurnsEnabled: false,
      );
    }
    return ListenableBuilder(
      listenable: memoryViewModel,
      builder:
          (context, child) => ConversationModelControls(
            provider: generationViewModel.capabilityProvider,
            showReasoning: widget.showReasoning,
            showVerificationStatus: widget.showVerificationStatus,
            showExecutionStatus: widget.showExecutionStatus,
            strictGroundingMode: widget.strictGroundingMode,
            onShowReasoningChanged: widget.onShowReasoningChanged,
            onShowExecutionStatusChanged: widget.onShowExecutionStatusChanged,
            onShowVerificationStatusChanged:
                widget.onShowVerificationStatusChanged,
            onStrictGroundingModeChanged: widget.onStrictGroundingModeChanged,
            maxModelTurns:
                memoryViewModel.state?.maxModelTurns ??
                ConversationMemoryState.defaultMaxModelTurns,
            maxModelTurnsEnabled: !memoryViewModel.loading,
            onMaxModelTurnsChanged: memoryViewModel.setMaxModelTurns,
          ),
    );
  }
}
