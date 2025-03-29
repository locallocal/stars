import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';

class ImageAttachments extends StatelessWidget {
  final List<File> images;
  final List<File> files;
  final VoidCallback onClearAll;
  final Function(int) onRemoveImage;
  final Function(int) onRemoveFile;

  const ImageAttachments({
    super.key,
    required this.images,
    required this.files,
    required this.onClearAll,
    required this.onRemoveImage,
    required this.onRemoveFile, // Add this parameter for the onRemoveImage callback from the men
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClearAll,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                iconSize: 20,
              ),
            ],
          ),

          // 显示图片列表
          if (images.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  S.of(context).attachedImages,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize! - 2,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Image.file(
                                images[index],
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => onRemoveImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

          // 显示文件列表
          if (files.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  S.of(context).attachedFiles,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize! - 2,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final fileName = files[index].path.split('/').last;
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            width: 150,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.insert_drive_file, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => onRemoveFile(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
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
      ),
    );
  }
}
