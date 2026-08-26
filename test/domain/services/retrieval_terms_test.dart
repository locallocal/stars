import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/services/retrieval_terms.dart';

void main() {
  group('buildRetrievalTerms', () {
    test('uses overlapping bigrams for unsegmented Chinese text', () {
      expect(buildRetrievalTerms('项目截止日期'), {'项目', '目截', '截止', '止日', '日期'});
    });

    test('keeps Latin words and scores mixed-language coverage', () {
      final terms = buildRetrievalTerms('Stars 项目 deadline');

      expect(terms, containsAll({'stars', '项目', 'deadline'}));
      expect(
        retrievalCoverage(terms, 'Stars 项目的 deadline 是九月十日'),
        greaterThan(0.6),
      );
      expect(retrievalCoverage(terms, '午餐喜欢面条'), 0);
    });
  });
}
