import 'package:flutter/widgets.dart';
import 'package:stars/domain/models/profile.dart';

/// Shares the app's current profile with every route without loading it again.
class UserProfileScope extends InheritedWidget {
  const UserProfileScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final Profile profile;

  static Profile? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UserProfileScope>()?.profile;

  @override
  bool updateShouldNotify(UserProfileScope oldWidget) =>
      profile != oldWidget.profile;
}
