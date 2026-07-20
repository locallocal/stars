import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/profile_repository.dart';
import 'package:stars/utils/utils.dart';

class AppViewModel extends ChangeNotifier {
  AppViewModel({
    required Profile initialProfile,
    required ProfileRepository profileRepository,
  }) : _profileRepository = profileRepository {
    _applyProfile(initialProfile, notify: false);
    _profileSubscription = _profileRepository.changes.listen(_applyProfile);
  }

  final ProfileRepository _profileRepository;
  late final StreamSubscription<Profile> _profileSubscription;

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('zh', 'CN');
  double _fontSize = 16;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  double get fontSize => _fontSize;

  void _applyProfile(Profile profile, {bool notify = true}) {
    _themeMode = intToThemeMode(profile.themeMode);
    _fontSize = profile.fontSize;
    final parts = profile.language.split('_');
    if (parts.length == 2) _locale = Locale(parts[0], parts[1]);
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription.cancel();
    super.dispose();
  }
}
