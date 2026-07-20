import 'dart:convert';
import 'dart:io';

import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';

export 'package:stars/domain/models/ai_models.dart';

extension ChatMessageJson on ChatMessage {
  Map<String, Object> toJson() => {'role': role, 'content': content};
}

/// Shared implementation helpers for vendor-specific AI service adapters.
abstract class Provider extends AiProvider {
  Provider(super.bot);

  List<Map<String, dynamic>> processMessagesWithImages(
    List<ChatMessage> messages,
  ) {
    return messages.map((message) {
      if (message.images.isEmpty) return message.toJson();

      final content = <Map<String, dynamic>>[];
      if (message.content.isNotEmpty) {
        content.add({'type': 'text', 'text': message.content});
      }

      for (final imagePath in message.images) {
        try {
          final file = File(imagePath);
          if (file.existsSync()) {
            final base64Image = base64Encode(file.readAsBytesSync());
            content.add({
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
            });
          }
        } catch (error) {
          throw Exception('Process image $imagePath failed: $error');
        }
      }
      return {'role': message.role, 'content': content};
    }).toList();
  }

  String getImageMediaType(List<int> bytes) {
    if (bytes.length >= 3) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        return 'image/jpeg';
      }
      if (bytes.length >= 4 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
      if (bytes[0] == 0x42 && bytes[1] == 0x4D) return 'image/bmp';
      if (bytes.length >= 4 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return 'image/webp';
      }
    }
    return 'application/octet-stream';
  }

  String transformRatio(int width, int height) {
    final divisor = _calculateGreatestCommonDivisor(width, height);
    return '${width ~/ divisor}:${height ~/ divisor}';
  }

  int _calculateGreatestCommonDivisor(int left, int right) {
    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }
    return left;
  }
}
