import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData buildAppTheme({
  required Brightness brightness,
  required double fontSize,
}) {
  final isDark = brightness == Brightness.dark;
  final colorScheme =
      isDark
          ? const ColorScheme.dark(
            primary: Color(0xFF7CAEFF),
            onPrimary: Colors.white,
            surface: Color(0xFF0F1116),
            onSurface: Color(0xFFF5F7FB),
            secondary: Color(0xFF171B24),
            tertiary: Color(0xFF2A3140),
            error: Color(0xFFF47070),
          )
          : const ColorScheme.light(
            primary: Color(0xFF5B8DEF),
            onPrimary: Colors.white,
            surface: Color(0xFFF3F5F9),
            onSurface: Color(0xFF1C2333),
            secondary: Colors.white,
            tertiary: Color(0xFFE7EBF2),
            error: Color(0xFFD95C5C),
          );

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: TextTheme(
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: _desktopFontFallback,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSize.clamp(14, 16).toDouble(),
        height: 1.6,
        fontFamilyFallback: _desktopFontFallback,
      ),
      bodyMedium: TextStyle(
        fontSize: (fontSize - 2).clamp(13, 15).toDouble(),
        height: 1.55,
        fontFamilyFallback: _desktopFontFallback,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        height: 1.4,
        fontFamilyFallback: _desktopFontFallback,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontFamilyFallback: _desktopFontFallback,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(
          colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
    ),
  );
}

const List<String> _desktopFontFallback = [
  'Segoe UI',
  'Microsoft YaHei UI',
  'PingFang SC',
  'Noto Sans CJK SC',
  'sans-serif',
];

class DesktopThemeTokens {
  static const double sidebarWidth = 340;
  static const double listPanelWidth = 340;
  static const double profileRailWidth = 340;
  static const double inspectorWidth = 380;
  static const double menuBarHeight = 42;
  static const double shellGap = 0;
  static const double controlHeight = 40;
  static const double iconButtonSize = 36;
  static const double listItemMinHeight = 38;
  static const double panelRadiusValue = 0;
  static const double itemRadiusValue = 11;
  static const double workspaceRadiusValue = 0;
  static const double inputRadiusValue = 20;
  static const double statusRadiusValue = 11;
  static const EdgeInsets shellPadding = EdgeInsets.zero;
  static const EdgeInsets panelPadding = EdgeInsets.all(14);
  static const EdgeInsets workspacePadding = EdgeInsets.all(24);
  static const BorderRadius sidebarRadius = BorderRadius.all(
    Radius.circular(workspaceRadiusValue),
  );
  static const BorderRadius panelRadius = BorderRadius.all(
    Radius.circular(panelRadiusValue),
  );
  static const BorderRadius workspaceRadius = BorderRadius.all(
    Radius.circular(workspaceRadiusValue),
  );
  static const BorderRadius itemRadius = BorderRadius.all(
    Radius.circular(itemRadiusValue),
  );
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(inputRadiusValue),
  );
  static const BorderRadius statusRadius = BorderRadius.all(
    Radius.circular(statusRadiusValue),
  );
  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(9),
  );
  static const BorderRadius selectionRadius = BorderRadius.all(
    Radius.circular(11),
  );
  static const BorderRadius inspectorRadius = BorderRadius.all(
    Radius.circular(22),
  );

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color shellBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF11161D) : const Color(0xFFF2F5F9);

  static Color sidebarSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF151B23) : const Color(0xFFEFF3F8);

  static Color panelSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF171F2B) : Colors.white;

  static Color workspaceSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF12171E) : Colors.white;

  static Color secondarySurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B222C) : const Color(0xFFF6F7F9);

  static Color outline(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE4E7EB);

  static Color divider(BuildContext context) => outline(context);

  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color mutedText(BuildContext context) =>
      isDark(context) ? const Color(0xFF9BA4AF) : const Color(0xFF6F757D);

  static Color softText(BuildContext context) =>
      isDark(context) ? const Color(0xFF7F8995) : const Color(0xFF9AA0A8);

  static Color hoverFill(BuildContext context) =>
      isDark(context)
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFE9EDF2);

  static Color selectedFill(BuildContext context) =>
      isDark(context)
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
          : const Color(0xFFE2E7ED);

  static Color success(BuildContext context) =>
      isDark(context) ? const Color(0xFF5BB498) : const Color(0xFF2E7D67);

  static Color warning(BuildContext context) =>
      isDark(context) ? const Color(0xFFE4B869) : const Color(0xFFA66A00);

  static Color error(BuildContext context) =>
      isDark(context) ? const Color(0xFFF08A8A) : const Color(0xFFC44545);

  static TextStyle? pageTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: text(context),
      );

  static TextStyle? sectionTitleStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .titleMedium
      ?.copyWith(fontWeight: FontWeight.w600, color: text(context));

  static TextStyle? bodyStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: text(context), height: 1.5);

  static TextStyle? metaStyle(BuildContext context) => Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(color: mutedText(context), height: 1.45);

  static List<BoxShadow> panelShadow(BuildContext context) {
    if (isDark(context)) {
      return const [];
    }

    return const [
      BoxShadow(
        color: Color(0x120F172A),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ];
  }

  static BorderSide panelBorder(BuildContext context) =>
      BorderSide(color: outline(context));

  static BoxDecoration sidebarDecoration(BuildContext context) => BoxDecoration(
    color: sidebarSurface(context),
    border: Border(right: BorderSide(color: outline(context))),
  );

  static BoxDecoration panelDecoration(
    BuildContext context, {
    Color? color,
    BorderRadius borderRadius = panelRadius,
  }) => BoxDecoration(
    color: color ?? panelSurface(context),
    borderRadius: borderRadius,
    border: Border.all(color: outline(context)),
    boxShadow: panelShadow(context),
  );

  static BoxDecoration workspaceDecoration(BuildContext context) =>
      panelDecoration(
        context,
        color: workspaceSurface(context),
        borderRadius: workspaceRadius,
      );

  static BoxDecoration inspectorDecoration(BuildContext context) =>
      BoxDecoration(
        color: panelSurface(context),
        borderRadius: inspectorRadius,
        border: Border.all(color: outline(context)),
        boxShadow: panelShadow(context),
      );

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
    bool focused = false,
  }) {
    final color =
        selected
            ? selectedFill(context)
            : hovered
            ? hoverFill(context)
            : Colors.transparent;

    return BoxDecoration(
      color: color,
      borderRadius: itemRadius,
      border: Border.all(
        color:
            selected
                ? Colors.transparent
                : focused
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.42)
                : Colors.transparent,
      ),
      boxShadow: focused ? const [] : null,
    );
  }

  static InputDecoration searchDecoration(
    BuildContext context, {
    required String hintText,
  }) => InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: softText(context),
      fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
    ),
    prefixIcon: Icon(Icons.search, color: softText(context)),
    filled: true,
    fillColor: secondarySurface(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: controlRadius,
      borderSide: BorderSide(color: outline(context)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: controlRadius,
      borderSide: BorderSide(color: outline(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: controlRadius,
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
      ),
    ),
  );

  static ButtonStyle primaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(0, controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      );

  static ButtonStyle secondaryButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        minimumSize: const Size(0, controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        foregroundColor: text(context),
        backgroundColor: secondarySurface(context),
        side: BorderSide(color: outline(context)),
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      );

  static ButtonStyle iconButtonStyle(BuildContext context) =>
      IconButton.styleFrom(
        minimumSize: const Size(iconButtonSize, iconButtonSize),
        backgroundColor: secondarySurface(context),
        foregroundColor: mutedText(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class DesktopEmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? supportingText;
  final Widget? action;
  final String? imageAsset;

  const DesktopEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.supportingText,
    this.action,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = DesktopThemeTokens.sectionTitleStyle(
      context,
    )?.copyWith(fontWeight: FontWeight.w700);
    final bodyStyle = DesktopThemeTokens.bodyStyle(
      context,
    )?.copyWith(color: DesktopThemeTokens.mutedText(context));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: DesktopThemeTokens.panelDecoration(
            context,
            color:
                DesktopThemeTokens.isDark(context)
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFFDFEFF),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageAsset != null) ...[
                Image.asset(
                  imageAsset!,
                  width: 180,
                  height: 180,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: DesktopThemeTokens.selectedFill(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 34,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(title, textAlign: TextAlign.center, style: titleStyle),
              const SizedBox(height: 10),
              Text(description, textAlign: TextAlign.center, style: bodyStyle),
              if (supportingText != null) ...[
                const SizedBox(height: 8),
                Text(
                  supportingText!,
                  textAlign: TextAlign.center,
                  style: bodyStyle?.copyWith(
                    color: DesktopThemeTokens.softText(context),
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class DesktopListPanel extends StatelessWidget {
  final String title;
  final String description;
  final String searchHintText;
  final ValueChanged<String> onSearchChanged;
  final Widget action;
  final Widget child;

  const DesktopListPanel({
    super.key,
    required this.title,
    required this.description,
    required this.searchHintText,
    required this.onSearchChanged,
    required this.action,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DesktopThemeTokens.sidebarSurface(context),
      padding: DesktopThemeTokens.panelPadding,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DesktopThemeTokens.pageTitleStyle(
                        context,
                      )?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: DesktopThemeTokens.bodyStyle(
                        context,
                      )?.copyWith(color: DesktopThemeTokens.mutedText(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              action,
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: onSearchChanged,
            decoration: DesktopThemeTokens.searchDecoration(
              context,
              hintText: searchHintText,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class DesktopInteractiveListItem extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DesktopInteractiveListItem({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  State<DesktopInteractiveListItem> createState() =>
      _DesktopInteractiveListItemState();
}

class _DesktopInteractiveListItemState
    extends State<DesktopInteractiveListItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      constraints: const BoxConstraints(
        minHeight: DesktopThemeTokens.listItemMinHeight,
      ),
      decoration: DesktopThemeTokens.listItemDecoration(
        context,
        selected: widget.selected,
        hovered: _hovered,
        focused: _focused,
      ),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              widget.onTap();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) {
          if (_hovered == value) {
            return;
          }
          setState(() {
            _hovered = value;
          });
        },
        onShowFocusHighlight: (value) {
          if (_focused == value) {
            return;
          }
          setState(() {
            _focused = value;
          });
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: DesktopThemeTokens.itemRadius,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class BubbleDesktopTheme {
  static double get panelRadius => DesktopThemeTokens.panelRadiusValue;
  static double get cardRadius => DesktopThemeTokens.statusRadiusValue;
  static double get bubbleRadius => DesktopThemeTokens.itemRadiusValue;
  static double get workspacePadding =>
      DesktopThemeTokens.workspacePadding.left;
  static const double contentMaxWidth = 920;
  static const double messageBubbleMaxWidth = 552;
  static const double inputMaxWidth = 920;

  static Color workspaceBackground(BuildContext context) {
    return DesktopThemeTokens.workspaceSurface(context);
  }

  static Color panelBackground(BuildContext context) {
    return DesktopThemeTokens.panelSurface(context);
  }

  static Color elevatedSurface(BuildContext context) {
    return DesktopThemeTokens.secondarySurface(context);
  }

  static Color borderColor(BuildContext context) {
    return DesktopThemeTokens.outline(context);
  }

  static Color mutedText(BuildContext context) {
    return DesktopThemeTokens.mutedText(context);
  }

  static Color subtleText(BuildContext context) {
    return DesktopThemeTokens.softText(context);
  }

  static Color assistantBubble(BuildContext context) {
    return DesktopThemeTokens.secondarySurface(context);
  }

  static Color userBubble(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.24)
        : const Color(0xFFE9F1FF);
  }

  static Color statusCardBackground(BuildContext context) {
    return DesktopThemeTokens.secondarySurface(context);
  }

  static List<BoxShadow> panelShadow(BuildContext context) {
    return DesktopThemeTokens.panelShadow(context);
  }
}
