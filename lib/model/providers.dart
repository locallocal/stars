import 'package:bubble/model/model.dart';

final providers = [
  'OpenAI',
  'Anthropic',
  'Gemini',
  'DeepSeek',
  'Ollama',
  'HuggingFace',
  'Grok',
  'OpenRouter',
  'ChatGLM',
  'Aliyun',
  'VolcanoEngine',
  'Tencent',
  'SiliconFlow',
  'Baidu',
  'Moonshot',
  'ZhiPu',
  'ZeroOneAI',
];

final modelsByProvider = {
  'OpenAI': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.openai.com/v1',
    'models': [],
  },
  'Anthropic': {
    'api_type': Bot.apiTypeAnthropic,
    'base_url': 'https://api.anthropic.com',
  },
  'Gemini': {
    'api_type': Bot.apiTypeGemini,
    'base_url': 'https://generativelanguage.googleapis.com',
  },
  'DeepSeek': {
    'api_type': Bot.apiTypeDeepseek,
    'base_url': 'https://api.deepseek.com',
  },
  'Ollama': {
    'api_type': Bot.apiTypeOllama,
    'base_url': 'http://localhost:11434',
  },
  'HuggingFace': {
    'api_type': Bot.apiTypeHuggingface,
    'base_url': 'https://api-inference.huggingface.co',
  },
  'Grok': {'api_type': Bot.apiTypeGrok, 'base_url': 'https://api.grok.ai'},
  'OpenRouter': {
    'api_type': Bot.apiTypeOpenRouter,
    'base_url': 'https://openrouter.ai/api',
  },
  'ChatGLM': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'http://localhost:8000',
  },
  'Aliyun': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://dashscope.aliyuncs.com/compatible-mode',
  },
  'VolcanoEngine': {
    'api_type': Bot.apiTypeVolcanoEngine,
    'base_url': 'https://ark.cn-beijing.volces.com/api',
  },
  'Tencent': {
    'api_type': Bot.apiTypeTencent,
    'base_url': 'https://api.hunyuan.cloud.tencent.com',
  },
  'SiliconFlow': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.siliconflow.cn',
  },
  'Baidu': {
    'api_type': Bot.apiTypeBaidu,
    'base_url': 'https://aistudio.baidu.com/llm/lmapi/v3',
  },
  'Moonshot': {
    'api_type': Bot.apiTypeOpenAI,
    'base_url': 'https://api.moonshot.cn',
  },
  'ZhiPu': {
    'api_type': Bot.apiTypeZhipu,
    'base_url': 'https://open.bigmodel.cn',
  },
  "ZeroOneAI": {
    'api_type': Bot.apiTypeZeroOneAI,
    'base_url': 'https://api.lingyiwanwu.com/v1',
  },
};
