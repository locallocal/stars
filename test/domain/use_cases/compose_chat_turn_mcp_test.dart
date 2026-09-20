import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';

import '../../support/compose_chat_fixtures.dart';

void main() {
  test('exposes only MCP Tools configured for the bot', () async {
    final now = DateTime(2026, 8, 2);
    final server = McpServer(
      id: 'server-1',
      name: 'Docs',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://mcp.example.test'),
      ),
      status: McpConnectionStatus.connected,
      createdAt: now,
      updatedAt: now,
    );
    final tool = McpToolDescriptor(
      serverId: server.id,
      remoteName: 'search',
      title: 'Search',
      description: 'Search documentation',
      inputSchema: const {'type': 'object', 'properties': <String, Object?>{}},
      updatedAt: now,
    );
    final compose = ComposeChatTurn(
      skillRepository: FixtureFakeSkillRepository(const {}),
      bindingRepository: FixtureFakeBindingRepository(const []),
      conversationArtifactsDirectoryProvider:
          fixtureTestConversationArtifactsDirectory,
      mcpServerRepository: FixtureFakeMcpServerRepository(server, [tool]),
    );

    final result = await compose(
      bot: fixtureBot(
        parameters: const {
          Bot.parameterSupportsMcp: true,
          Bot.parameterMcpTools: [
            {
              'server_id': 'server-1',
              'remote_name': 'search',
              'requires_approval': false,
            },
          ],
        },
      ),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Search the docs',
      ),
      currentUserId: 'user-1',
      skillToolProvider: FixtureMcpProvider(),
    );

    expect(result.requestedToolNames, {'mcp.server-1.search'});
    expect(result.approvalExemptToolNames, {'mcp.server-1.search'});

    final unconfiguredResult = await compose(
      bot: fixtureBot(parameters: const {Bot.parameterSupportsMcp: true}),
      history: const [],
      userMessage: fixtureMessage(
        senderId: 'user-1',
        content: 'Search the docs',
      ),
      currentUserId: 'user-1',
      skillToolProvider: FixtureMcpProvider(),
    );

    expect(unconfiguredResult.requestedToolNames, isEmpty);
    expect(unconfiguredResult.approvalExemptToolNames, isEmpty);
  });
}
