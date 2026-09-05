part of 'message_list.dart';

void _showImageDialog(
  BuildContext context,
  String imagePath,
  MessageActionViewModel? actions, {
  String trustAnnotation = '',
}) {
  final isDesktop = isDesktopPlatform(context);

  Future<void> saveImage(BuildContext dialogContext) async {
    final strings = S.of(dialogContext);
    try {
      final result = await actions?.saveImage(
        sourcePath: imagePath,
        dialogTitle: strings.saveImage,
      );
      if (result != MediaExportResult.saved || !dialogContext.mounted) return;
      showDialog<void>(
        context: dialogContext,
        barrierColor: Colors.transparent,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              content: Text(
                strings.imageSavedToGallery,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
      );
      Future<void>.delayed(const Duration(milliseconds: 1500), () {
        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      });
    } catch (error) {
      if (dialogContext.mounted) {
        showStarsNotice(
          dialogContext,
          strings.saveImageFailed(safeFailureMessage(dialogContext, error)),
        );
      }
    }
  }

  Future<void> shareImage(BuildContext dialogContext) async {
    try {
      await actions?.shareImage(
        sourcePath: imagePath,
        text: <String>[
          S.of(dialogContext).sharedImageFromStars,
          if (trustAnnotation.isNotEmpty) trustAnnotation,
        ].join('\n\n'),
      );
    } catch (error) {
      if (dialogContext.mounted) {
        showStarsNotice(
          dialogContext,
          S
              .of(dialogContext)
              .shareImageFailed(safeFailureMessage(dialogContext, error)),
        );
      }
    }
  }

  Widget actionButton({
    required BuildContext dialogContext,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    if (!isDesktop) {
      return FloatingActionButton(
        mini: true,
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        onPressed: onPressed,
        tooltip: tooltip,
        child: Icon(icon, color: Colors.white),
      );
    }

    return StarsDesktopIconAction(
      icon: icon,
      label: tooltip,
      variant: ShadButtonVariant.secondary,
      onPressed: onPressed,
    );
  }

  Widget preview(BuildContext dialogContext) {
    return Stack(
      key: const ValueKey<String>('message-image-dialog-preview'),
      children: [
        if (isDesktop)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
          )
        else
          Image.file(File(imagePath), fit: BoxFit.contain),
        Positioned(
          right: 12,
          bottom: 12,
          child: Row(
            children: [
              actionButton(
                dialogContext: dialogContext,
                tooltip: S.of(dialogContext).saveImage,
                icon: isDesktop ? LucideIcons.download : Icons.save_alt_rounded,
                onPressed: () => saveImage(dialogContext),
              ),
              const SizedBox(width: 8),
              actionButton(
                dialogContext: dialogContext,
                tooltip: S.of(dialogContext).shareImage,
                icon: isDesktop ? LucideIcons.share2 : Icons.share_rounded,
                onPressed: () => shareImage(dialogContext),
              ),
              const SizedBox(width: 8),
              actionButton(
                dialogContext: dialogContext,
                tooltip:
                    MaterialLocalizations.of(dialogContext).closeButtonTooltip,
                icon: isDesktop ? LucideIcons.x : Icons.close_rounded,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  if (isDesktop) {
    final windowSize = MediaQuery.sizeOf(context);
    final width = (windowSize.width - 32).clamp(0.0, 960.0).toDouble();
    final height = (windowSize.height - 32).clamp(0.0, 720.0).toDouble();
    showChatShadDialog<void>(
      context: context,
      builder:
          (dialogContext) => ShadDialog(
            key: const ValueKey<String>('message-image-dialog'),
            constraints: BoxConstraints.tightFor(width: width, height: height),
            scrollable: false,
            padding: EdgeInsets.zero,
            gap: 0,
            closeIcon: const SizedBox.shrink(),
            child: preview(dialogContext),
          ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(child: preview(dialogContext)),
  );
}
