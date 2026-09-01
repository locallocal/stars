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
            child: widget.pages[0],
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
          _buildChatDetail(context),
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
        showExecutionStatus: widget.showExecutionStatus,
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

  Widget _buildInspectorOverlay(BuildContext context, double availableWidth) {
    final width =
        _inspectorWidth
            .clamp(
              StarsDesktopThemeSpec.inspectorMinWidth,
              math.min(
                StarsDesktopThemeSpec.inspectorMaxWidth,
                math.max(
                  StarsDesktopThemeSpec.inspectorMinWidth,
                  availableWidth - 24.0,
                ),
              ),
            )
            .toDouble();
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _inspectorOpen = false),
              child: ColoredBox(
                color: StarsDesktopTokens.of(
                  context,
                ).scrim.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            bottom: 8,
            width: width,
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              shadowColor: StarsDesktopTokens.of(
                context,
              ).scrim.withValues(alpha: 0.2),
              borderRadius: StarsDesktopThemeSpec.containerRadius,
              clipBehavior: Clip.antiAlias,
              child: _buildInspector(context, overlay: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspector(
    BuildContext context, {
    required bool overlay,
    bool showHeader = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final bot = _activeBot;
    final generationViewModel =
        widget.currentIndex == 0 &&
                widget.selectedChatId != null &&
                widget.selectedChatBot != null &&
                _dependencies != null
            ? _dependencies!.generationRegistry.viewModelFor(
              widget.selectedChatId!,
              widget.selectedChatBot!,
            )
            : null;
    final decoration =
        overlay && showHeader
            ? StarsDesktopThemeSpec.overlayInspectorDecoration(context)
            : showHeader
            ? StarsDesktopThemeSpec.inspectorDecoration(context)
            : const BoxDecoration();
    return Container(
      decoration: decoration,
      child: ListView(
        key: const PageStorageKey<String>('desktop-context-inspector'),
        controller: _inspectorScrollController,
        padding: contentPadding ?? const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context).botInformation,
                    style: StarsDesktopThemeSpec.sectionTitleStyle(context),
                  ),
                ),
                if (widget.currentIndex == 0)
                  StarsDesktopIconAction(
                    label: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => setState(() => _inspectorOpen = false),
                    icon: LucideIcons.x,
                  )
                else
                  _DesktopToolbarIconAction(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => setState(() => _inspectorOpen = false),
                    icon: const Icon(LucideIcons.x, size: 17),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          if (bot != null) ...[
            _InspectorRow(
              icon:
                  widget.currentIndex == 0
                      ? LucideIcons.bot
                      : LucideIcons.sparkles,
              label: S.of(context).name,
              value: bot.name,
            ),
            _InspectorRow(
              icon:
                  widget.currentIndex == 0
                      ? LucideIcons.server
                      : LucideIcons.server,
              label: S.of(context).provider,
              value: bot.provider.isEmpty ? '—' : bot.provider,
            ),
            _InspectorRow(
              icon:
                  widget.currentIndex == 0 ? LucideIcons.cpu : LucideIcons.cpu,
              label: S.of(context).model,
              value: bot.model.isEmpty ? '—' : bot.model,
            ),
            ModelModalitiesView(
              inputModalities:
                  generationViewModel?.capabilityProvider.getInputModalites() ??
                  bot.configuredInputModalities ??
                  const [InputModality.text],
              outputModalities:
                  generationViewModel?.capabilityProvider
                      .getOutputModalites() ??
                  bot.configuredOutputModalities ??
                  const [OutputModality.text],
              keyPrefix: 'conversation-model-modalities',
            ),
            if (generationViewModel != null)
              ConversationModelControls(
                provider: generationViewModel.capabilityProvider,
              ),
            if (widget.currentIndex == 0 && _tokenUsageViewModel != null)
              ConversationTokenUsagePanel(viewModel: _tokenUsageViewModel!),
            if (widget.currentIndex == 0 && _memoryViewModel != null)
              ConversationMemoryPanel(
                viewModel: _memoryViewModel!,
                generationViewModel: _dependencies?.generationRegistry
                    .maybeViewModel(widget.selectedChatId),
              ),
          ],
        ],
      ),
    );
  }
}
