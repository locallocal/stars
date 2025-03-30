import 'package:flutter/material.dart';
import 'package:bubble/generated/l10n.dart';
import 'package:bubble/model/model.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final Function() onSend;
  final Function() onToggleAttachmentBar;
  final bool showAttachmentBar;
  final List<InputModality> inputModalities;
  final bool hasAttachments;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onToggleAttachmentBar,
    required this.showAttachmentBar,
    required this.inputModalities,
    required this.hasAttachments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.send,
        onSubmitted: (value) => onSend(),
        decoration: InputDecoration(
          hintText: S.of(context).messageHint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (inputModalities.contains(InputModality.image) ||
                  inputModalities.contains(InputModality.file))
                IconButton(
                  icon:
                      !showAttachmentBar
                          ? const Icon(Icons.add_circle_outline)
                          : const Icon(Icons.close),
                  tooltip: S.of(context).addAttachment,
                  onPressed: onToggleAttachmentBar,
                ),

              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return (value.text.isNotEmpty || hasAttachments)
                      ? IconButton(
                        icon: const Icon(Icons.send_rounded),
                        tooltip: S.of(context).send,
                        onPressed: onSend,
                      )
                      : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        maxLines: null,
        textAlignVertical: TextAlignVertical.center,
      ),
    );
  }
}
