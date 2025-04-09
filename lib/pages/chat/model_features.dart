import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';

class ChatModelFeatures extends StatelessWidget {
  final bool isWebSearchEnabled;
  final bool isDeepThinkingEnabled;
  final bool supportWebSearch;
  final bool supportDeepThinking;
  final Function(bool) onWebSearchToggle;
  final Function(bool) onDeepThinkingToggle;

  const ChatModelFeatures({
    super.key,
    required this.isWebSearchEnabled,
    required this.isDeepThinkingEnabled,
    required this.supportWebSearch,
    required this.supportDeepThinking,
    required this.onWebSearchToggle,
    required this.onDeepThinkingToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (supportWebSearch)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: OutlinedButton.icon(
                onPressed: () {
                  onWebSearchToggle(!isWebSearchEnabled);
                },
                icon: const Icon(Icons.public, size: 16),
                label: Text(
                  S.of(context).webSearch,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  iconColor:
                      isWebSearchEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                  backgroundColor:
                      isWebSearchEnabled
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  side: const BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          if (supportDeepThinking)
            OutlinedButton.icon(
              onPressed: () {
                onDeepThinkingToggle(!isDeepThinkingEnabled);
              },
              icon: const Icon(Icons.psychology, size: 16),
              label: Text(
                S.of(context).deepThinking,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                iconColor:
                    isDeepThinkingEnabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                backgroundColor:
                    isDeepThinkingEnabled
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
        ],
      ),
    );
  }
}
