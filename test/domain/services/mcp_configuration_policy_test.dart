import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/mcp.dart';
import 'package:stars/domain/services/mcp_configuration_policy.dart';

void main() {
  final blocked = <McpServerTransport>[
    for (final query in [
      'api_key=secret',
      'access_token=secret',
      'token=secret',
      'x-api-key=secret',
      '%61pi%5Fkey=secret',
      'AWS_ACCESS_KEY_ID=secret',
    ])
      McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/mcp?$query'),
      ),
    for (final arguments in [
      ['--api-key', 'secret'],
      ['--token=secret'],
      ['PASSWORD=secret'],
      ['--header', 'Authorization: Bearer secret'],
      ['https://example.com/mcp?%61pi_key=secret'],
      ['--client-secret', 'secret'],
    ])
      McpStdioServerTransport(command: 'npx', arguments: arguments),
    McpStdioServerTransport(command: 'API_KEY=secret npx'),
  ];
  for (var index = 0; index < blocked.length; index++) {
    test(
      'rejects credential-bearing configuration $index without echoing it',
      () {
        expect(
          () => McpConfigurationPolicy.validateTransport(blocked[index]),
          throwsA(
            isA<McpException>()
                .having(
                  (e) => e.code,
                  'code',
                  'mcp_credentials_in_configuration',
                )
                .having(
                  (e) => e.toString(),
                  'safe message',
                  isNot(contains('=secret')),
                ),
          ),
        );
      },
    );
  }
  test('allows ordinary query parameters, package names, and file paths', () {
    McpConfigurationPolicy.validateTransport(
      McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/mcp?region=eu&mode=read_only'),
      ),
    );
    McpConfigurationPolicy.validateTransport(
      McpStdioServerTransport(
        command: 'npx',
        arguments: ['-y', '@example/mcp', '/workspace', '--port', '8080'],
      ),
    );
  });
}
