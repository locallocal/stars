import 'package:flutter/widgets.dart';

/// Lets the conversation list open its selected chat's task workspace.
final class StarsConversationTasksScope extends InheritedWidget {
  const StarsConversationTasksScope({
    super.key,
    required this.onShow,
    required super.child,
  });
  final VoidCallback onShow;

  static StarsConversationTasksScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StarsConversationTasksScope>();

  @override
  bool updateShouldNotify(StarsConversationTasksScope oldWidget) =>
      onShow != oldWidget.onShow;
}
