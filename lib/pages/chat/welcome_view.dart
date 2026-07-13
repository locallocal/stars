import 'package:flutter/material.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/model/model.dart';
import 'package:stars/pages/common/logo.dart';

class WelcomeView extends StatelessWidget {
  final Bot bot;
  final double? fontSize;

  const WelcomeView({super.key, required this.bot, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child:
                    bot.avatar.isEmpty
                        ? buildProviderLogo(context, '', bot.provider, 96)
                        : null,
              ),
              const SizedBox(height: 24),
              Text(
                bot.name,
                style: TextStyle(
                  fontSize: fontSize! + 2,
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
                    fontSize: fontSize,
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
                  S.of(context).startChatPrompt,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize! - 2,
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
