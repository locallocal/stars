part of 'openai.dart';

extension _OpenAiMessageFormatting on OpenAI {
  List<Map<String, dynamic>> _formatChatMessages(List<ChatMessage> messages) {
    return messages
        .map((message) {
          final role = _normalizedMessageRole(message.role);
          if (message.images.isEmpty) {
            return {'role': role, 'content': message.content};
          }
          final content = <Map<String, dynamic>>[];
          if (message.content.isNotEmpty) {
            content.add({'type': 'text', 'text': message.content});
          }

          for (final imagePath in message.images) {
            try {
              final file = File(imagePath);
              if (file.existsSync()) {
                final bytes = file.readAsBytesSync();
                content.add({
                  'type': 'image_url',
                  'image_url': {
                    'url':
                        'data:${getImageMediaType(bytes)};base64,${base64Encode(bytes)}',
                  },
                });
              }
            } catch (_) {
              // Skip an unreadable optional image and continue the request.
            }
          }
          return {'role': role, 'content': content};
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _processMessagesForResponses(
    List<ChatMessage> messages,
  ) {
    return messages
        .map((message) {
          final content = <Map<String, dynamic>>[];
          if (message.content.isNotEmpty) {
            content.add({'type': 'input_text', 'text': message.content});
          }
          for (final imagePath in message.images) {
            try {
              final bytes = File(imagePath).readAsBytesSync();
              content.add({
                'type': 'input_image',
                'image_url':
                    'data:${getImageMediaType(bytes)};base64,${base64Encode(bytes)}',
              });
            } on FileSystemException {
              // Ignore an optional image that was removed before sending.
            }
          }
          return {
            'role': _normalizedMessageRole(message.role),
            'content': content,
          };
        })
        .toList(growable: false);
  }
}
