import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Semantic desktop colors and accessibility state for Stars.
///
/// The fallback palette mirrors the shadcn Zinc scheme. Keeping these semantic
/// names lets legacy Material-only widgets share the same desktop appearance.
@immutable
class StarsDesktopTokens extends ThemeExtension<StarsDesktopTokens> {
  const StarsDesktopTokens({
    required this.windowBackground,
    required this.contentBackground,
    required this.sidebarOpaque,
    required this.raisedSurface,
    required this.controlFill,
    required this.hoverFill,
    required this.pressedFill,
    required this.selectedFill,
    required this.separator,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.accent,
    required this.focusRing,
    required this.success,
    required this.warning,
    required this.danger,
    required this.reduceTransparency,
    required this.highContrast,
  });

  factory StarsDesktopTokens.light({
    bool reduceTransparency = false,
    bool highContrast = false,
  }) {
    return StarsDesktopTokens(
      windowBackground: const Color(0xFFFFFFFF),
      contentBackground: const Color(0xFFFFFFFF),
      sidebarOpaque: const Color(0xFFFAFAFA),
      raisedSurface: const Color(0xFFFFFFFF),
      controlFill: const Color(0xFFF4F4F5),
      hoverFill: const Color(0xFFF4F4F5),
      pressedFill: const Color(0xFFE4E4E7),
      selectedFill:
          highContrast ? const Color(0xFFE4E4E7) : const Color(0xFFF4F4F5),
      separator:
          highContrast ? const Color(0xFFA1A1AA) : const Color(0xFFE4E4E7),
      primaryText: const Color(0xFF09090B),
      secondaryText: const Color(0xFF71717A),
      tertiaryText: const Color(0xFFA1A1AA),
      accent: const Color(0xFF18181B),
      focusRing:
          highContrast ? const Color(0xFF09090B) : const Color(0xFF18181B),
      success: const Color(0xFF16A34A),
      warning: const Color(0xFFD97706),
      danger: const Color(0xFFEF4444),
      reduceTransparency: reduceTransparency,
      highContrast: highContrast,
    );
  }

  factory StarsDesktopTokens.dark({
    bool reduceTransparency = false,
    bool highContrast = false,
  }) {
    return StarsDesktopTokens(
      windowBackground: const Color(0xFF09090B),
      contentBackground: const Color(0xFF09090B),
      sidebarOpaque: const Color(0xFF18181B),
      raisedSurface: const Color(0xFF18181B),
      controlFill: const Color(0xFF27272A),
      hoverFill: const Color(0xFF27272A),
      pressedFill: const Color(0xFF3F3F46),
      selectedFill:
          highContrast ? const Color(0xFF3F3F46) : const Color(0xFF27272A),
      separator:
          highContrast ? const Color(0xFF71717A) : const Color(0xFF27272A),
      primaryText: const Color(0xFFFAFAFA),
      secondaryText: const Color(0xFFA1A1AA),
      tertiaryText: const Color(0xFF71717A),
      accent: const Color(0xFFFAFAFA),
      focusRing:
          highContrast ? const Color(0xFFFAFAFA) : const Color(0xFFD4D4D8),
      success: const Color(0xFF22C55E),
      warning: const Color(0xFFF59E0B),
      danger: const Color(0xFFEF4444),
      reduceTransparency: reduceTransparency,
      highContrast: highContrast,
    );
  }

  final Color windowBackground;
  final Color contentBackground;
  final Color sidebarOpaque;
  final Color raisedSurface;
  final Color controlFill;
  final Color hoverFill;
  final Color pressedFill;
  final Color selectedFill;
  final Color separator;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color accent;
  final Color focusRing;
  final Color success;
  final Color warning;
  final Color danger;
  final bool reduceTransparency;
  final bool highContrast;

  static StarsDesktopTokens of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final extension = Theme.of(context).extension<StarsDesktopTokens>();
    final shadTheme = ShadTheme.maybeOf(context);
    var tokens =
        shadTheme == null
            ? extension ??
                (brightness == Brightness.dark
                    ? StarsDesktopTokens.dark()
                    : StarsDesktopTokens.light())
            : StarsDesktopTokens.fromShad(
              shadTheme,
              reduceTransparency: extension?.reduceTransparency ?? false,
              highContrast: extension?.highContrast ?? false,
            );
    final mediaHighContrast =
        MediaQuery.maybeOf(context)?.highContrast ?? false;
    if (mediaHighContrast && !tokens.highContrast) {
      tokens = tokens._withHighContrast(brightness);
    }
    return tokens;
  }

  StarsDesktopTokens _withHighContrast(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return copyWith(
      highContrast: true,
      selectedFill: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
      separator: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
      focusRing: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF09090B),
    );
  }

  factory StarsDesktopTokens.fromShad(
    ShadThemeData theme, {
    bool reduceTransparency = false,
    bool highContrast = false,
  }) {
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tokens = StarsDesktopTokens(
      windowBackground: colors.background,
      contentBackground: colors.background,
      sidebarOpaque: isDark ? const Color(0xFF18181B) : const Color(0xFFFAFAFA),
      raisedSurface: colors.card,
      controlFill: colors.secondary,
      hoverFill: colors.accent,
      pressedFill: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
      selectedFill: colors.accent,
      separator: colors.border,
      primaryText: colors.foreground,
      secondaryText: colors.mutedForeground,
      tertiaryText: colors.mutedForeground.withValues(alpha: 0.72),
      accent: colors.primary,
      focusRing: colors.ring,
      success: isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
      warning: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
      danger: colors.destructive,
      reduceTransparency: reduceTransparency,
      highContrast: highContrast,
    );
    return highContrast ? tokens._withHighContrast(theme.brightness) : tokens;
  }

  @override
  StarsDesktopTokens copyWith({
    Color? windowBackground,
    Color? contentBackground,
    Color? sidebarOpaque,
    Color? raisedSurface,
    Color? controlFill,
    Color? hoverFill,
    Color? pressedFill,
    Color? selectedFill,
    Color? separator,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? accent,
    Color? focusRing,
    Color? success,
    Color? warning,
    Color? danger,
    bool? reduceTransparency,
    bool? highContrast,
  }) {
    return StarsDesktopTokens(
      windowBackground: windowBackground ?? this.windowBackground,
      contentBackground: contentBackground ?? this.contentBackground,
      sidebarOpaque: sidebarOpaque ?? this.sidebarOpaque,
      raisedSurface: raisedSurface ?? this.raisedSurface,
      controlFill: controlFill ?? this.controlFill,
      hoverFill: hoverFill ?? this.hoverFill,
      pressedFill: pressedFill ?? this.pressedFill,
      selectedFill: selectedFill ?? this.selectedFill,
      separator: separator ?? this.separator,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      accent: accent ?? this.accent,
      focusRing: focusRing ?? this.focusRing,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  @override
  StarsDesktopTokens lerp(covariant StarsDesktopTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return StarsDesktopTokens(
      windowBackground:
          Color.lerp(windowBackground, other.windowBackground, t)!,
      contentBackground:
          Color.lerp(contentBackground, other.contentBackground, t)!,
      sidebarOpaque: Color.lerp(sidebarOpaque, other.sidebarOpaque, t)!,
      raisedSurface: Color.lerp(raisedSurface, other.raisedSurface, t)!,
      controlFill: Color.lerp(controlFill, other.controlFill, t)!,
      hoverFill: Color.lerp(hoverFill, other.hoverFill, t)!,
      pressedFill: Color.lerp(pressedFill, other.pressedFill, t)!,
      selectedFill: Color.lerp(selectedFill, other.selectedFill, t)!,
      separator: Color.lerp(separator, other.separator, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      tertiaryText: Color.lerp(tertiaryText, other.tertiaryText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      reduceTransparency:
          t < 0.5 ? reduceTransparency : other.reduceTransparency,
      highContrast: t < 0.5 ? highContrast : other.highContrast,
    );
  }
}

ShadThemeData buildStarsShadTheme({
  required Brightness brightness,
  required double fontSize,
  bool highContrast = false,
}) {
  final contentFontSize = fontSize.clamp(12.0, 24.0);
  final isDark = brightness == Brightness.dark;
  final baseColorScheme =
      isDark
          ? const ShadZincColorScheme.dark()
          : const ShadZincColorScheme.light();
  final colorScheme =
      highContrast
          ? baseColorScheme.copyWith(
            secondary:
                isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
            mutedForeground:
                isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B),
            accent: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
            border: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
            input: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
            ring: isDark ? const Color(0xFFFAFAFA) : const Color(0xFF09090B),
          )
          : baseColorScheme;
  final baseTextTheme = ShadTextTheme(
    p: TextStyle(
      fontSize: contentFontSize,
      height: 1.6,
      fontFamilyFallback: _desktopFontFallback,
    ),
    large: TextStyle(
      fontSize: (contentFontSize - 1).clamp(13.0, 23.0),
      fontWeight: FontWeight.w600,
      height: 1.4,
      fontFamilyFallback: _desktopFontFallback,
    ),
    small: TextStyle(
      fontSize: (contentFontSize - 3).clamp(12.0, 21.0),
      height: 1.4,
      fontFamilyFallback: _desktopFontFallback,
    ),
    muted: TextStyle(
      fontSize: (contentFontSize - 3).clamp(12.0, 21.0),
      height: 1.4,
      fontFamilyFallback: _desktopFontFallback,
    ),
  );

  return ShadThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    radius: const BorderRadius.all(Radius.circular(6)),
    textTheme: baseTextTheme,
  );
}

/// Keeps existing Material-only mobile widgets usable while the desktop tree
/// consumes Shad components and Shad's Zinc color system.
ThemeData buildShadMaterialBridgeTheme({
  required BuildContext context,
  required double fontSize,
  bool highContrast = false,
  bool reduceTransparency = false,
}) {
  final shadMaterialTheme = Theme.of(context);
  final legacyTheme = buildAppTheme(
    brightness: shadMaterialTheme.brightness,
    fontSize: fontSize,
    highContrast: highContrast,
    reduceTransparency: reduceTransparency,
  );

  return legacyTheme.copyWith(
    colorScheme: shadMaterialTheme.colorScheme,
    scaffoldBackgroundColor: shadMaterialTheme.scaffoldBackgroundColor,
    dividerTheme: shadMaterialTheme.dividerTheme.copyWith(space: 1),
    textSelectionTheme: shadMaterialTheme.textSelectionTheme,
    iconTheme: shadMaterialTheme.iconTheme,
    scrollbarTheme: shadMaterialTheme.scrollbarTheme,
  );
}

/// The original Material palette used by mobile before the desktop Shad
/// migration. Keeping it separate prevents desktop Zinc tokens from changing
/// existing Android and iOS surfaces.
ThemeData buildLegacyMobileTheme({
  required Brightness brightness,
  required double fontSize,
  bool highContrast = false,
  bool reduceTransparency = false,
}) {
  final tokens =
      brightness == Brightness.dark
          ? StarsDesktopTokens(
            windowBackground: const Color(0xFF1C1C1E),
            contentBackground: const Color(0xFF18181A),
            sidebarOpaque: const Color(0xFF242426),
            raisedSurface: const Color(0xFF2C2C2E),
            controlFill: const Color(0x14FFFFFF),
            hoverFill: const Color(0x12FFFFFF),
            pressedFill: const Color(0x1CFFFFFF),
            selectedFill:
                highContrast
                    ? const Color(0x610A84FF)
                    : const Color(0x380A84FF),
            separator:
                highContrast
                    ? const Color(0x6BFFFFFF)
                    : const Color(0x24FFFFFF),
            primaryText: const Color(0xFFF5F5F7),
            secondaryText: const Color(0xFFAEAEB2),
            tertiaryText: const Color(0xFF8E8E93),
            accent: const Color(0xFF0A84FF),
            focusRing: const Color(0xFF0A84FF),
            success: const Color(0xFF30D158),
            warning: const Color(0xFFFF9F0A),
            danger: const Color(0xFFFF453A),
            reduceTransparency: reduceTransparency,
            highContrast: highContrast,
          )
          : StarsDesktopTokens(
            windowBackground: const Color(0xFFF5F5F7),
            contentBackground: const Color(0xFFFFFFFF),
            sidebarOpaque: const Color(0xFFF0F0F2),
            raisedSurface: const Color(0xFFFFFFFF),
            controlFill: const Color(0x1F787880),
            hoverFill: const Color(0x0D000000),
            pressedFill: const Color(0x17000000),
            selectedFill:
                highContrast
                    ? const Color(0x3D007AFF)
                    : const Color(0x1F007AFF),
            separator:
                highContrast
                    ? const Color(0x6B3C3C43)
                    : const Color(0x2E3C3C43),
            primaryText: const Color(0xFF1D1D1F),
            secondaryText: const Color(0xFF6E6E73),
            tertiaryText: const Color(0xFF8E8E93),
            accent: const Color(0xFF007AFF),
            focusRing: const Color(0xFF007AFF),
            success: const Color(0xFF248A3D),
            warning: const Color(0xFFC93400),
            danger: const Color(0xFFD70015),
            reduceTransparency: reduceTransparency,
            highContrast: highContrast,
          );
  final colorScheme = (brightness == Brightness.dark
          ? ColorScheme.dark(
            primary: tokens.accent,
            onPrimary: Colors.white,
            secondary: tokens.raisedSurface,
            onSecondary: tokens.primaryText,
            surface: tokens.contentBackground,
            onSurface: tokens.primaryText,
            error: tokens.danger,
            onError: Colors.white,
          )
          : ColorScheme.light(
            primary: tokens.accent,
            onPrimary: Colors.white,
            secondary: tokens.raisedSurface,
            onSecondary: tokens.primaryText,
            surface: tokens.contentBackground,
            onSurface: tokens.primaryText,
            error: tokens.danger,
            onError: Colors.white,
          ))
      .copyWith(
        tertiary: tokens.controlFill,
        onTertiary: tokens.primaryText,
        surfaceContainerHighest: tokens.controlFill,
        surfaceContainerHigh: tokens.raisedSurface,
        outline: tokens.separator,
        outlineVariant: tokens.separator,
        onSurfaceVariant: tokens.secondaryText,
      );
  const controlRadius = BorderRadius.all(Radius.circular(8));
  const containerRadius = BorderRadius.all(Radius.circular(12));
  final base = buildAppTheme(
    brightness: brightness,
    fontSize: fontSize,
    highContrast: highContrast,
    reduceTransparency: reduceTransparency,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.windowBackground,
    dividerColor: tokens.separator,
    focusColor: tokens.focusRing,
    hoverColor: tokens.hoverFill,
    splashColor: tokens.pressedFill,
    extensions: <ThemeExtension<dynamic>>[tokens],
    dividerTheme: DividerThemeData(
      color: tokens.separator,
      space: 1,
      thickness: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.controlFill,
      isDense: true,
      hintStyle: TextStyle(color: tokens.tertiaryText),
      border: const OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: tokens.separator, width: 0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(
          color: tokens.focusRing,
          width: highContrast ? 2 : 1.5,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tokens.accent,
      selectionColor: tokens.accent.withValues(alpha: 0.24),
      selectionHandleColor: tokens.accent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(tokens.accent),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed)
              ? tokens.pressedFill
              : tokens.hoverFill;
        }),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: controlRadius),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.raisedSurface,
        border: Border.all(color: tokens.separator, width: 0),
        borderRadius: containerRadius,
        boxShadow: DesktopThemeTokens.floatingShadowFor(tokens, subtle: true),
      ),
      textStyle: TextStyle(color: tokens.primaryText, fontSize: 12),
      waitDuration: const Duration(milliseconds: 450),
    ),
  );
}

ThemeData buildAppTheme({
  required Brightness brightness,
  required double fontSize,
  bool highContrast = false,
  bool reduceTransparency = false,
}) {
  final tokens =
      brightness == Brightness.dark
          ? StarsDesktopTokens.dark(
            highContrast: highContrast,
            reduceTransparency: reduceTransparency,
          )
          : StarsDesktopTokens.light(
            highContrast: highContrast,
            reduceTransparency: reduceTransparency,
          );
  final colorScheme = (brightness == Brightness.dark
          ? ColorScheme.dark(
            primary: tokens.accent,
            onPrimary: const Color(0xFF18181B),
            secondary: tokens.raisedSurface,
            onSecondary: tokens.primaryText,
            surface: tokens.contentBackground,
            onSurface: tokens.primaryText,
            error: tokens.danger,
            onError: const Color(0xFFFAFAFA),
          )
          : ColorScheme.light(
            primary: tokens.accent,
            onPrimary: const Color(0xFFFAFAFA),
            secondary: tokens.raisedSurface,
            onSecondary: tokens.primaryText,
            surface: tokens.contentBackground,
            onSurface: tokens.primaryText,
            error: tokens.danger,
            onError: const Color(0xFFFAFAFA),
          ))
      .copyWith(
        tertiary: tokens.controlFill,
        onTertiary: tokens.primaryText,
        surfaceContainerHighest: tokens.controlFill,
        surfaceContainerHigh: tokens.raisedSurface,
        outline: tokens.separator,
        outlineVariant: tokens.separator,
        onSurfaceVariant: tokens.secondaryText,
      );
  final contentFontSize = fontSize.clamp(12.0, 24.0);

  return ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.windowBackground,
    dividerColor: tokens.separator,
    focusColor: tokens.focusRing,
    hoverColor: tokens.hoverFill,
    splashColor: tokens.pressedFill,
    extensions: <ThemeExtension<dynamic>>[tokens],
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textTheme: TextTheme(
      titleLarge: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
        fontFamilyFallback: _desktopFontFallback,
      ),
      titleMedium: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontFamilyFallback: _desktopFontFallback,
      ),
      titleSmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontFamilyFallback: _desktopFontFallback,
      ),
      bodyLarge: TextStyle(
        fontSize: contentFontSize,
        height: 1.6,
        fontFamilyFallback: _desktopFontFallback,
      ),
      bodyMedium: TextStyle(
        fontSize: (contentFontSize - 2).clamp(12.0, 22.0),
        height: 1.45,
        fontFamilyFallback: _desktopFontFallback,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        height: 1.4,
        fontFamilyFallback: _desktopFontFallback,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamilyFallback: _desktopFontFallback,
      ),
      labelMedium: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.4,
        fontFamilyFallback: _desktopFontFallback,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        height: 1.4,
        fontFamilyFallback: _desktopFontFallback,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: tokens.separator,
      space: 1,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.contentBackground,
      isDense: true,
      hintStyle: TextStyle(color: tokens.tertiaryText),
      border: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide(color: tokens.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: DesktopThemeTokens.controlRadius,
        borderSide: BorderSide(
          color: tokens.focusRing,
          width: highContrast ? 2 : 1.5,
        ),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tokens.accent,
      selectionColor: tokens.accent.withValues(alpha: 0.24),
      selectionHandleColor: tokens.accent,
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(tokens.accent),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.pressed)
              ? tokens.pressedFill
              : tokens.hoverFill;
        }),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: DesktopThemeTokens.controlRadius,
          ),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.raisedSurface,
        border: Border.all(color: tokens.separator),
        borderRadius: DesktopThemeTokens.containerRadius,
        boxShadow: DesktopThemeTokens.floatingShadowFor(tokens, subtle: true),
      ),
      textStyle: TextStyle(color: tokens.primaryText, fontSize: 12),
      waitDuration: const Duration(milliseconds: 450),
    ),
  );
}

const List<String> _desktopFontFallback = [
  'Segoe UI',
  'Microsoft YaHei UI',
  'PingFang SC',
  'Noto Sans CJK SC',
  'Noto Sans',
  'Ubuntu',
  'sans-serif',
];

/// Compatibility facade for existing desktop widgets.
///
/// New widgets should read [StarsDesktopTokens] directly. Keeping this API
/// avoids a flag-day migration while the desktop shell is rebuilt.
class DesktopThemeTokens {
  static const double sidebarWidth = 300;
  static const double sidebarMinWidth = 240;
  static const double sidebarMaxWidth = 360;
  static const double listPanelWidth = 300;
  static const double profileRailWidth = 300;
  static const double inspectorWidth = 320;
  static const double inspectorMinWidth = 280;
  static const double inspectorMaxWidth = 380;
  static const double detailMinWidth = 560;
  static const double toolbarHeight = 50;
  static const double menuBarHeight = toolbarHeight;
  static const double shellGap = 0;
  static const double controlHeight = 32;
  static const double iconButtonSize = 32;
  static const double listItemMinHeight = 44;
  static const double formContentMaxWidth = 720;
  static const EdgeInsets formPagePadding = EdgeInsets.fromLTRB(32, 28, 32, 48);
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

  static Color success(BuildContext context) => tokens(context).success;

  static Color warning(BuildContext context) => tokens(context).warning;

  static Color error(BuildContext context) => tokens(context).danger;

  static TextStyle? pageTitleStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 17,
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

enum StarsGlassRole { toolbar, sidebar, composer, popover, overlayInspector }

/// Solid semantic fallback for glass-role surfaces.
///
/// This widget intentionally never constructs a BackdropFilter. Native/window
/// material integration can be added behind this API when it is reliable.
class StarsGlassSurface extends StatelessWidget {
  const StarsGlassSurface({super.key, required this.role, required this.child});

  final StarsGlassRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final transient =
        role == StarsGlassRole.popover ||
        role == StarsGlassRole.overlayInspector;
    final composer = role == StarsGlassRole.composer;
    final borderRadius =
        transient
            ? DesktopThemeTokens.containerRadius
            : composer
            ? DesktopThemeTokens.inputRadius
            : BorderRadius.zero;
    final color = switch (role) {
      StarsGlassRole.sidebar => tokens.sidebarOpaque,
      StarsGlassRole.toolbar => tokens.raisedSurface,
      StarsGlassRole.composer => tokens.raisedSurface,
      StarsGlassRole.popover => tokens.raisedSurface,
      StarsGlassRole.overlayInspector => tokens.raisedSurface,
    };
    final border = switch (role) {
      StarsGlassRole.toolbar => Border(
        bottom: BorderSide(color: tokens.separator, width: 0),
      ),
      StarsGlassRole.sidebar => Border(
        right: BorderSide(color: tokens.separator, width: 0),
      ),
      _ => Border.all(color: tokens.separator, width: 0),
    };

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: border,
        borderRadius: borderRadius,
        boxShadow:
            transient || composer
                ? DesktopThemeTokens.floatingShadow(context, subtle: composer)
                : null,
      ),
      clipBehavior:
          borderRadius == BorderRadius.zero ? Clip.none : Clip.antiAlias,
      child: child,
    );
  }
}

class StarsToolbarButton extends StatelessWidget {
  const StarsToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final shadTheme = ShadTheme.maybeOf(context);
    if (shadTheme != null) {
      final button = ShadIconButton.ghost(
        icon: icon,
        iconSize: 18,
        width: 32,
        height: 32,
        enabled: onPressed != null,
        onPressed: onPressed,
        foregroundColor:
            selected ? shadTheme.colorScheme.accentForeground : null,
        backgroundColor:
            selected ? shadTheme.colorScheme.accent : Colors.transparent,
      );
      return Semantics(
        button: true,
        enabled: onPressed != null,
        selected: selected,
        label: semanticLabel ?? tooltip,
        excludeSemantics: true,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: ShadTooltip(
              builder: (context) => Text(tooltip),
              child: button,
            ),
          ),
        ),
      );
    }
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(32, 32)),
      maximumSize: const WidgetStatePropertyAll(Size(32, 32)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      iconSize: const WidgetStatePropertyAll(18),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return tokens.tertiaryText;
        }
        return selected ? tokens.accent : tokens.primaryText;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return tokens.pressedFill;
        }
        if (selected) {
          return tokens.selectedFill;
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return tokens.hoverFill;
        }
        return Colors.transparent;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.focused)) {
          return BorderSide.none;
        }
        return BorderSide(
          color: tokens.focusRing,
          width: tokens.highContrast ? 2 : 1.5,
        );
      }),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: DesktopThemeTokens.controlRadius),
      ),
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: selected,
      label: semanticLabel ?? tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: IconButton(onPressed: onPressed, style: style, icon: icon),
          ),
        ),
      ),
    );
  }
}

class StarsSearchField extends StatelessWidget {
  const StarsSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
    this.enabled = true,
    this.autofocus = false,
    this.suffixIcon,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;
  final bool enabled;
  final bool autofocus;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    return Semantics(
      container: true,
      textField: true,
      enabled: enabled,
      label: semanticLabel ?? hintText,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child:
            shadTheme == null
                ? TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: autofocus,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: DesktopThemeTokens.searchDecoration(
                    context,
                    hintText: hintText,
                    suffixIcon: suffixIcon,
                  ),
                )
                : ShadInput(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  autofocus: autofocus,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  placeholder: Text(hintText),
                  leading: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: Icon(
                      LucideIcons.search,
                      size: 16,
                      color: shadTheme.colorScheme.mutedForeground,
                    ),
                  ),
                  trailing: suffixIcon,
                  constraints: const BoxConstraints(minHeight: 36),
                ),
      ),
    );
  }
}

/// Retained name for source compatibility; the visual is intentionally flat.
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
    final tokens = StarsDesktopTokens.of(context);
    final shadTheme = ShadTheme.maybeOf(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: tokens.primaryText,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: tokens.secondaryText);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageAsset != null) ...[
          Image.asset(
            imageAsset!,
            width: 56,
            height: 56,
            cacheWidth: 112,
            cacheHeight: 112,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) =>
                    _EmptyStateIcon(icon: icon, tokens: tokens),
          ),
          const SizedBox(height: 12),
        ] else ...[
          _EmptyStateIcon(icon: icon, tokens: tokens),
          const SizedBox(height: 16),
        ],
        Text(title, textAlign: TextAlign.center, style: titleStyle),
        const SizedBox(height: 8),
        Text(description, textAlign: TextAlign.center, style: bodyStyle),
        if (supportingText != null) ...[
          const SizedBox(height: 6),
          Text(
            supportingText!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.tertiaryText),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding:
                shadTheme == null ? EdgeInsets.zero : const EdgeInsets.all(8),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateIcon extends StatelessWidget {
  const _EmptyStateIcon({required this.icon, required this.tokens});

  final IconData icon;
  final StarsDesktopTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tokens.selectedFill,
          borderRadius: DesktopThemeTokens.containerRadius,
        ),
        child: Icon(icon, size: 18, color: tokens.accent),
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
  final FocusNode? searchFocusNode;
  final TextEditingController? searchController;
  final Widget? searchSuffix;
  final double? contentMaxWidth;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  const DesktopListPanel({
    super.key,
    required this.title,
    required this.description,
    required this.searchHintText,
    required this.onSearchChanged,
    required this.action,
    required this.child,
    this.searchFocusNode,
    this.searchController,
    this.searchSuffix,
    this.contentMaxWidth,
    this.padding = DesktopThemeTokens.panelPadding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    final content = Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesktopThemeTokens.sectionTitleStyle(context),
                    ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesktopThemeTokens.metaStyle(context),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            action,
          ],
        ),
        const SizedBox(height: 12),
        StarsSearchField(
          hintText: searchHintText,
          controller: searchController,
          focusNode: searchFocusNode,
          onChanged: onSearchChanged,
          suffixIcon: searchSuffix,
        ),
        const SizedBox(height: 12),
        Expanded(child: child),
      ],
    );
    return ColoredBox(
      color: backgroundColor ?? tokens.sidebarOpaque,
      child: Padding(
        padding: padding,
        child:
            contentMaxWidth == null
                ? content
                : Center(
                  child: SizedBox(
                    width: contentMaxWidth,
                    height: double.infinity,
                    child: content,
                  ),
                ),
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
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  State<DesktopInteractiveListItem> createState() =>
      _DesktopInteractiveListItemState();
}

class _DesktopInteractiveListItemState
    extends State<DesktopInteractiveListItem> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (ShadTheme.maybeOf(context) != null) {
      return Semantics(
        button: true,
        selected: widget.selected,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: DesktopThemeTokens.listItemMinHeight,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ShadButton.raw(
              variant:
                  widget.selected
                      ? ShadButtonVariant.secondary
                      : ShadButtonVariant.ghost,
              expands: true,
              height: 0,
              padding: widget.padding,
              mainAxisAlignment: MainAxisAlignment.start,
              onPressed: widget.onTap,
              child: widget.child,
            ),
          ),
        ),
      );
    }
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      selected: widget.selected,
      child: AnimatedContainer(
        duration:
            disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(
          minHeight: DesktopThemeTokens.listItemMinHeight,
        ),
        decoration: DesktopThemeTokens.listItemDecoration(
          context,
          selected: widget.selected,
          hovered: _hovered,
          pressed: _pressed,
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
            if (_hovered != value) {
              setState(() => _hovered = value);
            }
          },
          onShowFocusHighlight: (value) {
            if (_focused != value) {
              setState(() => _focused = value);
            }
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (_pressed != value) {
                  setState(() => _pressed = value);
                }
              },
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              borderRadius: DesktopThemeTokens.itemRadius,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class StarsDesktopTheme {
  static double get panelRadius => DesktopThemeTokens.panelRadiusValue;
  static double get cardRadius => DesktopThemeTokens.statusRadiusValue;
  static double get bubbleRadius => DesktopThemeTokens.bubbleRadiusValue;
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
    return DesktopThemeTokens.panelSurface(context);
  }

  static Color userBubble(BuildContext context) {
    return DesktopThemeTokens.selectedFill(context);
  }

  static Color statusCardBackground(BuildContext context) {
    return DesktopThemeTokens.secondarySurface(context);
  }

  static List<BoxShadow> panelShadow(BuildContext context) {
    return DesktopThemeTokens.panelShadow(context);
  }
}
