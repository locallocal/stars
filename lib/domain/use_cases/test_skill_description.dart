import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';

final class TestSkillDescription {
  const TestSkillDescription({
    StarsSystemPromptProvider starsSystemPromptProvider =
        currentStarsSystemPrompt,
    StarsSystemPromptLanguageProvider starsSystemPromptLanguageProvider =
        starsSystemPromptLanguageByDefault,
  }) : _starsSystemPromptProvider = starsSystemPromptProvider,
       _starsSystemPromptLanguageProvider = starsSystemPromptLanguageProvider;

  final StarsSystemPromptProvider _starsSystemPromptProvider;
  final StarsSystemPromptLanguageProvider _starsSystemPromptLanguageProvider;

  Future<SkillDescriptionTestReport> call({
    required AiProvider provider,
    required SkillDescriptor skill,
    required List<SkillDescriptionTestCase> cases,
    int runsPerCase = 3,
  }) async {
    if (!provider.capabilities.supportsAutomaticSkillActivation) {
      throw UnsupportedError('当前 Provider 不支持结构化 Skill 自动激活。');
    }
    if (cases.isEmpty) {
      throw ArgumentError.value(
        cases,
        'cases',
        'At least one case is required.',
      );
    }
    if (runsPerCase < 1 || runsPerCase > 10) {
      throw RangeError.range(runsPerCase, 1, 10, 'runsPerCase');
    }
    final applicationPromptLanguage =
        await _starsSystemPromptLanguageProvider();

    final catalog = [
      SkillCatalogEntry(
        id: skill.id,
        name: skill.name,
        description: skill.description,
        contentDigest: skill.contentDigest,
        priority: 0,
      ),
    ];
    final results = <SkillDescriptionTestResult>[];
    for (final testCase in cases) {
      var activations = 0;
      for (var run = 0; run < runsPerCase; run++) {
        final session = provider.openSkillToolSession(
          SkillToolSessionRequest(
            messages: [
              ChatMessage(
                role: 'system',
                content: prependStarsSystemPrompt(
                  'Use activate_skill only when the available Skill is relevant.',
                  languageCode: applicationPromptLanguage,
                  starsSystemPromptProvider: _starsSystemPromptProvider,
                ),
              ),
              ChatMessage(role: 'user', content: testCase.input),
            ],
            catalog: catalog,
          ),
        );
        try {
          final turn = await session.start();
          if (turn.calls.any(
            (call) =>
                call.name == 'activate_skill' &&
                call.arguments['name'] == skill.name,
          )) {
            activations += 1;
          }
        } finally {
          session.close();
        }
      }
      results.add(
        SkillDescriptionTestResult(
          testCase: testCase,
          runs: runsPerCase,
          activations: activations,
        ),
      );
    }
    return SkillDescriptionTestReport(skill: skill, results: results);
  }
}
