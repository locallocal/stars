import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Semantic desktop colors and accessibility state for Stars.
///
/// The fallback palette mirrors the shadcn Zinc scheme. Keeping these semantic
/// names lets legacy Material-only widgets share the same desktop appearance.
part 'desktop_theme_spec.dart';
part 'theme_components.dart';

const _starsChartColorKeys = <String>[
  'chart-1',
  'chart-2',
  'chart-3',
  'chart-4',
  'chart-5',
];

// Flutter sRGB equivalents of shadcn/ui's default chart tokens.
const _starsLightChartColors = <String, Color>{
  'chart-1': Color(0xFFF54900),
  'chart-2': Color(0xFF009689),
  'chart-3': Color(0xFF104E64),
  'chart-4': Color(0xFFFFB900),
  'chart-5': Color(0xFFFE9A00),
};

const _starsDarkChartColors = <String, Color>{
  'chart-1': Color(0xFF1447E6),
  'chart-2': Color(0xFF00BC7D),
  'chart-3': Color(0xFFFE9A00),
  'chart-4': Color(0xFFAD46FF),
  'chart-5': Color(0xFFFF2056),
};

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
    required this.scrim,
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
      scrim: const Color(0xFF000000),
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
      scrim: const Color(0xFF000000),
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
  final Color scrim;
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
      scrim: const Color(0xFF000000),
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
    Color? scrim,
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
      scrim: scrim ?? this.scrim,
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
      scrim: Color.lerp(scrim, other.scrim, t)!,
      reduceTransparency:
          t < 0.5 ? reduceTransparency : other.reduceTransparency,
      highContrast: t < 0.5 ? highContrast : other.highContrast,
    );
  }
}

extension StarsShadChartColors on ShadColorScheme {
  /// Returns a theme-aware chart color, cycling after the five shadcn tokens.
  Color chartColor(int index) {
    assert(index >= 0, 'Chart color index must be non-negative.');
    final normalizedIndex = index % _starsChartColorKeys.length;
    final configured = custom[_starsChartColorKeys[normalizedIndex]];
    if (configured != null) return configured;
    return switch (normalizedIndex) {
      0 => primary,
      1 => selection,
      2 => accentForeground,
      3 => destructive,
      _ => mutedForeground,
    };
  }
}

ShadThemeData buildStarsShadTheme({
  required Brightness brightness,
  required double fontSize,
  bool highContrast = false,
}) {
  final contentFontSize = fontSize.clamp(12.0, 24.0);
  final isDark = brightness == Brightness.dark;
  final baseColorScheme = (isDark
          ? const ShadZincColorScheme.dark()
          : const ShadZincColorScheme.light())
      .copyWith(
        custom: isDark ? _starsDarkChartColors : _starsLightChartColors,
      );
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
            scrim: const Color(0xFF000000),
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
            scrim: const Color(0xFF000000),
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
        boxShadow: StarsDesktopThemeSpec.floatingShadowFor(
          tokens,
          subtle: true,
        ),
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
        borderRadius: StarsDesktopThemeSpec.controlRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: StarsDesktopThemeSpec.controlRadius,
        borderSide: BorderSide(color: tokens.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: StarsDesktopThemeSpec.controlRadius,
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
            borderRadius: StarsDesktopThemeSpec.controlRadius,
          ),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: tokens.raisedSurface,
        border: Border.all(color: tokens.separator),
        borderRadius: StarsDesktopThemeSpec.containerRadius,
        boxShadow: StarsDesktopThemeSpec.floatingShadowFor(
          tokens,
          subtle: true,
        ),
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
