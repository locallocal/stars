import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:stars/data/services/mcp/mcp_transport.dart';
import 'package:stars/data/services/mcp/mcp_stdio_environment.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/mcp_configuration_policy.dart';

/// Runs a local MCP server without invoking a shell and exchanges one JSON-RPC
/// message per line over stdin/stdout.
final class McpStdioTransport
    implements McpTransport, McpStdioProcessInfoProvider {
  McpStdioTransport({
    this.requestTimeout = const Duration(seconds: 30),
    this.maxMessageCharacters = 4 * 1024 * 1024,
    DateTime Function()? now,
    Map<String, String>? parentEnvironment,
  }) : _now = now ?? DateTime.now,
       _parentEnvironment = Map.unmodifiable(
         parentEnvironment ?? Platform.environment,
       ),
       assert(maxMessageCharacters > 0);

  final Duration requestTimeout;
  final int maxMessageCharacters;
  final DateTime Function() _now;
  final Map<String, String> _parentEnvironment;
  final Map<String, _McpStdioSession> _sessions = {};

  @override
  McpTransportType get type => McpTransportType.stdio;

  @override
  McpStdioProcessInfo? getProcessInfo(String serverId) {
    final session = _sessions[serverId];
    return session == null || session.isClosed ? null : session.processInfo;
  }

  @override
  Future<McpTransportResponse> send({
    required McpServer server,
    required Map<String, Object?> payload,
    required McpCredential? credential,
    required AgentCancellationToken cancellationToken,
    required String? protocolVersion,
    required String? sessionId,
  }) async {
    if (server.transport is! McpStdioServerTransport) {
      throw ArgumentError.value(
        server.transport,
        'server',
        'A stdio MCP transport requires a stdio server.',
      );
    }
    cancellationToken.throwIfCancelled();
    final session = await _sessionFor(
      server,
      credential,
      allowStart: payload['method'] == 'initialize',
    );
    try {
      final response = await session.send(
        payload,
        cancellationToken: cancellationToken,
        timeout: requestTimeout,
      );
      return McpTransportResponse(payload: response);
    } on TimeoutException catch (error, stackTrace) {
      await close(server.id);
      Error.throwWithStackTrace(
        const McpException(
          'mcp_request_timeout',
          message: 'The MCP stdio request timed out.',
        ),
        stackTrace,
      );
    } on AgentRunCancelledException {
      await close(server.id);
      rethrow;
    } on McpException {
      await close(server.id);
      rethrow;
    } on Object catch (error, stackTrace) {
      await close(server.id);
      Error.throwWithStackTrace(
        const McpException(
          'mcp_stdio_io_error',
          message: 'The MCP stdio process could not be reached.',
        ),
        stackTrace,
      );
    }
  }

  Future<void> close(String serverId) async {
    await _sessions.remove(serverId)?.close();
  }

  Future<void> dispose() async {
    final sessions = _sessions.values.toList(growable: false);
    _sessions.clear();
    await Future.wait(sessions.map((session) => session.close()));
  }

  @override
  Future<void> disconnect({
    required McpServer server,
    required McpCredential? credential,
    required String? protocolVersion,
    required String? sessionId,
  }) => close(server.id);

  Future<_McpStdioSession> _sessionFor(
    McpServer server,
    McpCredential? credential, {
    required bool allowStart,
  }) async {
    final environment = credential?.environment ?? const <String, String>{};
    final fingerprint = _fingerprint(server, environment);
    final existing = _sessions[server.id];
    if (existing != null &&
        !existing.isClosed &&
        existing.fingerprint == fingerprint) {
      return existing;
    }
    await close(server.id);
    if (!allowStart) {
      throw const McpException(
        'mcp_stdio_process_exited',
        message: 'The MCP stdio process is not running. Reconnect the server.',
      );
    }

    final Process process;
    try {
      final configuration = server.transport as McpStdioServerTransport;
      McpConfigurationPolicy.validateTransport(configuration);
      process = await Process.start(
        configuration.command.trim(),
        configuration.arguments,
        environment: mcpStdioEnvironment(
          _parentEnvironment,
          environment,
          caseInsensitive: Platform.isWindows,
        ),
        includeParentEnvironment: false,
        runInShell: false,
      );
    } on ProcessException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        McpException(
          'mcp_stdio_start_failed',
          message: 'Unable to start MCP command: ${error.message}',
        ),
        stackTrace,
      );
    }

    final configuration = server.transport as McpStdioServerTransport;
    late final _McpStdioSession session;
    session = _McpStdioSession(
      process: process,
      fingerprint: fingerprint,
      maxMessageCharacters: maxMessageCharacters,
      processInfo: McpStdioProcessInfo(
        processId: process.pid,
        command: configuration.command.trim(),
        arguments: configuration.arguments,
        startedAt: _now(),
        environmentVariableCount: environment.length,
      ),
      onExited: () {
        if (identical(_sessions[server.id], session)) {
          _sessions.remove(server.id);
        }
      },
    )..listen();
    _sessions[server.id] = session;
    return session;
  }

  String _fingerprint(McpServer server, Map<String, String> environment) {
    final configuration = server.transport as McpStdioServerTransport;
    final sortedEnvironment = environment.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    return jsonEncode({
      'command': configuration.command.trim(),
      'arguments': configuration.arguments,
      'environment': {
        for (final entry in sortedEnvironment) entry.key: entry.value,
      },
    });
  }
}

final class _McpStdioSession {
  _McpStdioSession({
    required this.process,
    required this.fingerprint,
    required this.maxMessageCharacters,
    required this.processInfo,
    required this.onExited,
  });

  final Process process;
  final String fingerprint;
  final int maxMessageCharacters;
  final McpStdioProcessInfo processInfo;
  final void Function() onExited;
  final Map<String, Completer<Map<String, Object?>>> _pending = {};
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  bool _closed = false;

  bool get isClosed => _closed;

  void listen() {
    _stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleLine,
          onError: (Object error, StackTrace stackTrace) {
            _fail(
              const McpException(
                'mcp_stdio_protocol_error',
                message: 'The MCP stdio output stream failed.',
              ),
              stackTrace,
            );
          },
        );
    // stderr is diagnostic-only. Drain it so a noisy child cannot block while
    // keeping credentials and server output out of application logs.
    _stderrSubscription = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen((_) {});
    unawaited(
      process.exitCode.then((exitCode) {
        if (_closed) return;
        _closed = true;
        _fail(
          McpException(
            'mcp_stdio_process_exited',
            message: 'The MCP stdio process exited with code $exitCode.',
          ),
        );
        onExited();
      }),
    );
  }

  Future<Map<String, Object?>?> send(
    Map<String, Object?> payload, {
    required AgentCancellationToken cancellationToken,
    required Duration timeout,
  }) async {
    cancellationToken.throwIfCancelled();
    if (_closed) {
      throw const McpException(
        'mcp_stdio_process_exited',
        message: 'The MCP stdio process is not running.',
      );
    }

    final id = payload['id'];
    Completer<Map<String, Object?>>? completer;
    String? requestKey;
    if (id != null) {
      requestKey = jsonEncode(id);
      if (_pending.containsKey(requestKey)) {
        throw const McpException(
          'mcp_duplicate_request_id',
          message: 'The MCP JSON-RPC request id is already pending.',
        );
      }
      completer = Completer<Map<String, Object?>>();
      _pending[requestKey] = completer;
      unawaited(
        cancellationToken.whenCancelled.then((_) {
          final pending = _pending.remove(requestKey);
          if (pending != null && !pending.isCompleted) {
            pending.completeError(const AgentRunCancelledException());
          }
        }),
      );
    }

    try {
      process.stdin.writeln(jsonEncode(payload));
      await process.stdin.flush();
    } on Object {
      if (requestKey != null) _pending.remove(requestKey);
      rethrow;
    }
    if (completer == null) return null;
    try {
      return await completer.future.timeout(timeout);
    } finally {
      _pending.remove(requestKey);
    }
  }

  void _handleLine(String line) {
    if (_closed || line.trim().isEmpty) return;
    try {
      if (line.length > maxMessageCharacters) {
        throw const FormatException('MCP stdio message exceeds the limit.');
      }
      final decoded = jsonDecode(line);
      if (decoded is! Map) throw const FormatException();
      final response = decoded.map(
        (key, value) => MapEntry(key.toString(), value as Object?),
      );
      final id = response['id'];
      if (id == null) return;
      final completer = _pending.remove(jsonEncode(id));
      if (completer != null && !completer.isCompleted) {
        completer.complete(response);
      }
    } on FormatException catch (error, stackTrace) {
      _closed = true;
      _fail(
        const McpException(
          'mcp_stdio_protocol_error',
          message: 'The MCP stdio server wrote invalid JSON-RPC to stdout.',
        ),
        stackTrace,
      );
      process.kill();
      onExited();
    }
  }

  void _fail(Object error, [StackTrace? stackTrace]) {
    final pending = _pending.values.toList(growable: false);
    _pending.clear();
    for (final completer in pending) {
      if (completer.isCompleted) continue;
      if (stackTrace == null) {
        completer.completeError(error);
      } else {
        completer.completeError(error, stackTrace);
      }
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _fail(
      const McpException(
        'mcp_stdio_process_closed',
        message: 'The MCP stdio process was closed.',
      ),
    );
    try {
      await process.stdin.close();
    } on Object {
      // The child may already have closed its stdin.
    }
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill();
    }
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    onExited();
  }
}
