import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
  await for (final line in lines) {
    final request = jsonDecode(line) as Map<String, dynamic>;
    final id = request['id'];
    if (id == null) continue;

    final Object result;
    switch (request['method']) {
      case 'initialize':
        result = {
          'protocolVersion': '2025-11-25',
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': 'Fixture stdio MCP', 'version': '1.0.0'},
        };
      case 'tools/list':
        result = {
          'tools': [
            {
              'name': 'echo',
              'title': 'Echo',
              'description': 'Returns fixture process details.',
              'inputSchema': {
                'type': 'object',
                'properties': {
                  'message': {'type': 'string'},
                },
              },
            },
          ],
        };
      case 'tools/call':
        final params = request['params'] as Map<String, dynamic>;
        final toolArguments =
            params['arguments'] as Map<String, dynamic>? ?? const {};
        result = {
          if (toolArguments['inspect_environment'] == true)
            'structuredContent': {'environment': Platform.environment},
          'content': [
            {
              'type': 'text',
              'text':
                  '${toolArguments['message']}|'
                  '${Platform.environment['STARS_MCP_TEST_VALUE']}|'
                  '${arguments.join(',')}',
            },
          ],
        };
      default:
        stdout.writeln(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': -32601, 'message': 'Method not found'},
          }),
        );
        await stdout.flush();
        continue;
    }
    stdout.writeln(jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}));
    await stdout.flush();
  }
}
