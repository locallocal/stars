import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/tools/built_in_tools.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('built-in registry includes native directory and file tools', () {
    final names = createBuiltInTools().map((tool) => tool.definition.name);

    expect(names, containsAll(directoryOperationsToolNames));
    expect(names, containsAll(fileOperationsToolNames));
  });

  test('calculator returns structured arithmetic output', () async {
    final observedAt = DateTime.utc(2026, 9, 4, 10);
    final tool = CalculatorTool(now: () => observedAt);

    final result = await tool.execute(
      ToolCallRequest(
        callId: 'calculate-1',
        name: tool.definition.name,
        arguments: const {'operation': 'multiply', 'left': 6, 'right': 7},
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isFalse);
    expect(result.content, '42');
    expect(result.structuredContent, containsPair('result', 42));
    expect(result.schemaValid, isTrue);
    expect(result.evidenceKind, EvidenceKind.calculation);
    expect(result.subject, 'calculation:basic-arithmetic');
    expect(result.scope, {'operation': 'multiply', 'left': 6, 'right': 7});
    expect(result.structuredFacts.single.name, 'calculation.result');
    expect(result.structuredFacts.single.value, 42);
    expect(result.observedAt, observedAt);
    expect(result.resultDigest, hasLength(64));
    expect(
      const JsonSchemaValidator().validate(
        result.structuredContent,
        tool.definition.outputSchema!,
      ),
      isEmpty,
    );
  });

  test('calculator rejects division by zero without throwing', () async {
    final tool = CalculatorTool();

    final result = await tool.execute(
      ToolCallRequest(
        callId: 'calculate-2',
        name: tool.definition.name,
        arguments: const {'operation': 'divide', 'left': 1, 'right': 0},
      ),
      AgentCancellationToken(),
    );

    expect(result.isError, isTrue);
    expect(result.errorCode, 'division_by_zero');
  });

  test(
    'current time applies the requested UTC offset deterministically',
    () async {
      final tool = CurrentTimeTool(
        now: () => DateTime.utc(2026, 7, 29, 12, 30),
      );

      final result = await tool.execute(
        ToolCallRequest(
          callId: 'time-1',
          name: tool.definition.name,
          arguments: const {'utc_offset_minutes': 480},
        ),
        AgentCancellationToken(),
      );

      expect(result.content, '2026-07-29T20:30:00.000+08:00');
      expect(result.structuredContent, {
        'iso8601': '2026-07-29T20:30:00.000+08:00',
        'utc_offset_minutes': 480,
      });
      expect(result.schemaValid, isTrue);
      expect(result.observedAt, DateTime.utc(2026, 7, 29, 12, 30));
      expect(result.evidenceKind, isNull);
    },
  );
}
