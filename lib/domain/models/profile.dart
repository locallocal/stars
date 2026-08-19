abstract final class ProfileDefaults {
  static const double desktopFontSize = 14.0;
  static const double mobileFontSize = 16.0;
}

class Profile {
  const Profile({
    required this.name,
    required this.avatar,
    required this.fontSize,
    required this.themeMode,
    required this.language,
    this.showExecutionStatus = true,
    required this.createTimestamp,
    required this.modifyTimestamp,
  });

  final String name;
  final String avatar;
  final double fontSize;
  final int themeMode;
  final String language;
  final bool showExecutionStatus;
  final DateTime createTimestamp;
  final DateTime modifyTimestamp;
}
