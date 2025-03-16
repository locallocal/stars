import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '隐私政策',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: _fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // 防止滚动时背景色变化
        elevation: 0, // 移除阴影
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "泡泡AI聊天助手隐私政策",
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "我们非常重视您的隐私保护，请仔细阅读以下内容：",
              style: TextStyle(fontSize: _fontSize),
            ),
            const SizedBox(height: 16),
            _buildSection(
              "1. 信息收集",
              "我们可能收集您的对话内容、设备信息等数据。这些信息用于提供服务、改进产品和用户体验。您可以选择不提供某些信息，但这可能会影响您使用某些功能。",
              _fontSize,
            ),
            _buildSection(
              "2. 信息使用",
              "收集的信息用于提供服务、改进产品和用户体验。我们可能会使用您的信息来：提供、维护和改进我们的服务；开发新的服务和功能；理解用户如何使用我们的服务；个性化您的体验。",
              _fontSize,
            ),
            _buildSection(
              "3. 信息存储",
              "您的信息将存储在安全的服务器中。我们采取适当的技术和组织措施来保护您的个人信息不被意外或非法破坏、丢失、更改或未经授权的访问。",
              _fontSize,
            ),
            _buildSection(
              "4. 信息共享",
              "除法律要求外，我们不会与第三方共享您的个人信息。在某些情况下，我们可能会共享匿名的、无法识别个人身份的统计数据。",
              _fontSize,
            ),
            _buildSection(
              "5. 信息安全",
              "我们采取多种措施保护您的信息安全，包括加密技术和访问控制。但请注意，互联网传输不可能完全安全，我们无法保证信息传输的绝对安全。",
              _fontSize,
            ),
            _buildSection(
              "6. 儿童隐私",
              "本应用不面向13岁以下儿童。如果我们发现收集了13岁以下儿童的个人信息，我们会采取措施尽快删除这些信息。",
              _fontSize,
            ),
            _buildSection(
              "7. 政策更新",
              "我们可能会更新本隐私政策，请定期查看。当我们对隐私政策做出重大更改时，我们会在应用内通知您。",
              _fontSize,
            ),
            _buildSection(
              "8. 联系我们",
              "如果您对本隐私政策有任何疑问，请通过应用内的反馈功能联系我们。",
              _fontSize,
            ),
            const SizedBox(height: 20),
            Text("最后更新日期：2025年04月01日", style: TextStyle(fontSize: _fontSize)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, double? fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize ?? 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
