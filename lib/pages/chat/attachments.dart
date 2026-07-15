import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/pages/chat/desktop_chat_primitives.dart';
import 'package:stars/utils/theme.dart';

class ImageAttachments extends StatelessWidget {
  final List<File> images;
  final List<File> files;
  final bool desktopMode;
  final VoidCallback onClearAll;
  final Function(int) onRemoveImage;
  final Function(int) onRemoveFile;

  const ImageAttachments({
    super.key,
    required this.images,
    required this.files,
    this.desktopMode = false,
    required this.onClearAll,
    required this.onRemoveImage,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                S.of(context).attachments,
                style: TextStyle(
                  fontSize: fontSize - 1,
                  fontWeight: FontWeight.w600,
                  color:
                      desktopMode
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            Text(
              S
                  .of(context)
                  .itemCount((images.length + files.length).toString()),
              style: TextStyle(
                fontSize: fontSize - 3,
                color: StarsDesktopTheme.mutedText(context),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (desktopMode)
              StarsDesktopIconAction(
                icon: LucideIcons.x,
                label: S.of(context).clearAttachments,
                onPressed: onClearAll,
              )
            else
              IconButton(
                icon: buildCloseIcon(context),
                onPressed: onClearAll,
                tooltip: S.of(context).clearAttachments,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),

        if (images.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).attachedImages,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize - 2,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: desktopMode ? 104 : 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: EdgeInsets.all(desktopMode ? 6 : 0),
                          decoration:
                              desktopMode
                                  ? BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: StarsDesktopTheme.borderColor(
                                        context,
                                      ),
                                    ),
                                  )
                                  : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              desktopMode ? 6 : 8,
                            ),
                            child: Image.file(
                              images[index],
                              height: desktopMode ? 92 : 90,
                              width: desktopMode ? 74 : 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: desktopMode ? 0 : 6,
                          child:
                              desktopMode
                                  ? StarsDesktopIconAction(
                                    icon: LucideIcons.x,
                                    label: S.of(context).removeImageAttachment,
                                    iconSize: 14,
                                    onPressed: () => onRemoveImage(index),
                                  )
                                  : GestureDetector(
                                    onTap: () => onRemoveImage(index),
                                    child: buildCloseIcon(context),
                                  ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

        if (files.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (images.isNotEmpty) const SizedBox(height: 8),
              Text(
                S.of(context).attachedFiles,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize - 2,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: desktopMode ? 104 : 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final fileName =
                        files[index].path.split(Platform.pathSeparator).last;
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: EdgeInsets.all(desktopMode ? 14 : 12),
                          width: desktopMode ? 132 : 90,
                          decoration: BoxDecoration(
                            color:
                                desktopMode
                                    ? Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.78)
                                    : Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              desktopMode ? 8 : 8,
                            ),
                            border:
                                desktopMode
                                    ? Border.all(
                                      color: StarsDesktopTheme.borderColor(
                                        context,
                                      ),
                                    )
                                    : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                desktopMode
                                    ? LucideIcons.file
                                    : Icons.insert_drive_file_rounded,
                                size: desktopMode ? 26 : 24,
                                color:
                                    desktopMode
                                        ? StarsDesktopTheme.mutedText(context)
                                        : null,
                              ),
                              SizedBox(height: desktopMode ? 8 : 4),
                              Text(
                                fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: desktopMode ? 12.5 : 12,
                                  color:
                                      desktopMode
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                          : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: desktopMode ? 0 : 8,
                          child:
                              desktopMode
                                  ? StarsDesktopIconAction(
                                    icon: LucideIcons.x,
                                    label: S.of(context).removeFileAttachment,
                                    iconSize: 14,
                                    onPressed: () => onRemoveFile(index),
                                  )
                                  : GestureDetector(
                                    onTap: () => onRemoveFile(index),
                                    child: buildCloseIcon(context),
                                  ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );

    if (desktopMode) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ShadCard(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: content,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
    );
  }
}
