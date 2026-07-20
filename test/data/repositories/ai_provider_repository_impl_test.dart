import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/ai_provider_repository_impl.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('AiProviderRepositoryImpl', () {
    const repository = AiProviderRepositoryImpl();

    test('creates a provider for every supported API type', () {
      const supportedApiTypes = <String>[
        Bot.apiTypeOpenAI,
        Bot.apiTypeOllama,
        Bot.apiTypeDeepseek,
        Bot.apiTypeGemini,
        Bot.apiTypeGrok,
        Bot.apiTypeHuggingface,
        Bot.apiTypeAnthropic,
        Bot.apiTypeVolcanoEngine,
        Bot.apiTypeTencent,
        Bot.apiTypeOpenRouter,
        Bot.apiTypeBaidu,
        Bot.apiTypeXingHe,
        Bot.apiTypeZhipu,
        Bot.apiTypeZeroOneAI,
        Bot.apiTypeInfiniGence,
        Bot.apiTypePPIO,
        Bot.apiTypeStepFun,
        Bot.apiTypeBaiChuan,
        Bot.apiTypeSpark,
        Bot.apiTypeSenseNova,
        Bot.apiTypeMistral,
        Bot.apiTypeStability,
        Bot.apiTypeFireworks,
        Bot.apiTypeFlux,
        Bot.apiTypeKluster,
        Bot.apiTypeInternLM,
        Bot.apiTypeJina,
        Bot.apiTypeLambda,
        Bot.apiTypeAiHubMix,
        Bot.apiTypeAiMass,
        Bot.apiTypeDeepInfra,
        Bot.apiTypeCerebras,
        Bot.apiTypeCohere,
        Bot.apiTypeMiniMax,
        Bot.apiTypeModelScope,
        Bot.apiTypeMonica,
        Bot.apiTypeNebius,
        Bot.apiTypeNovita,
        Bot.apiTypeSearch1Api,
        Bot.apiTypeSambaNova,
        Bot.apiTypePerplexity,
        Bot.apiTypeTogetherAI,
        Bot.apiTypeAlibabaCloud,
        Bot.apiTypeMoonshot,
      ];

      for (final apiType in supportedApiTypes) {
        final bot = _bot(apiType);

        expect(repository.create(bot).bot, same(bot), reason: apiType);
      }
    });

    test('rejects an unsupported API type', () {
      expect(
        () => repository.create(_bot(Bot.apiTypeAzure)),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains(Bot.apiTypeAzure),
          ),
        ),
      );
    });
  });
}

Bot _bot(String apiType) => Bot(
  id: 'bot-$apiType',
  name: apiType,
  avatar: '',
  provider: apiType,
  baseURL: 'https://example.invalid',
  apiKey: 'test-key',
  apiType: apiType,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
  modifyTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
);
