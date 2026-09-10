import 'package:flutter/widgets.dart';

/// Exposes the desktop shell's conversation-information action to its sidebar.
///
/// The chat list is supplied to the shell as a child page, so an inherited
/// action keeps the page decoupled from the shell's private view state.
class StarsConversationInformationScope extends InheritedWidget {
  const StarsConversationInformationScope({
    super.key,
    required this.onShow,
    required super.child,
  });

  final VoidCallback onShow;

  static StarsConversationInformationScope? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            StarsConversationInformationScope
          >();

  @override
  bool updateShouldNotify(StarsConversationInformationScope oldWidget) =>
      onShow != oldWidget.onShow;
}
