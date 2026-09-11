import 'package:flutter/widgets.dart';

/// Exposes the desktop shell's clear-conversation action to its sidebar.
///
/// The selected chat page owns confirmation and mutation, while the sidebar
/// only requests the action through this scope.
class StarsConversationClearScope extends InheritedWidget {
  const StarsConversationClearScope({
    super.key,
    required this.onClear,
    required super.child,
  });

  final VoidCallback onClear;

  static StarsConversationClearScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StarsConversationClearScope>();

  @override
  bool updateShouldNotify(StarsConversationClearScope oldWidget) =>
      onClear != oldWidget.onClear;
}
