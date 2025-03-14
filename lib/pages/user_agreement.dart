import 'package:flutter/material.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '用户协议',
          style: TextStyle(fontWeight: FontWeight.bold),
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
            const Text(
              "泡泡AI聊天助手用户协议",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "欢迎使用泡泡AI聊天助手！请仔细阅读以下条款，使用本应用即表示您同意以下全部条款：",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSection(
              "1. 服务说明",
              "泡泡AI聊天助手提供基于人工智能的对话服务，旨在为用户提供信息和娱乐。本应用可能会根据服务需要进行更新或调整功能。",
            ),
            _buildSection(
              "2. 用户责任",
              "用户应当遵守中国法律法规，不得利用本应用从事违法活动。用户对自己在使用本应用过程中的行为及其结果承担全部责任。",
            ),
            _buildSection(
              "3. 内容规范",
              "用户不得发布违法、色情、暴力等不良信息。我们保留对违规内容进行删除的权利，并可能视情况对违规用户采取限制使用等措施。",
            ),
            _buildSection(
              "4. 知识产权",
              "本应用的所有权利归泡泡团队所有。未经授权，用户不得对本应用进行复制、修改、传播或用于商业用途。用户通过本应用发布的内容，用户保留其著作权，但授予我们使用、复制、修改、发布的权利。",
            ),
            _buildSection(
              "5. 免责声明",
              "本应用不对AI生成的内容准确性负责。我们尽力确保服务的连续性和安全性，但不对因不可抗力、网络问题等导致的服务中断或数据丢失承担责任。",
            ),
            _buildSection(
              "6. 协议修改",
              "我们保留随时修改本协议的权利。修改后的协议将在本应用内公布，继续使用本应用即表示您接受修改后的协议。",
            ),
            _buildSection("7. 终止服务", "我们保留因用户违反协议或其他原因终止向用户提供服务的权利。"),
            const SizedBox(height: 20),
            Text(
              "最后更新日期：2025年04月01日",
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
