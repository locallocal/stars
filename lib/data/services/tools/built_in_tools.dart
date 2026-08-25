import 'package:stars/data/services/tools/local_file_system_tools.dart';
import 'package:stars/domain/models/models.dart';

List<ExecutableTool> createBuiltInTools({
  DateTime Function()? now,
  String Function()? currentWorkingDirectory,
}) => [
  CalculatorTool(),
  CurrentTimeTool(now: now),
  ...createLocalFileSystemTools(
    currentWorkingDirectory: currentWorkingDirectory,
  ),
];

final class CalculatorTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'calculate',
    title: 'Calculator',
    description:
        'Perform one basic arithmetic operation on two finite numbers.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'operation': {
          'type': 'string',
          'enum': ['add', 'subtract', 'multiply', 'divide'],
        },
        'left': {'type': 'number'},
        'right': {'type': 'number'},
      },
      'required': ['operation', 'left', 'right'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'result': {'type': 'number'},
      },
      'required': ['result'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.compute},
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final left = call.arguments['left']! as num;
    final right = call.arguments['right']! as num;
    final operation = call.arguments['operation']! as String;
    if (operation == 'divide' && right == 0) {
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'Division by zero is not defined.',
        isError: true,
        errorCode: 'division_by_zero',
      );
    }
    final result = switch (operation) {
      'add' => left + right,
      'subtract' => left - right,
      'multiply' => left * right,
      'divide' => left / right,
      _ => throw StateError('Schema validation accepted an unknown operation.'),
    };
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: '$result',
      structuredContent: {'result': result},
    );
  }
}

final class CurrentTimeTool implements ExecutableTool {
  CurrentTimeTool({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'get_current_time',
    title: 'Current time',
    description:
        'Return the current time, optionally at a requested UTC offset.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'utc_offset_minutes': {
          'type': 'integer',
          'minimum': -840,
          'maximum': 840,
        },
      },
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'iso8601': {'type': 'string'},
        'utc_offset_minutes': {'type': 'integer'},
      },
      'required': ['iso8601', 'utc_offset_minutes'],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.compute},
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();
    final requestedOffset = call.arguments['utc_offset_minutes'];
    final base = _now();
    final offsetMinutes =
        requestedOffset is int
            ? requestedOffset
            : base.timeZoneOffset.inMinutes;
    final adjusted = base.toUtc().add(Duration(minutes: offsetMinutes));
    final iso8601 =
        '${adjusted.toIso8601String().replaceFirst(RegExp(r'Z$'), '')}'
        '${_formatOffset(offsetMinutes)}';
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: iso8601,
      structuredContent: {
        'iso8601': iso8601,
        'utc_offset_minutes': offsetMinutes,
      },
    );
  }

  String _formatOffset(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final absolute = minutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final remainingMinutes = (absolute % 60).toString().padLeft(2, '0');
    return '$sign$hours:$remainingMinutes';
  }
}
