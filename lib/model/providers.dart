import 'package:bubble/model/model.dart';

final providersInfo = {
  'AiHubMix': {
    'api_type': Bot.apiTypeAiHubMix,
    'base_url': 'https://aihubmix.com/v1/',
  },
  'AiMass': {
    'api_type': Bot.apiTypeAiMass,
    'base_url': 'https://platform.wair.ac.cn/maas/v1/',
  },
  'AIStudio': {
    'api_type': Bot.apiTypeGemini,
    'base_url': 'https://generativelanguage.googleapis.com/v1beta/',
  },
  'AlibabaCloud': {
    'api_type': Bot.apiTypeAlibabaCloud,
    'base_url': 'https://dashscope.aliyuncs.com/compatible-mode/v1/',
  },
  'Anthropic': {
    'api_type': Bot.apiTypeAnthropic,
    'base_url': 'https://api.anthropic.com/v1/',
  },
  'BaiChuan': {
    'api_type': Bot.apiTypeBaiChuan,
    'base_url': 'https://api.baichuan-ai.com/v1/',
  },
  'Baidu': {
    'api_type': Bot.apiTypeBaidu,
    'base_url': 'https://qianfan.baidubce.com/v2/',
  },
  'Cerebras': {
    'api_type': Bot.apiTypeCerebras,
    'base_url': 'https://api.cerebras.ai/v1/',
  },
  'ChatGLM': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'http://localhost:8000',
  },
  'Cohere': {
    'api_type': Bot.apiTypeCohere,
    'base_url': 'https://api.cohere.com/v1/',
  },
  'DeepInfra': {
    'api_type': Bot.apiTypeDeepInfra,
    'base_url': 'https://api.deepinfra.com/v1/openai/',
  },
  'DeepSeek': {
    'api_type': Bot.apiTypeDeepseek,
    'base_url': 'https://api.deepseek.com',
  },
  'Fireworks': {
    'api_type': Bot.apiTypeFireworks,
    'base_url': 'https://api.fireworks.ai/',
  },
  'Flux': {
    'api_type': Bot.apiTypeFlux,
    'base_url': 'https://api.us1.bfl.ai/v1/',
  },
  'Gemini': {
    'api_type': Bot.apiTypeGemini,
    'base_url': 'https://generativelanguage.googleapis.com/v1beta/',
  },
  'Grok': {'api_type': Bot.apiTypeGrok, 'base_url': 'https://api.x.ai/v1/'},
  'HuggingFace': {
    'api_type': Bot.apiTypeHuggingface,
    'sub_providers': {
      'Cerebras': {'base_url': 'https://router.huggingface.co/cerebras/v1/'},
      'Cohere': {
        'base_url': 'https://router.huggingface.co/cohere/compatibility/v1/',
      },
      'Fal-AI': {
        'base_url': 'https://router.huggingface.co/fal-ai/fal-ai/whisper',
      },
      'Fireworks-AI': {
        'base_url': 'https://router.huggingface.co/fireworks-ai/inference/v1/',
      },
      'Hyperbolic': {
        'base_url': 'https://router.huggingface.co/hyperbolic/v1/',
      },
      'HF-Inference': {
        'base_url': 'https://router.huggingface.co/hf-inference/',
      },
      'Nebius': {'base_url': 'https://router.huggingface.co/nebius/v1/'},
      'Novita': {'base_url': 'https://router.huggingface.co/novita/v3/openai/'},
      'Replicate': {'base_url': 'https://router.huggingface.co/replicate/v1/'},
      'Sambanova': {'base_url': 'https://router.huggingface.co/sambanova/v1/'},
      'Together': {'base_url': 'https://router.huggingface.co/together/v1/'},
    },
  },
  'InfiniGence': {
    'api_type': Bot.apiTypeInfiniGence,
    'base_url': 'https://cloud.infini-ai.com/maas/v1/',
  },
  'InternLM': {
    'api_type': Bot.apiTypeInternLM,
    'base_url': 'https://chat.intern-ai.org.cn/api/v1/',
  },
  'Jina': {
    'api_type': Bot.apiTypeJina,
    'base_url': 'https://deepsearch.jina.ai/v1/',
  },
  'Kluster': {
    'api_type': Bot.apiTypeKluster,
    'base_url': 'https://api.kluster.ai/v1/',
  },
  'Lambda': {
    'api_type': Bot.apiTypeLambda,
    'base_url': 'https://api.lambda.ai/v1/',
  },
  'MiniMax': {
    'api_type': Bot.apiTypeMiniMax,
    'base_url': 'https://api.minimaxi.chat/v1/',
  },
  'Mistral': {
    'api_type': Bot.apiTypeMistral,
    'base_url': 'https://api.mistral.ai/v1/',
  },
  'ModelScope': {
    'api_type': Bot.apiTypeModelScope,
    'base_urlt': 'https://api-inference.modelscope.cn/v1/',
  },
  'Monica': {
    'api_type': Bot.apiTypeMonica,
    'base_url': 'https://openapi.monica.im/v1/',
  },
  'Moonshot': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.moonshot.cn',
  },
  'Nebius': {
    'api_type': Bot.apiTypeNebius,
    'base_url': 'https://api.studio.nebius.com/v1/',
  },
  'Novita': {
    'api_type': Bot.apiTypeNovita,
    'base_url': 'https://api.novita.ai/v3/openai/v1/',
  },
  'Ollama': {
    'api_type': Bot.apiTypeOllama,
    'base_url': 'http://localhost:11434',
  },
  'OpenAI': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.openai.com/v1/',
    'models': [],
  },
  'OpenRouter': {
    'api_type': Bot.apiTypeOpenRouter,
    'base_url': 'https://openrouter.ai/api',
  },
  'Perplexity': {
    'api_type': Bot.apiTypePerplexity,
    'base_url': 'https://api.perplexity.ai/',
  },
  'PPIO': {
    'api_type': Bot.apiTypePPIO,
    'base_url': 'https://api.ppinfra.com/v3/',
  },
  'SambaNova': {
    'api_type': Bot.apiTypeSambaNova,
    'base_url': 'https://api.sambanova.ai/v1/',
  },
  'Search1Api': {
    'api_type': Bot.apiTypeSearch1Api,
    'base_url': 'https://api.search1api.com/v1/',
  },
  'SenseNova': {
    'api_type': Bot.apiTypeSenseNova,
    'base_url': 'https://api.sensenova.cn/v1/',
  },
  'SiliconFlow': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.siliconflow.cn',
  },
  'Spark': {
    'api_type': Bot.apiTypeSpark,
    'base_url': 'https://spark-api-open.xf-yun.com/v1/',
  },
  'StepFun': {
    'api_type': Bot.apiTypeStepFun,
    'base_url': 'https://api.stepfun.com/v1/',
  },
  'Stability': {
    'api_type': Bot.apiTypeStability,
    'base_url': 'https://api.stability.ai/v2beta/',
  },
  'Tencent': {
    'api_type': Bot.apiTypeTencent,
    'base_url': 'https://api.hunyuan.cloud.tencent.com',
  },
  'TogetherAI': {
    'api_type': Bot.apiTypeTogetherAI,
    'base_url': 'https://api.together.xyz/v1/',
  },
  'VolcanoEngine': {
    'api_type': Bot.apiTypeVolcanoEngine,
    'base_url': 'https://ark.cn-beijing.volces.com/api',
  },
  'XingHe': {
    'api_type': Bot.apiTypeXingHe,
    'base_url': 'https://aistudio.baidu.com/llm/lmapi/v3/',
  },
  "ZeroOneAI": {
    'api_type': Bot.apiTypeZeroOneAI,
    'base_url': 'https://api.lingyiwanwu.com/v1/',
  },
  'ZhiPu': {
    'api_type': Bot.apiTypeZhipu,
    'base_url': 'https://open.bigmodel.cn/api/paas/v4/',
  },
};
