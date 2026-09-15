import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/logo.dart';

/// A message sender's avatar, with local profile and provider fallbacks.
class MessageAvatar extends StatelessWidget {
  const MessageAvatar({
    super.key,
    required this.isCurrentUser,
    this.name = '',
    this.avatarPath = '',
    this.provider = '',
  });

  static const double size = 32;

  /// The shared fill for an avatar and its assistant message bubble.
  static Color backgroundColorOf(BuildContext context) {
    final theme = ShadTheme.maybeOf(context);
    return theme?.avatarTheme.backgroundColor ??
        theme?.colorScheme.muted ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  final bool isCurrentUser;
  final String name;
  final String avatarPath;
  final String provider;

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final backgroundColor = backgroundColorOf(context);
    final label =
        name.trim().isNotEmpty
            ? name.trim()
            : isCurrentUser
            ? S.of(context).profile
            : S.of(context).botAvatar;
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    const userPlaceholder = Icon(LucideIcons.userRound, size: 18);
    final fallback =
        isCurrentUser
            ? Image.asset(
              'assets/images/profile/avatar.png',
              width: size,
              height: size,
              cacheWidth: cacheSize,
              cacheHeight: cacheSize,
              fit: BoxFit.cover,
              frameBuilder:
                  (context, child, frame, _) =>
                      frame == null ? userPlaceholder : child,
              errorBuilder: (context, _, _) => userPlaceholder,
            )
            : buildProviderLogo(context, '', provider, 18);
    // Decode local photos at their displayed resolution in long histories.
    final image =
        avatarPath.trim().isEmpty
            ? fallback
            : Image.file(
              File(avatarPath),
              width: size,
              height: size,
              cacheWidth: cacheSize,
              cacheHeight: cacheSize,
              fit: BoxFit.cover,
              frameBuilder:
                  (context, child, frame, _) =>
                      frame == null ? fallback : child,
              errorBuilder: (context, _, _) => fallback,
            );

    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child:
          shadTheme != null
              ? ShadAvatar(
                null,
                size: const Size.square(size),
                backgroundColor: backgroundColor,
                placeholder: image,
              )
              : Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  shape: const CircleBorder(),
                  color: backgroundColor,
                ),
                child: image,
              ),
    );
  }
}
