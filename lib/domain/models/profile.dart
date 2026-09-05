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
    this.injectApplicationPrompt = true,
    this.strictGroundingMode = false,
    required this.createTimestamp,
    required this.modifyTimestamp,
  });

  final String name;
  final String avatar;
  final double fontSize;
  final int themeMode;
  final String language;
  final bool showExecutionStatus;
  final bool injectApplicationPrompt;
  final bool strictGroundingMode;
  final DateTime createTimestamp;
  final DateTime modifyTimestamp;

  Profile copyWith({
    String? name,
    String? avatar,
    double? fontSize,
    int? themeMode,
    String? language,
    bool? showExecutionStatus,
    bool? injectApplicationPrompt,
    bool? strictGroundingMode,
    DateTime? createTimestamp,
    DateTime? modifyTimestamp,
  }) {
    return Profile(
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      showExecutionStatus: showExecutionStatus ?? this.showExecutionStatus,
      injectApplicationPrompt:
          injectApplicationPrompt ?? this.injectApplicationPrompt,
      strictGroundingMode: strictGroundingMode ?? this.strictGroundingMode,
      createTimestamp: createTimestamp ?? this.createTimestamp,
      modifyTimestamp: modifyTimestamp ?? this.modifyTimestamp,
    );
  }
}
