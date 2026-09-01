part of 'theme.dart';

class StarsDesktopThemeSpec {
  /// Stable layout and shape metrics for the desktop component system.
  ///
  /// Colors and accessibility state intentionally live only in
  /// [StarsDesktopTokens], the app's desktop [ThemeExtension].
  static const double sidebarWidth = 300;
  static const double sidebarMinWidth = 240;
  static const double sidebarMaxWidth = 360;
  static const double listPanelWidth = 300;
  static const double profileRailWidth = 300;
  static const double inspectorWidth = 360;
  static const double inspectorMinWidth = 280;
  static const double inspectorMaxWidth = 420;
  static const double detailMinWidth = 560;
  static const double toolbarHeight = 50;
  static const double menuBarHeight = toolbarHeight;
  static const double shellGap = 0;
  static const double controlHeight = 32;
  static const double iconButtonSize = 32;
  static const double listItemMinHeight = 44;
  static const double contentMaxWidth = 920;
  static const double messageBubbleMaxWidth = 552;
  static const double formContentMaxWidth = contentMaxWidth;
  static const double addBotFormFieldWidth = 640;
  static const double botFormFieldHeight = 48;
  static const EdgeInsets formFieldPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 1,
  );
  static const double botFormSectionPadding = 20;
  static const double botFormSectionBorderWidth = 1;
  static const double botFormSectionTitleFontSize = 16;
  static const double pageTitleFontSize = 17;
  static const double managementCardHeight = 220;
  static const EdgeInsets settingsRowPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 10,
  );
  static const double settingsRowMinHeight = 38;
  static const double settingsRowIconSlotWidth = 24;
  static const double settingsRowIconSize = 18;
  static const double settingsRowIconGap = 8;
  static const double settingsRowValueGap = 16;
  static const double settingsRowValueMaxWidth = 220;
  static const EdgeInsetsDirectional settingsRowSeparatorMargin =
      EdgeInsetsDirectional.only(start: 40);
  static const EdgeInsets formPagePadding = EdgeInsets.fromLTRB(32, 28, 32, 48);
  static const double sidebarFooterBottomInset = 18;
  static const EdgeInsets profilePagePadding = EdgeInsets.fromLTRB(
    32,
    28,
    32,
    sidebarFooterBottomInset,
  );
  static const double panelRadiusValue = 8;
  static const double itemRadiusValue = 6;
  static const double workspaceRadiusValue = 0;
  static const double inputRadiusValue = 6;
  static const double statusRadiusValue = 8;
  static const double bubbleRadiusValue = 8;
  static const double splitterHitWidth = 6;
  static const EdgeInsets shellPadding = EdgeInsets.zero;
  static const EdgeInsets panelPadding = EdgeInsets.all(12);
  static const EdgeInsets workspacePadding = EdgeInsets.all(24);
  static const BorderRadius sidebarRadius = BorderRadius.zero;
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius workspaceRadius = BorderRadius.zero;
  static const BorderRadius itemRadius = BorderRadius.all(Radius.circular(6));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(6));
  static const BorderRadius statusRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius bubbleRadius = BorderRadius.all(Radius.circular(8));
  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(6),
  );
  static const BorderRadius selectionRadius = BorderRadius.all(
    Radius.circular(6),
  );
  static const BorderRadius containerRadius = BorderRadius.all(
    Radius.circular(8),
  );
  static const BorderRadius inspectorRadius = containerRadius;

  static StarsDesktopTokens tokens(BuildContext context) =>
      StarsDesktopTokens.of(context);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color shellBackground(BuildContext context) =>
      tokens(context).windowBackground;

  static Color sidebarSurface(BuildContext context) =>
      tokens(context).sidebarOpaque;

  static Color panelSurface(BuildContext context) =>
      tokens(context).contentBackground;

  static Color workspaceSurface(BuildContext context) =>
      tokens(context).contentBackground;

  static Color secondarySurface(BuildContext context) =>
      tokens(context).controlFill;

  static Color raisedSurface(BuildContext context) =>
      tokens(context).raisedSurface;

  static Color toolbarSurface(BuildContext context) =>
      tokens(context).raisedSurface;

  static Color controlFill(BuildContext context) => tokens(context).controlFill;

  static Color outline(BuildContext context) => tokens(context).separator;

  static Color divider(BuildContext context) => tokens(context).separator;

  static Color text(BuildContext context) => tokens(context).primaryText;

  static Color mutedText(BuildContext context) => tokens(context).secondaryText;

  static Color softText(BuildContext context) => tokens(context).tertiaryText;

  static Color hoverFill(BuildContext context) => tokens(context).hoverFill;

  static Color pressedFill(BuildContext context) => tokens(context).pressedFill;

  static Color selectedFill(BuildContext context) =>
      tokens(context).selectedFill;

  /// Shared color for primary actions and active navigation backgrounds.
  ///
  /// Desktop primary buttons are rendered by Shad, while a few compatibility
  /// widgets still read Material's color scheme. Prefer the Shad value when it
  /// is available so both surfaces resolve to the send button's background.
  static Color primaryActionColor(BuildContext context) =>
      ShadTheme.maybeOf(context)?.colorScheme.primary ??
      Theme.of(context).colorScheme.primary;

  /// Visual background of a disabled desktop primary [ShadButton].
  ///
  /// Shad renders disabled buttons at 50% opacity. Active navigation buttons
  /// use this semi-transparent color directly because they remain interactive.
  static Color inactivePrimaryActionColor(BuildContext context) =>
      primaryActionColor(context).withValues(alpha: 0.5);

  static Color success(BuildContext context) => tokens(context).success;

  static Color warning(BuildContext context) => tokens(context).warning;

  static Color error(BuildContext context) => tokens(context).danger;

  static TextStyle? pageTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: pageTitleFontSize,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: text(context),
      );

  static TextStyle? toolbarTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: text(context),
      );

  static TextStyle? sectionTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: text(context),
      );

  static TextStyle? bodyStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: text(context), height: 1.45);

  static TextStyle? metaStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(color: mutedText(context), height: 1.4);

  /// Structural and content panels do not cast shadows.
  static List<BoxShadow> panelShadow(BuildContext context) => const [];

  static List<BoxShadow> floatingShadow(
    BuildContext context, {
    bool subtle = false,
  }) => floatingShadowFor(tokens(context), subtle: subtle);

  static List<BoxShadow> floatingShadowFor(
    StarsDesktopTokens tokens, {
    bool subtle = false,
  }) {
    if (tokens.highContrast) {
      return const [];
    }
    final dark = tokens.windowBackground.computeLuminance() < 0.2;
    return [
      BoxShadow(
        color:
            dark
                ? const Color(0x52000000)
                : Color(subtle ? 0x1A000000 : 0x24000000),
        blurRadius: subtle ? 12 : 24,
        offset: Offset(0, subtle ? 4 : 8),
      ),
    ];
  }

  static BorderSide panelBorder(BuildContext context) =>
      BorderSide(color: outline(context));

  static BoxDecoration sidebarDecoration(BuildContext context) =>
      BoxDecoration(color: sidebarSurface(context));

  static BoxDecoration panelDecoration(
    BuildContext context, {
    Color? color,
    BorderRadius borderRadius = panelRadius,
  }) => BoxDecoration(
    color: color ?? panelSurface(context),
    borderRadius: borderRadius,
    border: Border.all(color: outline(context)),
  );

  static BoxDecoration workspaceDecoration(BuildContext context) =>
      BoxDecoration(color: workspaceSurface(context));

  /// The compatibility inspector decoration is the docked, structural form.
  /// Overlay inspectors should use [StarsGlassSurface].
  static BoxDecoration inspectorDecoration(BuildContext context) =>
      BoxDecoration(
        color: panelSurface(context),
        border: Border(left: BorderSide(color: outline(context))),
      );

  static BoxDecoration overlayInspectorDecoration(BuildContext context) {
    final semanticTokens = tokens(context);
    return BoxDecoration(
      color: semanticTokens.raisedSurface,
      borderRadius: inspectorRadius,
      border: Border.all(color: semanticTokens.separator),
      boxShadow: floatingShadow(context),
    );
  }

  static BoxDecoration statusDecoration(BuildContext context, {Color? color}) =>
      BoxDecoration(
        color: color ?? secondarySurface(context),
        borderRadius: statusRadius,
        border: Border.all(color: outline(context)),
      );

  static BoxDecoration listItemDecoration(
    BuildContext context, {
    required bool selected,
    required bool hovered,
    bool pressed = false,
    bool focused = false,
  }) {
    final semanticTokens = tokens(context);
    final color =
        pressed
            ? semanticTokens.pressedFill
            : selected
            ? semanticTokens.selectedFill
            : hovered
            ? semanticTokens.hoverFill
            : Colors.transparent;

    return BoxDecoration(
      color: color,
      borderRadius: itemRadius,
      border: Border.all(
        color: focused ? semanticTokens.focusRing : Colors.transparent,
        width: focused ? (semanticTokens.highContrast ? 2 : 1.5) : 0,
      ),
    );
  }

  static InputDecoration searchDecoration(
    BuildContext context, {
    required String hintText,
    Widget? suffixIcon,
  }) {
    final semanticTokens = tokens(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: semanticTokens.tertiaryText,
        fontSize: 13,
        height: 1.35,
      ),
      prefixIcon: Icon(
        Icons.search_rounded,
        size: 16,
        color: semanticTokens.secondaryText,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      filled: true,
      fillColor: semanticTokens.raisedSurface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      border: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: semanticTokens.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(
          color: semanticTokens.focusRing,
          width: semanticTokens.highContrast ? 2 : 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(
          color: semanticTokens.separator.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
    );
  }

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    final semanticTokens = tokens(context);
    return ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: Colors.transparent,
      backgroundColor: semanticTokens.accent,
      foregroundColor:
          semanticTokens.accent.computeLuminance() > 0.5
              ? const Color(0xFF18181B)
              : const Color(0xFFFAFAFA),
      disabledBackgroundColor: semanticTokens.controlFill,
      disabledForegroundColor: semanticTokens.tertiaryText,
      minimumSize: const Size(0, controlHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: const RoundedRectangleBorder(borderRadius: controlRadius),
    );
  }

  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    final semanticTokens = tokens(context);
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, controlHeight),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      foregroundColor: semanticTokens.primaryText,
      disabledForegroundColor: semanticTokens.tertiaryText,
      backgroundColor: semanticTokens.controlFill,
      side: BorderSide(color: semanticTokens.separator),
      shape: const RoundedRectangleBorder(borderRadius: controlRadius),
    );
  }

  static ButtonStyle iconButtonStyle(BuildContext context) {
    final semanticTokens = tokens(context);
    return IconButton.styleFrom(
      minimumSize: const Size(iconButtonSize, iconButtonSize),
      maximumSize: const Size(iconButtonSize, iconButtonSize),
      backgroundColor: semanticTokens.controlFill,
      foregroundColor: semanticTokens.secondaryText,
      disabledForegroundColor: semanticTokens.tertiaryText,
      shape: const RoundedRectangleBorder(borderRadius: controlRadius),
    );
  }
}
