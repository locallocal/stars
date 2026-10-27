import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/mcp/mcp_stdio_environment.dart';

void main() {
  test(
    'inherits runtime essentials but excludes ambient credentials and hooks',
    () {
      final result = mcpStdioEnvironment(
        {
          'PATH': '/bin',
          'HOME': '/home/user',
          'LANG': 'en_US.UTF-8',
          'OPENAI_API_KEY': 'ambient-secret',
          'AWS_SECRET_ACCESS_KEY': 'aws-secret',
          'GITHUB_TOKEN': 'github-secret',
          'NODE_OPTIONS': '--require=untrusted',
          'LD_PRELOAD': 'untrusted.so',
          'STARS_MCP_TEST_VALUE': 'ambient',
        },
        {'STARS_MCP_TEST_VALUE': 'explicit', 'API_KEY': 'user-approved'},
      );
      expect(result, {
        'PATH': '/bin',
        'HOME': '/home/user',
        'LANG': 'en_US.UTF-8',
        'STARS_MCP_TEST_VALUE': 'explicit',
        'API_KEY': 'user-approved',
      });
    },
  );
  test(
    'Windows explicit variables override mixed-case inherited variables',
    () {
      expect(
        mcpStdioEnvironment(
          {'Path': 'parent', 'SystemRoot': 'C:\\Windows'},
          {'PATH': 'explicit'},
          caseInsensitive: true,
        ),
        {'PATH': 'explicit', 'SystemRoot': 'C:\\Windows'},
      );
    },
  );
  test('POSIX variables retain their case-sensitive names', () {
    expect(
      mcpStdioEnvironment(
        {'PATH': '/bin', 'path': 'ignored'},
        {'path': 'explicit'},
      ),
      {'PATH': '/bin', 'path': 'explicit'},
    );
  });
}
