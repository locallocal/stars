/// Builds language-neutral lexical terms for local relevance scoring.
///
/// Latin text is tokenized by word. CJK text uses overlapping character
/// bigrams, which avoids treating an entire unsegmented Chinese sentence as
/// one term while keeping common single characters from dominating matches.
Set<String> buildRetrievalTerms(String value) {
  final normalized = value.toLowerCase();
  final terms = <String>{};
  final latinWord = StringBuffer();
  final cjkRun = <int>[];

  void flushLatin() {
    final word = latinWord.toString();
    latinWord.clear();
    if (word.length > 1) terms.add(word);
  }

  void flushCjk() {
    if (cjkRun.isEmpty) return;
    if (cjkRun.length == 1) {
      terms.add(String.fromCharCode(cjkRun.single));
    } else {
      for (var index = 0; index + 1 < cjkRun.length; index += 1) {
        terms.add(String.fromCharCodes(cjkRun.sublist(index, index + 2)));
      }
    }
    cjkRun.clear();
  }

  for (final rune in normalized.runes) {
    if (_isCjkRune(rune)) {
      flushLatin();
      cjkRun.add(rune);
    } else if (_isLatinLetterOrDigit(rune)) {
      flushCjk();
      latinWord.writeCharCode(rune);
    } else {
      flushLatin();
      flushCjk();
    }
  }
  flushLatin();
  flushCjk();
  return terms;
}

double retrievalCoverage(Set<String> queryTerms, String candidate) {
  if (queryTerms.isEmpty) return 0;
  final candidateTerms = buildRetrievalTerms(candidate);
  if (candidateTerms.isEmpty) return 0;
  final matches = queryTerms.where(candidateTerms.contains).length;
  return matches / queryTerms.length;
}

bool _isLatinLetterOrDigit(int rune) =>
    (rune >= 0x30 && rune <= 0x39) ||
    (rune >= 0x61 && rune <= 0x7a) ||
    (rune >= 0x00c0 && rune <= 0x024f);

bool _isCjkRune(int rune) =>
    (rune >= 0x3400 && rune <= 0x4dbf) ||
    (rune >= 0x4e00 && rune <= 0x9fff) ||
    (rune >= 0xf900 && rune <= 0xfaff) ||
    (rune >= 0x20000 && rune <= 0x2fa1f);
