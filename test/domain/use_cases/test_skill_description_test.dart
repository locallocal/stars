import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/stars_system_prompt.dart';
import 'package:stars/domain/use_cases/test_skill_description.dart';

void main() {
  test('runs should-trigger and should-not-trigger cases repeatedly', () async {
    final provider = _DescriptionProvider();
    final report = await const TestSkillDescription(
      starsSystemPromptProvider: _testStarsSystemPrompt,
      starsSystemPromptLanguageProvider: _japaneseLanguage,
    )(
      provider: provider,
      skill: _skill,
      cases: const [
        SkillDescriptionTestCase(
          input: 'Write release notes',
          shouldActivate: true,
        ),
        SkillDescriptionTestCase(
          input: 'Calculate 2 + 2',
          shouldActivate: false,
        ),
      ],
      runsPerCase: 3,
    );

    expect(report.results.map((result) => result.activations), [3, 0]);
    expect(report.passed, isTrue);
    expect(provider.closedSessions, 6);
    expect(provider.requests, hasLength(6));
    expect(
      provider.requests.every(
        (request) => request.messages.first.content.startsWith(
          '<stars_application_context>',
        ),
      ),
      isTrue,
    );
    expect(
      provider.requests.first.messages.first.content,
      contains('Use activate_skill only when the available Skill is relevant.'),
    );
    expect(
      provider.requests.first.messages.first.content,
      contains('選択中の表示言語: 日本語'),
    );
  });

  test('rejects legacy providers instead of text-marker fallback', () async {
    await expectLater(
      const TestSkillDescription()(
        provider: _LegacyProvider(),
        skill: _skill,
        cases: const [
          SkillDescriptionTestCase(input: 'test', shouldActivate: true),
        ],
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });
}

final class _DescriptionProvider extends AiProvider {
  _DescriptionProvider() : super(_bot);

  var closedSessions = 0;
  final requests = <SkillToolSessionRequest>[];

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  SkillToolSession openSkillToolSession(SkillToolSessionRequest request) {
    requests.add(request);
    final shouldActivate = request.messages.last.content.contains('release');
    return _DescriptionSession(
      shouldActivate: shouldActivate,
      onClose: () => closedSessions += 1,
    );
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _LegacyProvider extends AiProvider {
  _LegacyProvider() : super(_bot);

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _DescriptionSession implements SkillToolSession {
  const _DescriptionSession({
    required this.shouldActivate,
    required this.onClose,
  });

  final bool shouldActivate;
  final void Function() onClose;

  @override
  Future<SkillToolTurn> start() async => SkillToolTurn(
    calls:
        shouldActivate
            ? [
              SkillToolCall(
                callId: 'call',
                name: 'activate_skill',
                arguments: const {'name': 'release-notes'},
              ),
            ]
            : const [],
    isComplete: !shouldActivate,
  );

  @override
  Future<SkillToolTurn> continueWith(List<SkillToolResult> results) async =>
      SkillToolTurn(isComplete: true);

  @override
  void close() => onClose();
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

final _skill = SkillDescriptor(
  id: 'user:release-notes',
  name: 'release-notes',
  description: 'Prepare release notes when the user asks for release notes.',
  version: '1.0.0',
  scope: SkillScope.user,
  sourceUri: 'file:///release-notes',
  rootPath: '/skills/release-notes',
  contentDigest: 'digest',
  trustState: SkillTrustState.userReviewed,
  validationStatus: SkillValidationStatus.valid,
  compatibility: '',
  installedAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

String _testStarsSystemPrompt(String languageCode) => buildStarsSystemPrompt(
  operatingSystem: 'TestOS',
  operatingSystemVersion: '1.2.3',
  languageCode: languageCode,
);

Future<String> _japaneseLanguage() async => 'ja_JP';
