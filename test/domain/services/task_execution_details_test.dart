import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/services/task_execution_details.dart';

void main() {
  test('arguments remain valid JSON and retain multiline commands', () {
    final arguments = {
      'command': "printf 'hello\\n'\nflutter test",
      'working_directory': '/workspace/project with spaces',
      'headers': {'authorization': 'secret-value'},
    };
    final safe =
        jsonDecode(taskExecutionArguments(jsonEncode(arguments))) as Map;
    expect(safe['command'], arguments['command']);
    expect(safe['working_directory'], arguments['working_directory']);
    expect(safe['headers'], {'authorization': '[redacted]'});
  });

  test('structured output keeps useful results and removes nested secrets', () {
    final output = taskExecutionOutput(
      jsonEncode({
        'count': 42,
        'settings': {'password': 'secret-value'},
        'reasoning': 'private reasoning',
      }),
    );
    expect(output, contains('42'));
    expect(output, isNot(contains('secret-value')));
    expect(output, isNot(contains('private reasoning')));
    expect(taskExecutionOutput(output), output);
  });

  test('output sanitization happens before truncation and is idempotent', () {
    final output = taskExecutionOutput(
      'first line\n${'x' * 31980}\npassword=${'secret' * 100}\nlast line',
    );
    expect(output.length, lessThanOrEqualTo(32000));
    expect(output, startsWith('first line\n'));
    expect(output, endsWith('… [truncated]'));
    expect(output, isNot(contains('secret')));
    expect(taskExecutionOutput(output), output);
    expect(
      taskExecutionOutput('password\u0000=private-value'),
      'password=[redacted]',
    );
  });
}
