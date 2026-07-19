import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/common/logo.dart';
import 'package:stars/utils/utils.dart';

class WelcomeView extends StatelessWidget {
  final Bot bot;
  final double? fontSize;
  final bool isDesktop;

  const WelcomeView({
    super.key,
    required this.bot,
    this.fontSize,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? 16;
    final shadTheme = ShadTheme.maybeOf(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDesktop && shadTheme != null)
                ShadAvatar(
                  bot.avatar.isEmpty ? null : File(bot.avatar),
                  size: const Size.square(64),
                  placeholder: buildProviderLogo(context, '', bot.provider, 30),
                )
              else
                Container(
                  width: 128,
                  height: 128,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child:
                      bot.avatar.isEmpty
                          ? buildProviderLogo(context, '', bot.provider, 96)
                          : ClipOval(
                            child: Image.file(
                              File(bot.avatar),
                              fit: BoxFit.cover,
                            ),
                          ),
                ),
              SizedBox(height: isDesktop ? 20 : 24),
              Text(
                bot.name,
                style:
                    isDesktop && shadTheme != null
                        ? shadTheme.textTheme.h4
                        : TextStyle(
                          fontSize: effectiveFontSize + 2,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  S.of(context).botGreeting(bot.name),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: effectiveFontSize,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  desktopConversationText(
                    context,
                    S.of(context).startChatPrompt,
                  ),
                  style: TextStyle(
                    color:
                        isDesktop && shadTheme != null
                            ? shadTheme.colorScheme.mutedForeground
                            : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: effectiveFontSize - 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
