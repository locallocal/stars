import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';

/// Renders local raster and SVG images without reading files during build.
///
/// Full previews support panning and zooming; thumbnails keep their parent's
/// tap and scroll gestures. SVGs retain their vector rendering when enlarged.
class LocalImagePreview extends StatelessWidget {
  const LocalImagePreview({
    super.key,
    required this.filePath,
    this.interactive = false,
    this.compact = false,
  });

  final String filePath;
  final bool interactive;
  final bool compact;

  static bool isSvg(String filePath) =>
      path.extension(filePath).toLowerCase() == '.svg';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final file = File(filePath);
    final label = path.basename(filePath);
    final image =
        isSvg(filePath)
            ? SvgPicture.file(
              file,
              key: ValueKey(filePath),
              fit: BoxFit.contain,
              semanticsLabel: label,
              theme: SvgTheme(currentColor: theme.colorScheme.foreground),
              placeholderBuilder:
                  (context) => const Center(
                    child: SizedBox(width: 96, child: ShadProgress()),
                  ),
              errorBuilder: _buildError,
            )
            : Image.file(
              file,
              key: ValueKey(filePath),
              fit: BoxFit.contain,
              semanticLabel: label,
              errorBuilder: _buildError,
            );

    if (!interactive) return image;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: theme.radius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: ClipRRect(
        borderRadius: theme.radius,
        child: InteractiveViewer(
          // A new file starts fitted to its viewport rather than retaining
          // the previous file's transform.
          key: ValueKey(filePath),
          minScale: 1,
          maxScale: 8,
          child: SizedBox.expand(child: image),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, StackTrace? stack) {
    final theme = ShadTheme.of(context);
    final strings = S.of(context);
    final message =
        error is PathNotFoundException
            ? strings.fileMissing
            : strings.filePreviewUnavailable;
    return Semantics(
      label: message,
      child: ColoredBox(
        color: theme.colorScheme.muted,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.imageOff,
                  size: compact ? 24 : 40,
                  color: theme.colorScheme.mutedForeground,
                ),
                if (!compact) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
