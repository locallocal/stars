import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/shell_command_tool.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('native shell selection', () {
    test('recognizes desktop operating systems only', () {
      expect(nativeShellPlatformFor('windows'), NativeShellPlatform.windows);
      expect(nativeShellPlatformFor('macos'), NativeShellPlatform.macos);
      expect(nativeShellPlatformFor('linux'), NativeShellPlatform.linux);
      expect(nativeShellPlatformFor('android'), isNull);
      expect(nativeShellPlatformFor('ios'), isNull);
    });

    test('uses PowerShell on Windows and POSIX sh elsewhere', () {
      const resolver = NativeShellResolver();

      final windows = resolver.resolve(
        NativeShellPlatform.windows,
        r'Get-ChildItem C:\work',
      );
      expect(windows.executable, 'powershell.exe');
      expect(windows.arguments, [
        '-NoLogo',
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'Get-ChildItem C:\work',
      ]);

      for (final platform in const [
        NativeShellPlatform.macos,
        NativeShellPlatform.linux,
      ]) {
        final invocation = resolver.resolve(platform, 'pwd');
        expect(invocation.executable, '/bin/sh');
        expect(invocation.arguments, ['-c', 'pwd']);
      }
    });
  });

  group('ShellCommandTool', () {
    test('is destructive, process-capable, and always approval-gated', () {
      final tool = ShellCommandTool(
        platform: NativeShellPlatform.linux,
        runner: _FakeShellCommandRunner(),
      );
      final definition = tool.definition;
      final call = ToolCallRequest(
        callId: 'shell-policy',
        name: definition.name,
        arguments: const {'command': 'pwd'},
      );
      final context = ToolPolicyContext(
        runId: 'run-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        requestedToolNames: {definition.name},
      );

      expect(definition.riskLevel, ToolRiskLevel.destructive);
      expect(definition.capabilities, contains(ToolCapability.process));
      expect(definition.description, contains('structured built-in tool'));
      final properties =
          definition.inputSchema['properties']! as Map<String, Object?>;
      for (final schema in properties.values.cast<Map<String, Object?>>()) {
        expect(schema['description'], isNotEmpty);
      }
      expect(
        const DefaultToolPolicy().evaluate(definition, call, context).outcome,
        ToolPolicyOutcome.deny,
      );
      final enabled = const DefaultToolPolicy(
        allowProcessExecution: true,
      ).evaluate(definition, call, context);
      expect(enabled.outcome, ToolPolicyOutcome.requireApproval);
      expect(enabled.reason, 'process_execution_requires_approval');
    });

    test(
      'passes bounded arguments to the runner and returns structured data',
      () async {
        final runner = _FakeShellCommandRunner();
        final tool = ShellCommandTool(
          platform: NativeShellPlatform.windows,
          runner: runner,
          currentWorkingDirectory: () => r'C:\default',
        );

        final result = await tool.execute(
          ToolCallRequest(
            callId: 'shell-1',
            name: tool.definition.name,
            arguments: const {
              'command': 'Get-Location',
              'working_directory': r'C:\workspace',
              'timeout_seconds': 9,
            },
          ),
          AgentCancellationToken(),
        );

        expect(runner.request?.command, 'Get-Location');
        expect(runner.request?.workingDirectory, r'C:\workspace');
        expect(runner.request?.timeout, const Duration(seconds: 9));
        expect(runner.request?.maxOutputBytesPerStream, 7000);
        expect(result.isError, isFalse);
        expect(result.structuredContent, {
          'platform': 'windows',
          'shell': 'PowerShell',
          'working_directory': r'C:\workspace',
          'exit_code': 0,
          'stdout': 'ok\n',
          'stderr': '',
          'timed_out': false,
          'output_truncated': false,
          'duration_ms': 12,
        });
      },
    );

    test('reports timeouts and non-zero exits as tool errors', () async {
      final timeoutTool = ShellCommandTool(
        platform: NativeShellPlatform.linux,
        runner: _FakeShellCommandRunner(timedOut: true),
      );
      final failedTool = ShellCommandTool(
        platform: NativeShellPlatform.linux,
        runner: _FakeShellCommandRunner(exitCode: 7),
      );

      final timeout = await timeoutTool.execute(
        ToolCallRequest(
          callId: 'timeout',
          name: shellCommandToolName,
          arguments: const {'command': 'sleep 100'},
        ),
        AgentCancellationToken(),
      );
      final failed = await failedTool.execute(
        ToolCallRequest(
          callId: 'failed',
          name: shellCommandToolName,
          arguments: const {'command': 'exit 7'},
        ),
        AgentCancellationToken(),
      );

      expect(timeout.isError, isTrue);
      expect(timeout.errorCode, 'shell_command_timeout');
      expect(failed.isError, isTrue);
      expect(failed.errorCode, 'shell_command_failed');
    });
  });

  test(
    'local POSIX runner truncates output and terminates on timeout',
    () async {
      final platform =
          Platform.isMacOS
              ? NativeShellPlatform.macos
              : NativeShellPlatform.linux;
      final runner = LocalShellCommandRunner(platform: platform);
      final directory = await Directory.systemTemp.createTemp(
        'stars-shell-test-',
      );
      try {
        final bounded = await runner.run(
          ShellCommandExecutionRequest(
            command: "printf '123456789'; printf 'abcdef' >&2",
            workingDirectory: directory.path,
            timeout: const Duration(seconds: 2),
            maxOutputBytesPerStream: 4,
          ),
          AgentCancellationToken(),
        );
        expect(bounded.stdout, '1234');
        expect(bounded.stderr, 'abcd');
        expect(bounded.outputTruncated, isTrue);

        final stopwatch = Stopwatch()..start();
        final timedOut = await runner.run(
          ShellCommandExecutionRequest(
            command: 'sleep 2',
            workingDirectory: directory.path,
            timeout: const Duration(milliseconds: 30),
            maxOutputBytesPerStream: 32,
          ),
          AgentCancellationToken(),
        );
        stopwatch.stop();
        expect(timedOut.timedOut, isTrue);
        expect(timedOut.exitCode, -1);
        expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
      } finally {
        await directory.delete(recursive: true);
      }
    },
    skip: !(Platform.isLinux || Platform.isMacOS),
  );
}

final class _FakeShellCommandRunner implements ShellCommandRunner {
  _FakeShellCommandRunner({this.exitCode = 0, this.timedOut = false});

  final int exitCode;
  final bool timedOut;
  ShellCommandExecutionRequest? request;

  @override
  Future<ShellCommandExecutionResult> run(
    ShellCommandExecutionRequest request,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    this.request = request;
    return ShellCommandExecutionResult(
      platform: NativeShellPlatform.windows,
      shell: 'PowerShell',
      workingDirectory: request.workingDirectory,
      exitCode: exitCode,
      stdout: 'ok\n',
      stderr: '',
      duration: const Duration(milliseconds: 12),
      timedOut: timedOut,
    );
  }
}
