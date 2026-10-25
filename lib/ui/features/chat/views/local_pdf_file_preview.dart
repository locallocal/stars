import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';

/// Shared local PDF reader for conversation artifacts and message attachments.
class LocalPdfFilePreview extends StatefulWidget {
  const LocalPdfFilePreview({super.key, required this.filePath});

  final String filePath;

  @override
  State<LocalPdfFilePreview> createState() => _LocalPdfFilePreviewState();
}

class _LocalPdfFilePreviewState extends State<LocalPdfFilePreview> {
  final _controller = PdfViewerController();
  int _page = 0;
  int _pageCount = 0;

  @override
  void didUpdateWidget(covariant LocalPdfFilePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _page = 0;
      _pageCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final labels = MaterialLocalizations.of(context);
    final ready = _controller.isReady && _pageCount > 0;
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            StarsDesktopIconAction(
              icon: LucideIcons.chevronLeft,
              label: labels.previousPageTooltip,
              enabled: ready && _page > 1,
              onPressed:
                  () => unawaited(_controller.goToPage(pageNumber: _page - 1)),
            ),
            Text('$_page / $_pageCount', style: theme.textTheme.small),
            StarsDesktopIconAction(
              icon: LucideIcons.chevronRight,
              label: labels.nextPageTooltip,
              enabled: ready && _page < _pageCount,
              onPressed:
                  () => unawaited(_controller.goToPage(pageNumber: _page + 1)),
            ),
            StarsDesktopIconAction(
              icon: LucideIcons.zoomOut,
              label: S.of(context).pdfZoomOut,
              enabled: ready,
              onPressed: () => unawaited(_controller.zoomDown()),
            ),
            StarsDesktopIconAction(
              icon: LucideIcons.zoomIn,
              label: S.of(context).pdfZoomIn,
              enabled: ready,
              onPressed: () => unawaited(_controller.zoomUp()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: theme.radius,
            child: PdfViewer.file(
              widget.filePath,
              key: ValueKey(widget.filePath),
              controller: _controller,
              params: PdfViewerParams(
                backgroundColor: theme.colorScheme.muted,
                onViewerReady: (document, controller) {
                  if (!mounted) return;
                  setState(() {
                    _pageCount = document.pages.length;
                    _page = controller.pageNumber ?? 1;
                  });
                },
                onPageChanged: (page) {
                  if (mounted) setState(() => _page = page ?? 0);
                },
                loadingBannerBuilder:
                    (context, downloaded, total) =>
                        const Center(child: CircularProgressIndicator()),
                errorBannerBuilder:
                    (context, error, stack, document) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ShadAlert.destructive(
                          icon: const Icon(LucideIcons.circleAlert),
                          description: Text(
                            S.of(context).filePreviewUnavailable,
                          ),
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
