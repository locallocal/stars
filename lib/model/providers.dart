import 'package:bubble/model/model.dart';

final providers = [
  'AIStudio',
  'Aliyun',
  'Anthropic',
  'BaiChuan',
  'Baidu',
  'ChatGLM',
  'DeepSeek',
  'Gemini',
  'Grok',
  'HuggingFace',
  'InfiniGence',
  'Mistral',
  'Moonshot',
  'Ollama',
  'OpenAI',
  'OpenRouter',
  'PPIO',
  'SiliconFlow',
  'SenseNova',
  'Spark',
  'StepFun',
  'Tencent',
  'VolcanoEngine',
  'XingHe',
  'ZeroOneAI',
  'ZhiPu',
];

final modelsByProvider = {
  'AIStudio': {
    'api_type': Bot.apiTypeGemini,
    'base_url': 'https://generativelanguage.googleapis.com/v1beta/openai/',
  },
  'Aliyun': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://dashscope.aliyuncs.com/compatible-mode',
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
  'ChatGLM': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'http://localhost:8000',
  },
  'DeepSeek': {
    'api_type': Bot.apiTypeDeepseek,
    'base_url': 'https://api.deepseek.com',
  },
  'Gemini': {
    'api_type': Bot.apiTypeGemini,
    'base_url': 'https://generativelanguage.googleapis.com/v1beta/openai/',
  },
  'Grok': {'api_type': Bot.apiTypeGrok, 'base_url': 'https://api.grok.ai'},
  'HuggingFace': {
    'api_type': Bot.apiTypeHuggingface,
    'base_url': 'https://api-inference.huggingface.co',
  },
  'InfiniGence': {
    'api_type': Bot.apiTypeInfiniGence,
    'base_url': 'https://cloud.infini-ai.com/maas/v1/',
  },
  'Mistral': {
    'api_type': Bot.apiTypeMistral,
    'base_url': 'https://api.mistral.ai/v1/',
  },
  'Moonshot': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.moonshot.cn',
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
  'PPIO': {
    'api_type': Bot.apiTypePPIO,
    'base_url': 'https://api.ppinfra.com/v3/',
  },
  'SiliconFlow': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.siliconflow.cn',
  },
  'SenseNova': {
    'api_type': Bot.apiTypeSenseNova,
    'base_url': 'https://api.sensenova.cn/v1/',
  },
  'Spark': {
    'api_type': Bot.apiTypeSpark,
    'base_url': 'https://spark-api-open.xf-yun.com/v1/',
  },
  'StepFun': {
    'api_type': Bot.apiTypeStepFun,
    'base_url': 'https://api.stepfun.com/v1/',
  },
  'Tencent': {
    'api_type': Bot.apiTypeTencent,
    'base_url': 'https://api.hunyuan.cloud.tencent.com',
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
    'base_url': 'https://open.bigmodel.cn',
  },
};
