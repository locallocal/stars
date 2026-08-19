import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_profile_repository.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('desktop platforms default to 14px', () {
    for (final platform in const [
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ]) {
      expect(
        defaultProfileFontSizeForPlatform(platform),
        ProfileDefaults.desktopFontSize,
      );
    }
  });

  test('mobile platforms and web retain the 16px default', () {
    for (final platform in const [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ]) {
      expect(
        defaultProfileFontSizeForPlatform(platform),
        ProfileDefaults.mobileFontSize,
      );
    }
    expect(
      defaultProfileFontSizeForPlatform(TargetPlatform.linux, isWeb: true),
      ProfileDefaults.mobileFontSize,
    );
  });
}
