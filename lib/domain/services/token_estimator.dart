import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_memory.dart';

abstract interface class TokenEstimator {
  Future<int> estimateMessages(
    ModelContextProfile profile,
    List<ChatMessage> messages,
  );

  Future<int> estimateText(ModelContextProfile profile, String text);
}

/// Conservative tokenizer fallback for models without a local tokenizer.
///
/// CJK runes are counted as one token, while other text uses roughly three
/// UTF-8 bytes per token. The estimate intentionally rounds upward.
final class ConservativeTokenEstimator implements TokenEstimator {
  const ConservativeTokenEstimator({this.messageOverheadTokens = 8});

  final int messageOverheadTokens;

  @override
  Future<int> estimateMessages(
    ModelContextProfile profile,
    List<ChatMessage> messages,
  ) async {
    var total = 0;
    for (final message in messages) {
      total += messageOverheadTokens;
      total += await estimateText(profile, message.role);
      total += await estimateText(profile, message.content);
      total += await estimateText(profile, message.reasoning);
      total += message.images.length * 256;
      total += message.files.length * 64;
    }
    return total;
  }

  @override
  Future<int> estimateText(ModelContextProfile profile, String text) async {
    if (text.isEmpty) return 0;
    var cjk = 0;
    var otherBytes = 0;
    for (final rune in text.runes) {
      if (_isCjk(rune)) {
        cjk++;
      } else {
        otherBytes += rune <= 0x7f ? 1 : String.fromCharCode(rune).length;
      }
    }
    return cjk + ((otherBytes + 2) ~/ 3);
  }
}

bool _isCjk(int rune) =>
    (rune >= 0x3400 && rune <= 0x9fff) ||
    (rune >= 0xf900 && rune <= 0xfaff) ||
    (rune >= 0x3040 && rune <= 0x30ff) ||
    (rune >= 0xac00 && rune <= 0xd7af);
