part of 'theme.dart';

/// Foreground tokens for status icons on neutral or softly tinted surfaces.
///
/// These extend shadcn's palette without using its primary action color to
/// imply success. Custom themes can override each token in their color scheme.
enum StarsStatusTone {
  info('status-info-foreground', Color(0xFF1D4ED8), Color(0xFF93C5FD)),
  success('status-success-foreground', Color(0xFF166534), Color(0xFF86EFAC)),
  warning('status-warning-foreground', Color(0xFF92400E), Color(0xFFFCD34D)),
  danger('status-danger-foreground', Color(0xFFB91C1C), Color(0xFFFCA5A5)),
  reasoning(
    'status-reasoning-foreground',
    Color(0xFF6D28D9),
    Color(0xFFC4B5FD),
  );

  const StarsStatusTone(this.token, this._light, this._dark);

  final String token;
  final Color _light, _dark;

  Color _defaultForeground(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  Color foregroundFor(ShadThemeData theme) =>
      theme.colorScheme.custom[token] ?? _defaultForeground(theme.brightness);

  /// Also supports reasoning sections hosted in a mobile Material app.
  Color foreground(BuildContext context) {
    final theme = ShadTheme.maybeOf(context);
    return theme == null
        ? _defaultForeground(Theme.of(context).brightness)
        : foregroundFor(theme);
  }
}
