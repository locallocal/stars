import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_context;
import 'package:stars/data/services/tools/local_file_system_tools.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('local directory tools', () {
    late Directory sandbox;
    late ListLocalDirectoryTool listTool;
    late CreateLocalDirectoryTool createTool;
    late DeleteLocalDirectoryTool deleteTool;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('stars-directory-tools-');
      String currentWorkingDirectory() => sandbox.path;
      listTool = ListLocalDirectoryTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
      createTool = CreateLocalDirectoryTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
      deleteTool = DeleteLocalDirectoryTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
    });

    tearDown(() async {
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
    });

    test('creates, lists, and recursively deletes native paths', () async {
      final createResult = await createTool.execute(
        _call(createTool, {'path': 'docs/archive'}),
        AgentCancellationToken(),
      );
      expect(createResult.isError, isFalse);
      _expectValidOutput(createTool, createResult);
      expect(createResult.structuredContent, containsPair('created', true));
      await File(
        path_context.join(sandbox.path, 'docs', 'note.txt'),
      ).writeAsString('hello');

      final listResult = await listTool.execute(
        _call(listTool, {'path': 'docs', 'recursive': true}),
        AgentCancellationToken(),
      );
      expect(listResult.isError, isFalse);
      _expectValidOutput(listTool, listResult);
      final structured = listResult.structuredContent! as Map<String, Object?>;
      final entries = structured['entries']! as List<Object?>;
      expect(structured['truncated'], isFalse);
      expect(
        entries.cast<Map<String, Object?>>().map(
          (entry) => (entry['relative_path'], entry['type']),
        ),
        containsAll([('archive', 'directory'), ('note.txt', 'file')]),
      );

      final safeDeleteResult = await deleteTool.execute(
        _call(deleteTool, {'path': 'docs'}),
        AgentCancellationToken(),
      );
      expect(safeDeleteResult.errorCode, 'directory_not_empty');
      expect(
        await Directory(path_context.join(sandbox.path, 'docs')).exists(),
        isTrue,
      );

      final recursiveDeleteResult = await deleteTool.execute(
        _call(deleteTool, {'path': 'docs', 'recursive': true}),
        AgentCancellationToken(),
      );
      expect(recursiveDeleteResult.isError, isFalse);
      _expectValidOutput(deleteTool, recursiveDeleteResult);
      expect(
        await Directory(path_context.join(sandbox.path, 'docs')).exists(),
        isFalse,
      );
    });

    test('bounds directory listings and reports truncation', () async {
      for (var index = 0; index < 3; index++) {
        await File(
          path_context.join(sandbox.path, '$index.txt'),
        ).writeAsString('$index');
      }

      final result = await listTool.execute(
        _call(listTool, {'path': '.', 'max_entries': 2}),
        AgentCancellationToken(),
      );

      _expectValidOutput(listTool, result);
      final structured = result.structuredContent! as Map<String, Object?>;
      expect((structured['entries']! as List<Object?>), hasLength(2));
      expect(structured['truncated'], isTrue);
    });
  });

  group('local file tools', () {
    late Directory sandbox;
    late WriteLocalFileTool writeTool;
    late ReadLocalFileTool readTool;
    late CopyLocalFileTool copyTool;
    late MoveLocalFileTool moveTool;
    late DeleteLocalFileTool deleteTool;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('stars-file-tools-');
      String currentWorkingDirectory() => sandbox.path;
      writeTool = WriteLocalFileTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
      readTool = ReadLocalFileTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
      copyTool = CopyLocalFileTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
      moveTool = MoveLocalFileTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
      deleteTool = DeleteLocalFileTool(
        currentWorkingDirectory: currentWorkingDirectory,
      );
    });

    tearDown(() async {
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
    });

    test('writes, reads, copies, moves, and deletes a file', () async {
      final writeResult = await writeTool.execute(
        _call(writeTool, {
          'path': 'notes/original.txt',
          'content': 'hello',
          'mode': 'create',
          'create_parents': true,
        }),
        AgentCancellationToken(),
      );
      expect(writeResult.isError, isFalse);
      _expectValidOutput(writeTool, writeResult);

      final appendResult = await writeTool.execute(
        _call(writeTool, {
          'path': 'notes/original.txt',
          'content': ' world',
          'mode': 'append',
        }),
        AgentCancellationToken(),
      );
      _expectValidOutput(writeTool, appendResult);
      expect(appendResult.structuredContent, containsPair('size_bytes', 11));

      final readResult = await readTool.execute(
        _call(readTool, {'path': 'notes/original.txt', 'max_bytes': 5}),
        AgentCancellationToken(),
      );
      _expectValidOutput(readTool, readResult);
      expect(readResult.content, 'hello');
      expect(readResult.structuredContent, containsPair('truncated', true));
      expect(
        readResult.structuredContent,
        containsPair('next_offset_bytes', 5),
      );

      final copyResult = await copyTool.execute(
        _call(copyTool, {
          'source_path': 'notes/original.txt',
          'destination_path': 'copies/copied.txt',
          'create_parents': true,
        }),
        AgentCancellationToken(),
      );
      expect(copyResult.isError, isFalse);
      _expectValidOutput(copyTool, copyResult);
      expect(
        await File(
          path_context.join(sandbox.path, 'copies', 'copied.txt'),
        ).readAsString(),
        'hello world',
      );

      final protectedCopyResult = await copyTool.execute(
        _call(copyTool, {
          'source_path': 'notes/original.txt',
          'destination_path': 'copies/copied.txt',
        }),
        AgentCancellationToken(),
      );
      expect(protectedCopyResult.errorCode, 'file_already_exists');

      final moveResult = await moveTool.execute(
        _call(moveTool, {
          'source_path': 'copies/copied.txt',
          'destination_path': 'moved.txt',
        }),
        AgentCancellationToken(),
      );
      expect(moveResult.isError, isFalse);
      _expectValidOutput(moveTool, moveResult);
      expect(
        await File(
          path_context.join(sandbox.path, 'copies', 'copied.txt'),
        ).exists(),
        isFalse,
      );
      expect(
        await File(path_context.join(sandbox.path, 'moved.txt')).exists(),
        isTrue,
      );

      final deleteResult = await deleteTool.execute(
        _call(deleteTool, {'path': 'moved.txt'}),
        AgentCancellationToken(),
      );
      expect(deleteResult.isError, isFalse);
      _expectValidOutput(deleteTool, deleteResult);
      expect(
        await File(path_context.join(sandbox.path, 'moved.txt')).exists(),
        isFalse,
      );
    });

    test(
      'supports bounded UTF-8 and base64 data without splitting text',
      () async {
        await File(
          path_context.join(sandbox.path, 'unicode.txt'),
        ).writeAsString('你好');

        final textResult = await readTool.execute(
          _call(readTool, {'path': 'unicode.txt', 'max_bytes': 4}),
          AgentCancellationToken(),
        );
        _expectValidOutput(readTool, textResult);
        expect(textResult.content, '你');
        expect(textResult.structuredContent, containsPair('bytes_returned', 3));
        expect(
          textResult.structuredContent,
          containsPair('next_offset_bytes', 3),
        );
        expect(textResult.structuredContent, containsPair('truncated', true));

        final binary = [0, 255, 1, 254];
        final binaryWriteResult = await writeTool.execute(
          _call(writeTool, {
            'path': 'binary.dat',
            'content': base64Encode(binary),
            'encoding': 'base64',
            'mode': 'create',
          }),
          AgentCancellationToken(),
        );
        expect(binaryWriteResult.isError, isFalse);
        _expectValidOutput(writeTool, binaryWriteResult);

        final binaryReadResult = await readTool.execute(
          _call(readTool, {'path': 'binary.dat', 'encoding': 'base64'}),
          AgentCancellationToken(),
        );
        _expectValidOutput(readTool, binaryReadResult);
        expect(binaryReadResult.content, base64Encode(binary));
      },
    );
  });

  test('tool definitions preserve approval boundaries', () {
    final tools = createLocalFileSystemTools();
    final byName = {
      for (final tool in tools) tool.definition.name: tool.definition,
    };
    const validator = JsonSchemaValidator();
    for (final definition in byName.values) {
      expect(validator.supports(definition.inputSchema), isTrue);
      expect(validator.supports(definition.outputSchema!), isTrue);
    }

    expect(byName.keys, containsAll(directoryOperationsToolNames));
    expect(byName.keys, containsAll(fileOperationsToolNames));
    expect(
      byName[listLocalDirectoryToolName]!.riskLevel,
      ToolRiskLevel.readOnly,
    );
    expect(byName[readLocalFileToolName]!.capabilities, {
      ToolCapability.localRead,
    });
    expect(
      byName[createLocalDirectoryToolName]!.riskLevel,
      ToolRiskLevel.write,
    );
    for (final name in {
      deleteLocalDirectoryToolName,
      writeLocalFileToolName,
      copyLocalFileToolName,
      moveLocalFileToolName,
      deleteLocalFileToolName,
    }) {
      expect(byName[name]!.riskLevel, ToolRiskLevel.destructive);
    }

    final readDecision = const DefaultToolPolicy().evaluate(
      byName[readLocalFileToolName]!,
      ToolCallRequest(callId: 'read-approval', name: readLocalFileToolName),
      ToolPolicyContext(
        runId: 'run-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        requestedToolNames: {readLocalFileToolName},
      ),
    );
    expect(readDecision.outcome, ToolPolicyOutcome.requireApproval);
    expect(readDecision.reason, 'local_read_requires_approval');
  });
}

ToolCallRequest _call(ExecutableTool tool, Map<String, Object?> arguments) =>
    ToolCallRequest(
      callId: '${tool.definition.name}-1',
      name: tool.definition.name,
      arguments: arguments,
    );

void _expectValidOutput(ExecutableTool tool, ToolResult result) {
  expect(result.isError, isFalse);
  expect(result.structuredContent, isNotNull);
  expect(
    const JsonSchemaValidator().validate(
      result.structuredContent,
      tool.definition.outputSchema!,
    ),
    isEmpty,
  );
}
