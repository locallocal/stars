import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/utils.dart';

/// Maps arbitrary failures to localized, product-safe copy. Raw exception
/// strings remain available only through [AppFailure.debugCause].
String safeFailureMessage(BuildContext context, Object error) {
  final failure = AppFailure.from(error);
  if (failure.code == 'bot_required_fields_missing') {
    return S.of(context).fillRequiredFields;
  }
  if (failure.code == 'database_downgrade_not_supported') {
    return S.of(context).databaseDowngradeNotSupported;
  }
  if (failure.code == 'database_recovery_failed') {
    return S.of(context).databaseRecoveryFailed;
  }
  if (failure.code == 'unsupported_image_format') {
    return S.of(context).unsupportedImageFormat;
  }
  return switch (failure.kind) {
    AppFailureKind.cancelled => S.of(context).replyCancelled,
    AppFailureKind.networkTimeout => S.of(context).statusTimedOut,
    _ => S.of(context).errorLoadingContent,
  };
}

enum StarsNoticeTone { info, success, warning, error }

/// The single transient-feedback entry point for every feature.
///
/// Desktop uses Shad Sonner. Mobile keeps a Material SnackBar because the
/// mobile shell is Material-only. Feature code must not select a feedback
/// implementation itself.
void showStarsNotice(
  BuildContext context,
  String message, {
  String? description,
  StarsNoticeTone tone = StarsNoticeTone.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  assert((actionLabel == null) == (onAction == null));
  if (isDesktopPlatform(context)) {
    final sonner = ShadSonner.maybeOf(context);
    if (sonner != null) {
      final action =
          actionLabel == null
              ? null
              : ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: onAction,
                child: Text(actionLabel),
              );
      sonner.show(
        tone == StarsNoticeTone.error
            ? ShadToast.destructive(
              title: Text(message),
              description: description == null ? null : Text(description),
              action: action,
            )
            : ShadToast(
              title: Text(message),
              description: description == null ? null : Text(description),
              action: action,
            ),
      );
      return;
    }
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final colorScheme = Theme.of(context).colorScheme;
  final foreground = switch (tone) {
    StarsNoticeTone.warning || StarsNoticeTone.error => colorScheme.onError,
    _ => colorScheme.onInverseSurface,
  };
  final background = switch (tone) {
    StarsNoticeTone.warning || StarsNoticeTone.error => colorScheme.error,
    _ => colorScheme.inverseSurface,
  };
  final mediaSize = MediaQuery.sizeOf(context);
  final scaledBodySize = MediaQuery.textScalerOf(context).scale(16);
  final useFixedSnackBar =
      mediaSize.width < 360 || mediaSize.height < 600 || scaledBodySize >= 24;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          description == null ? message : '$message\n$description',
          style: TextStyle(color: foreground),
        ),
        backgroundColor: background,
        duration: const Duration(seconds: 5),
        behavior:
            useFixedSnackBar
                ? SnackBarBehavior.fixed
                : SnackBarBehavior.floating,
        margin:
            useFixedSnackBar ? null : const EdgeInsets.fromLTRB(16, 0, 16, 16),
        action:
            actionLabel == null
                ? null
                : SnackBarAction(label: actionLabel, onPressed: onAction!),
      ),
    );
}

// 构建分组容器
Widget buildSectionContainer(
  BuildContext context,
  String title,
  List<Widget> children,
) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8.0),
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondary,
      borderRadius: BorderRadius.circular(24.0),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children
            .expand((child) => [child, const SizedBox(height: 4)])
            .take(children.length * 2 - 1),
      ],
    ),
  );
}

Widget buildCloseIcon(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface,
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.close_rounded,
      size: 16,
      color: Theme.of(context).colorScheme.secondary,
    ),
  );
}
