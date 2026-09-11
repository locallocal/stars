import 'package:flutter/widgets.dart';

/// Exposes the desktop shell's conversation-directory action to its sidebar.
///
/// The chat list is supplied to the shell as a child page, so an inherited
/// action keeps the page decoupled from the shell's private workspace state.
class StarsConversationDirectoryScope extends InheritedWidget {
  const StarsConversationDirectoryScope({
    super.key,
    required this.onShow,
    required super.child,
  });

  final VoidCallback onShow;

  static StarsConversationDirectoryScope? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            StarsConversationDirectoryScope
          >();

  @override
  bool updateShouldNotify(StarsConversationDirectoryScope oldWidget) =>
      onShow != oldWidget.onShow;
}
