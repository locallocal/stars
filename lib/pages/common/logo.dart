import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget buildProviderLogo(
  BuildContext context,
  String avatar,
  String provider,
  double size,
) {
  if (avatar.isNotEmpty) {
    return Image.file(
      File(avatar),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  final String providerLower = provider.toLowerCase();
  if (providerLower == 'custom' || providerLower == '') {
    return Icon(
      Icons.smart_toy_rounded,
      size: size,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  try {
    return SvgPicture.asset(
      'assets/images/providers/$providerLower.svg',
      width: size,
      height: size,
      placeholderBuilder:
          (context) => Icon(
            Icons.smart_toy_rounded,
            size: size,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  } catch (e) {
    return Image.asset(
      'assets/images/providers/$providerLower.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.smart_toy_rounded,
          size: size,
          color: Theme.of(context).colorScheme.onSurface,
        );
      },
    );
  }
}

// 获取提供商对应的主题色
// 获取提供商对应的主题色
Color getProviderColor(String provider, Color defaultColor) {
  switch (provider.toLowerCase()) {
    case 'openai':
      return const Color(0xFFB8E6D9); // OpenAI 浅绿色
    case 'anthropic':
      return const Color(0xFFF0D9C9); // Anthropic 浅棕色
    case 'gemini':
      return const Color(0xFFBBDEFF); // Gemini 浅蓝色
    case 'deepseek':
      return const Color(0xFFD9CFFF); // DeepSeek 浅紫色
    case 'ollama':
      return const Color(0xFFFFD6D6); // Ollama 浅红色
    case 'huggingface':
      return const Color(0xFFFFF6D6); // HuggingFace 浅黄色
    case 'grok':
      return const Color(0xFFBBE6FF); // Grok 浅蓝色
    case 'openrouter':
      return const Color(0xFFDCD9FF); // OpenRouter 浅紫色
    case 'chatglm':
      return const Color(0xFFCCEFCE); // ChatGLM 浅绿色
    case 'aliyun':
      return const Color(0xFFFFDCC0); // 阿里云 浅橙色
    case 'volcanoengine':
      return const Color(0xFFFFCCCC); // 火山引擎 浅红色
    case 'tencent':
      return const Color(0xFFC9DFFF); // 腾讯 浅蓝色
    case 'siliconflow':
      return const Color(0xFFB3EBEF); // SiliconFlow 浅青色
    case 'baidu':
      return const Color(0xFFC9CBFF); // 百度 浅蓝色
    case 'xinghe':
      return const Color(0xFF7A6AFF); // 星河 紫色
    case 'moonshot':
      return const Color(0xFFE1C4E9); // Moonshot 浅紫色
    case 'zhipu':
      return const Color(0xFFD4F0E2); // 智普 浅绿色
    case 'zerooneai':
    case '01ai':
      return const Color(0xFFE6F0FF); // 零一万物 浅蓝色
    case 'infinigence':
      return const Color(0xFFEBF0DC); // Infinigence 更浅的米色
    case 'ppio':
      return const Color(0xFFE8F5FF); // PPIO 浅蓝色
    case 'stepfun':
      return const Color(0xFFE6F0E0); // Stemfun 浅绿色
    case 'baichuan':
      return const Color(0xFFD6E8FF); // 百川 浅蓝色
    case 'aistudio':
      return const Color(0xFFD4E7FF); // Google AI Studio 浅蓝色
    case 'spark':
      return const Color(0xFFFFE8D9); // 讯飞星火 浅橙色
    case 'sensenova':
      return const Color(0xFFE0F0FF); // 商汤大模型 浅蓝色
    case 'mistral':
      return const Color(0xFFFFF6D6); // Mistral 浅黄色
    default:
      return defaultColor; // 默认颜色
  }
}

// 添加磨砂效果的函数
Color getFrostedProviderColor(
  String provider,
  Color defaultColor, {
  double opacity = 0.7,
}) {
  // 获取基础颜色
  Color baseColor = getProviderColor(provider, defaultColor);

  // 创建磨砂效果（通过调整透明度）
  return baseColor.withOpacity(opacity);
}
