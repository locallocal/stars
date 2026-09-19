import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path/path.dart' as path;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/generated/l10n.dart';

@immutable
class MessageAnchorEntry {
  const MessageAnchorEntry({required this.id, required this.message});

  final String id;
  final Message message;

  String summary(BuildContext context) {
    final text = message.content.trim();
    if (text.isNotEmpty) {
      return text.characters
          .take(160)
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ');
    }
    final strings = S.of(context);
    if (message.files.isNotEmpty) return path.basename(message.files.first);
    if (message.images.isNotEmpty) return strings.imageAttachment;
    if (message.audio.isNotEmpty) return strings.fileTypeSpeech;
    if (message.music.isNotEmpty) return strings.fileTypeMusic;
    if (message.video.isNotEmpty) return strings.fileTypeVideo;
    return strings.userMessageNavigation;
  }
}

/// A compact outline of user messages, ordered from oldest to newest.
class MessageAnchorRail extends StatefulWidget {
  const MessageAnchorRail({
    super.key,
    required this.entries,
    required this.onSelected,
    this.userName = '',
  });

  static const double width = 24;

  final List<MessageAnchorEntry> entries;
  final ValueChanged<MessageAnchorEntry> onSelected;
  final String userName;

  @override
  State<MessageAnchorRail> createState() => _MessageAnchorRailState();
}

class _MessageAnchorRailState extends State<MessageAnchorRail> {
  String? _hoveredId;
  String? _focusedId;
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    final colors = ShadTheme.of(context).colorScheme;
    final activeId = _hoveredId ?? _focusedId;
    final activeIndex = widget.entries.indexWhere(
      (entry) => entry.id == activeId,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = math.min(
          16.0,
          constraints.maxHeight / widget.entries.length,
        );
        return Center(
          child: Semantics(
            label: S.of(context).userMessageNavigation,
            container: true,
            child: FocusTraversalGroup(
              child: Column(
                key: const ValueKey('message-anchor-rail'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < widget.entries.length; index++)
                    Builder(
                      key: ValueKey(
                        'message-anchor-entry-${widget.entries[index].id}',
                      ),
                      builder: (context) {
                        final entry = widget.entries[index];
                        final distance = (index - activeIndex).abs();
                        // A raised cosine keeps the center strongest and gently
                        // tapers its neighbours instead of scaling every mark.
                        final influence =
                            activeIndex < 0 || distance >= 3
                                ? 0.0
                                : (1 + math.cos(math.pi * distance / 3)) / 2;
                        final selected = entry.id == _selectedId;
                        return _MessageAnchorTick(
                          key: ValueKey('message-anchor-${entry.id}'),
                          entry: entry,
                          index: index,
                          userName: widget.userName,
                          height: spacing,
                          previewAlignment: Alignment(
                            1,
                            index < widget.entries.length / 4
                                ? -1
                                : index >= widget.entries.length * .75
                                ? 1
                                : 0,
                          ),
                          onHover: (hovered) {
                            final next =
                                hovered
                                    ? entry.id
                                    : _hoveredId == entry.id
                                    ? null
                                    : _hoveredId;
                            if (_hoveredId != next) {
                              setState(() => _hoveredId = next);
                            }
                          },
                          onFocus: (focused) {
                            final next =
                                focused
                                    ? entry.id
                                    : _focusedId == entry.id
                                    ? null
                                    : _focusedId;
                            if (_focusedId != next) {
                              setState(() => _focusedId = next);
                            }
                          },
                          onPressed: () {
                            setState(() => _selectedId = entry.id);
                            widget.onSelected(entry);
                          },
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedContainer(
                              key: ValueKey('message-anchor-line-${entry.id}'),
                              duration:
                                  reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 140),
                              curve: Curves.easeOutCubic,
                              width: math.max(
                                selected ? 10 : 6,
                                6 + 14 * influence,
                              ),
                              height: math.min(2, spacing * .5),
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  colors.mutedForeground.withValues(alpha: .4),
                                  colors.foreground,
                                  selected ? 1 : influence,
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageAnchorTick extends StatefulWidget {
  const _MessageAnchorTick({
    super.key,
    required this.entry,
    required this.index,
    required this.userName,
    required this.height,
    required this.previewAlignment,
    required this.onHover,
    required this.onFocus,
    required this.onPressed,
    required this.child,
  });

  final MessageAnchorEntry entry;
  final int index;
  final String userName;
  final double height;
  final Alignment previewAlignment;
  final ValueChanged<bool> onHover;
  final ValueChanged<bool> onFocus;
  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_MessageAnchorTick> createState() => _MessageAnchorTickState();
}

class _MessageAnchorTickState extends State<_MessageAnchorTick> {
  static const _previewDuration = Duration(milliseconds: 120);
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final summary = widget.entry.summary(context);
    final name = widget.userName.trim();
    final time = intl.DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).add_Hm().format(widget.entry.message.timestamp.toLocal());
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ShadTooltip(
      focusNode: _focusNode,
      // ShadTooltip and its effects share a controller. Their durations must
      // agree even when an open tooltip rebuilds during a streaming update.
      duration: _previewDuration,
      effects:
          reduceMotion
              ? const []
              : const [
                FadeEffect(
                  duration: _previewDuration,
                  curve: Curves.easeOutCubic,
                ),
                ScaleEffect(
                  duration: _previewDuration,
                  begin: Offset(.95, .95),
                  end: Offset(1, 1),
                ),
                MoveEffect(
                  duration: _previewDuration,
                  begin: Offset(0, 2),
                  end: Offset.zero,
                ),
              ],
      anchor: ShadAnchor(
        overlayAlignment: Alignment.centerLeft,
        childAlignment: widget.previewAlignment,
        offset: const Offset(-12, 0),
      ),
      builder:
          (context) => SizedBox(
            key: ValueKey('message-anchor-preview-${widget.entry.id}'),
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  [if (name.isNotEmpty) name, time].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small,
                ),
              ],
            ),
          ),
      child: Semantics(
        label: S.of(context).jumpToUserMessage(widget.index + 1, summary),
        child: ShadButton.ghost(
          focusNode: _focusNode,
          onFocusChange: widget.onFocus,
          onHoverChange: widget.onHover,
          onPressed: widget.onPressed,
          width: MessageAnchorRail.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          hoverBackgroundColor: Colors.transparent,
          pressedBackgroundColor: Colors.transparent,
          child: SizedBox(
            width: MessageAnchorRail.width - 4,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
