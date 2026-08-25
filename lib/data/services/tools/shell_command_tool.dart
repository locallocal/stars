import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:stars/domain/models/models.dart';

enum NativeShellPlatform { windows, macos, linux }

NativeShellPlatform? nativeShellPlatformFor(String operatingSystem) =>
    switch (operatingSystem.toLowerCase()) {
      'windows' => NativeShellPlatform.windows,
      'macos' => NativeShellPlatform.macos,
      'linux' => NativeShellPlatform.linux,
      _ => null,
    };

final class NativeShellInvocation {
  NativeShellInvocation({
    required this.executable,
    required List<String> arguments,
    required this.displayName,
  }) : arguments = List<String>.unmodifiable(arguments);

  final String executable;
  final List<String> arguments;
  final String displayName;
}

final class NativeShellResolver {
  const NativeShellResolver();

  NativeShellInvocation resolve(NativeShellPlatform platform, String command) =>
      switch (platform) {
        NativeShellPlatform.windows => NativeShellInvocation(
          executable: 'powershell.exe',
          arguments: [
            '-NoLogo',
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            command,
          ],
          displayName: 'PowerShell',
        ),
        NativeShellPlatform.macos ||
        NativeShellPlatform.linux => NativeShellInvocation(
          executable: '/bin/sh',
          arguments: ['-c', command],
          displayName: 'POSIX sh',
        ),
      };
}

final class ShellCommandExecutionRequest {
  const ShellCommandExecutionRequest({
    required this.command,
    required this.workingDirectory,
    required this.timeout,
    required this.maxOutputBytesPerStream,
  });

  final String command;
  final String workingDirectory;
  final Duration timeout;
  final int maxOutputBytesPerStream;
}

final class ShellCommandExecutionResult {
  const ShellCommandExecutionResult({
    required this.platform,
    required this.shell,
    required this.workingDirectory,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
    this.timedOut = false,
    this.outputTruncated = false,
  });

  final NativeShellPlatform platform;
  final String shell;
  final String workingDirectory;
  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration duration;
  final bool timedOut;
  final bool outputTruncated;
}

final class ShellCommandExecutionException implements Exception {
  const ShellCommandExecutionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

abstract interface class ShellCommandRunner {
  Future<ShellCommandExecutionResult> run(
    ShellCommandExecutionRequest request,
    AgentCancellationToken cancellationToken,
  );
}

final class LocalShellCommandRunner implements ShellCommandRunner {
  const LocalShellCommandRunner({
    required this.platform,
    this.resolver = const NativeShellResolver(),
    this.streamCloseGrace = const Duration(seconds: 2),
  });

  final NativeShellPlatform platform;
  final NativeShellResolver resolver;
  final Duration streamCloseGrace;

  @override
  Future<ShellCommandExecutionResult> run(
    ShellCommandExecutionRequest request,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final directory = Directory(request.workingDirectory);
    if (!await directory.exists()) {
      throw const ShellCommandExecutionException(
        'shell_working_directory_not_found',
        'The requested working directory does not exist.',
      );
    }
    final invocation = resolver.resolve(platform, request.command);
    final stopwatch = Stopwatch()..start();
    final Process process;
    try {
      process = await Process.start(
        invocation.executable,
        invocation.arguments,
        workingDirectory: directory.absolute.path,
        includeParentEnvironment: true,
        runInShell: false,
      );
    } on ProcessException catch (error) {
      throw ShellCommandExecutionException(
        'shell_process_start_failed',
        'Unable to start ${invocation.displayName}: ${error.message}',
      );
    }

    final stdoutCollector = _LimitedStreamCollector(
      process.stdout,
      request.maxOutputBytesPerStream,
    );
    final stderrCollector = _LimitedStreamCollector(
      process.stderr,
      request.maxOutputBytesPerStream,
    );
    await process.stdin.close();

    final timeoutCompleter = Completer<_ProcessOutcome>();
    final timer = Timer(request.timeout, () {
      if (!timeoutCompleter.isCompleted) {
        timeoutCompleter.complete(const _ProcessOutcome.timedOut());
      }
    });
    final outcome = await Future.any<_ProcessOutcome>([
      process.exitCode.then(_ProcessOutcome.exited),
      timeoutCompleter.future,
      cancellationToken.whenCancelled.then(
        (_) => const _ProcessOutcome.cancelled(),
      ),
    ]);
    timer.cancel();

    var exitCode = outcome.exitCode;
    if (!outcome.exitedNormally) {
      await _terminate(process);
      exitCode = -1;
    }
    final streams = await Future.wait<_LimitedBytes>([
      stdoutCollector.finish(streamCloseGrace),
      stderrCollector.finish(streamCloseGrace),
    ]);
    final stdout = streams[0];
    final stderr = streams[1];
    stopwatch.stop();
    if (outcome.cancelled) throw const AgentRunCancelledException();

    return ShellCommandExecutionResult(
      platform: platform,
      shell: invocation.displayName,
      workingDirectory: directory.absolute.path,
      exitCode: exitCode,
      stdout: utf8.decode(stdout.bytes, allowMalformed: true),
      stderr: utf8.decode(stderr.bytes, allowMalformed: true),
      duration: stopwatch.elapsed,
      timedOut: outcome.timedOut,
      outputTruncated: stdout.truncated || stderr.truncated,
    );
  }

  Future<void> _terminate(Process process) async {
    if (platform == NativeShellPlatform.windows) {
      try {
        await Process.run('taskkill.exe', [
          '/PID',
          '${process.pid}',
          '/T',
          '/F',
        ], runInShell: false).timeout(const Duration(seconds: 1));
      } on Object {
        process.kill();
      }
    } else {
      final descendants = await _descendantProcessIds(process.pid);
      process.kill(ProcessSignal.sigkill);
      _killPids(descendants.reversed, ProcessSignal.sigkill);
    }
    try {
      await process.exitCode.timeout(const Duration(seconds: 1));
    } on TimeoutException {
      if (platform != NativeShellPlatform.windows) {
        process.kill(ProcessSignal.sigkill);
      }
      try {
        await process.exitCode.timeout(const Duration(seconds: 1));
      } on TimeoutException {
        // The output subscriptions are still cancelled below, so the Agent
        // run is not held open by an unresponsive child process.
      }
    }
  }

  Future<List<int>> _descendantProcessIds(int rootPid) async {
    try {
      final result = await Process.run('/bin/ps', const [
        '-eo',
        'pid=,ppid=',
      ], runInShell: false).timeout(const Duration(milliseconds: 500));
      if (result.exitCode != 0) return const [];
      final childrenByParent = <int, List<int>>{};
      for (final line in result.stdout.toString().split('\n')) {
        final columns = line.trim().split(RegExp(r'\s+'));
        if (columns.length != 2) continue;
        final pid = int.tryParse(columns[0]);
        final parentPid = int.tryParse(columns[1]);
        if (pid == null || parentPid == null) continue;
        childrenByParent.putIfAbsent(parentPid, () => []).add(pid);
      }
      final descendants = <int>[];
      final pending = <int>[rootPid];
      while (pending.isNotEmpty) {
        final parentPid = pending.removeLast();
        for (final childPid in childrenByParent[parentPid] ?? const <int>[]) {
          descendants.add(childPid);
          pending.add(childPid);
        }
      }
      return descendants;
    } on Object {
      return const [];
    }
  }

  void _killPids(Iterable<int> pids, ProcessSignal signal) {
    for (final pid in pids) {
      try {
        Process.killPid(pid, signal);
      } on Object {
        // A process may have already exited between the snapshot and signal.
      }
    }
  }
}

final class ShellCommandTool implements ExecutableTool {
  ShellCommandTool({
    required NativeShellPlatform platform,
    ShellCommandRunner? runner,
    String Function()? currentWorkingDirectory,
    this.defaultTimeout = const Duration(seconds: 15),
    this.maxOutputBytesPerStream = 7000,
  }) : _runner = runner ?? LocalShellCommandRunner(platform: platform),
       _currentWorkingDirectory =
           currentWorkingDirectory ?? (() => Directory.current.path);

  static const maxCommandCharacters = 8192;
  static const maxTimeoutSeconds = 25;

  final ShellCommandRunner _runner;
  final String Function() _currentWorkingDirectory;
  final Duration defaultTimeout;
  final int maxOutputBytesPerStream;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: shellCommandToolName,
    title: 'Run shell command',
    description:
        'Run one process-oriented command through the native desktop shell '
        'when no structured built-in tool fits, such as a build, test, '
        'version-control, package-manager, or diagnostic command. Do not use '
        'for ordinary file or directory operations. Requires explicit user '
        'approval. Windows uses PowerShell; macOS and Linux use POSIX sh.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'command': {
          'type': 'string',
          'minLength': 1,
          'maxLength': maxCommandCharacters,
          'description':
              'One coherent command string interpreted by the native shell. '
              'Do not bundle unrelated or independently approval-sensitive '
              'actions.',
        },
        'working_directory': {
          'type': 'string',
          'minLength': 1,
          'maxLength': 4096,
          'description':
              'Optional native directory in which to start the command. Use '
              'it when the command depends on project-relative paths.',
        },
        'timeout_seconds': {
          'type': 'integer',
          'minimum': 1,
          'maximum': maxTimeoutSeconds,
          'description':
              'Optional execution timeout from 1 to 25 seconds; defaults to '
              '15 seconds. Interactive and long-running commands are not '
              'supported.',
        },
      },
      'required': ['command'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'platform': {'type': 'string'},
        'shell': {'type': 'string'},
        'working_directory': {'type': 'string'},
        'exit_code': {'type': 'integer'},
        'stdout': {'type': 'string'},
        'stderr': {'type': 'string'},
        'timed_out': {'type': 'boolean'},
        'output_truncated': {'type': 'boolean'},
        'duration_ms': {'type': 'integer'},
      },
      'required': [
        'platform',
        'shell',
        'working_directory',
        'exit_code',
        'stdout',
        'stderr',
        'timed_out',
        'output_truncated',
        'duration_ms',
      ],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.destructive,
    capabilities: const {
      ToolCapability.process,
      ToolCapability.localRead,
      ToolCapability.localWrite,
      ToolCapability.network,
      ToolCapability.externalRead,
      ToolCapability.externalWrite,
    },
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final command = call.arguments['command']?.toString() ?? '';
    if (command.trim().isEmpty ||
        command.runes.length > maxCommandCharacters ||
        command.contains('\u0000')) {
      return _error(
        call,
        'The shell command is empty or exceeds the allowed size.',
        'invalid_shell_command',
      );
    }
    final requestedDirectory =
        call.arguments['working_directory']?.toString().trim() ?? '';
    final workingDirectory =
        requestedDirectory.isEmpty
            ? _currentWorkingDirectory()
            : requestedDirectory;
    final requestedTimeout = call.arguments['timeout_seconds'];
    final timeoutSeconds =
        requestedTimeout is int ? requestedTimeout : defaultTimeout.inSeconds;
    if (timeoutSeconds < 1 || timeoutSeconds > maxTimeoutSeconds) {
      return _error(
        call,
        'The shell command timeout is outside the allowed range.',
        'invalid_shell_timeout',
      );
    }

    try {
      final result = await _runner.run(
        ShellCommandExecutionRequest(
          command: command,
          workingDirectory: workingDirectory,
          timeout: Duration(seconds: timeoutSeconds),
          maxOutputBytesPerStream: maxOutputBytesPerStream,
        ),
        cancellationToken,
      );
      final structured = <String, Object?>{
        'platform': result.platform.name,
        'shell': result.shell,
        'working_directory': result.workingDirectory,
        'exit_code': result.exitCode,
        'stdout': result.stdout,
        'stderr': result.stderr,
        'timed_out': result.timedOut,
        'output_truncated': result.outputTruncated,
        'duration_ms': result.duration.inMilliseconds,
      };
      final errorCode =
          result.timedOut
              ? 'shell_command_timeout'
              : result.exitCode == 0
              ? ''
              : 'shell_command_failed';
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: _formatResult(result),
        structuredContent: structured,
        isError: errorCode.isNotEmpty,
        errorCode: errorCode,
      );
    } on AgentRunCancelledException {
      rethrow;
    } on ShellCommandExecutionException catch (error) {
      return _error(call, error.message, error.code);
    } on Object {
      return _error(
        call,
        'The shell command could not be executed.',
        'shell_execution_failed',
      );
    }
  }

  String _formatResult(ShellCommandExecutionResult result) {
    final lines = <String>[
      'platform: ${result.platform.name}',
      'shell: ${result.shell}',
      'working_directory: ${result.workingDirectory}',
      'exit_code: ${result.exitCode}',
      'timed_out: ${result.timedOut}',
      'output_truncated: ${result.outputTruncated}',
      if (result.stdout.isNotEmpty) 'stdout:\n${result.stdout}',
      if (result.stderr.isNotEmpty) 'stderr:\n${result.stderr}',
    ];
    return lines.join('\n');
  }

  ToolResult _error(ToolCallRequest call, String message, String code) =>
      ToolResult(
        callId: call.callId,
        name: call.name,
        content: message,
        isError: true,
        errorCode: code,
      );
}

ShellCommandTool? createHostShellCommandTool({
  String? operatingSystem,
  ShellCommandRunner? runner,
}) {
  final platform = nativeShellPlatformFor(
    operatingSystem ?? Platform.operatingSystem,
  );
  if (platform == null) return null;
  return ShellCommandTool(platform: platform, runner: runner);
}

final class _ProcessOutcome {
  const _ProcessOutcome.exited(this.exitCode)
    : timedOut = false,
      cancelled = false;

  const _ProcessOutcome.timedOut()
    : exitCode = -1,
      timedOut = true,
      cancelled = false;

  const _ProcessOutcome.cancelled()
    : exitCode = -1,
      timedOut = false,
      cancelled = true;

  final int exitCode;
  final bool timedOut;
  final bool cancelled;

  bool get exitedNormally => !timedOut && !cancelled;
}

final class _LimitedStreamCollector {
  _LimitedStreamCollector(Stream<List<int>> stream, this.limit) {
    _subscription = stream.listen(
      _add,
      onError: (_) {
        _truncated = true;
        _complete();
      },
      onDone: _complete,
      cancelOnError: true,
    );
  }

  final int limit;
  final BytesBuilder _bytes = BytesBuilder(copy: false);
  final Completer<void> _done = Completer<void>();
  late final StreamSubscription<List<int>> _subscription;
  bool _truncated = false;

  void _add(List<int> chunk) {
    final remaining = limit - _bytes.length;
    if (remaining <= 0) {
      _truncated = true;
    } else if (chunk.length > remaining) {
      _bytes.add(chunk.sublist(0, remaining));
      _truncated = true;
    } else {
      _bytes.add(chunk);
    }
  }

  void _complete() {
    if (!_done.isCompleted) _done.complete();
  }

  Future<_LimitedBytes> finish(Duration grace) async {
    try {
      await _done.future.timeout(grace);
    } on TimeoutException {
      _truncated = true;
      await _subscription.cancel();
      _complete();
    }
    return _LimitedBytes(_bytes.takeBytes(), _truncated);
  }
}

final class _LimitedBytes {
  const _LimitedBytes(this.bytes, this.truncated);

  final Uint8List bytes;
  final bool truncated;
}
