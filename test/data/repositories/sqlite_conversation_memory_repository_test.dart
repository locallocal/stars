import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_conversation_memory_repository.dart';
import 'package:stars/data/services/conversation_summary_storage.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/conversation_memory.dart';

void main() {
  sqfliteFfiInit();
  late Database database;
  late Directory root;
  late SqliteConversationMemoryRepository repository;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );
    root = await Directory.systemTemp.createTemp('stars_memory_repository_');
    repository = SqliteConversationMemoryRepository(
      localDatabase: LocalDatabaseService(
        databaseProvider: () async => database,
      ),
      storage: ConversationSummaryStorage(
        documentsDirectoryProvider: () async => root,
      ),
    );
    await database.insert('bots', _botRow('bot_1'));
    await database.insert('chats', _chatRow('chat_1', 'bot_1'));
  });

  tearDown(() async {
    await database.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('commits Markdown metadata and Memory with revision CAS', () async {
    final now = DateTime(2026, 8, 8);
    final summary = ConversationSummaryDocument(
      metadata: ConversationSummaryMetadata(
        id: 'summary_1',
        chatId: 'chat_1',
        fileName: 'summary_1.md',
        contentDigest: '',
        sourceStartMessageId: 'message_1',
        sourceEndMessageId: 'message_2',
        sourceMessageIds: const ['message_1', 'message_2'],
        sourceDigest: 'sources',
        estimatedTokenCount: 30,
        baseRevision: 0,
        createdAt: now,
        updatedAt: now,
      ),
      markdown: '# 会话摘要\n\n## 目标与约束\n\n- 完成实现',
    );
    final item = ConversationMemoryItem(
      id: 'memory_1',
      chatId: 'chat_1',
      memoryKey: 'project.goal',
      kind: ConversationMemoryKind.openTask,
      content: '完成实现',
      sourceMessageIds: const ['message_1'],
      createdAt: now,
      updatedAt: now,
    );

    expect(
      await repository.commitCompaction(
        chatId: 'chat_1',
        expectedRevision: 0,
        summary: summary,
        items: [item],
      ),
      isTrue,
    );
    expect((await repository.getState('chat_1')).revision, 1);
    expect(
      (await repository.getActiveSummary('chat_1'))?.markdown,
      contains('完成实现'),
    );
    expect(await repository.getItems('chat_1'), hasLength(1));
    final rows = await database.query('conversation_summary_segments');
    expect(rows.single.keys, isNot(contains('narrative_summary')));
    expect(rows.single.values, isNot(contains(summary.markdown)));

    final stale = ConversationSummaryDocument(
      metadata: ConversationSummaryMetadata(
        id: 'summary_stale',
        chatId: 'chat_1',
        fileName: 'summary_stale.md',
        contentDigest: '',
        sourceStartMessageId: 'message_1',
        sourceEndMessageId: 'message_2',
        sourceDigest: 'sources',
        baseRevision: 0,
        createdAt: now,
        updatedAt: now,
      ),
      markdown: 'stale',
    );
    expect(
      await repository.commitCompaction(
        chatId: 'chat_1',
        expectedRevision: 0,
        summary: stale,
        items: const [],
      ),
      isFalse,
    );
    expect(
      await File(
        path.join(
          root.path,
          'chats',
          'chat_1',
          'summaries',
          'summary_stale.md',
        ),
      ).exists(),
      isFalse,
    );
  });

  test('current schema includes Memory tables and history index', () async {
    final tables = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tables.map((row) => row['name']),
      containsAll([
        'conversation_memory_state',
        'conversation_summary_segments',
        'conversation_memory_items',
      ]),
    );
    final indexes = await database.rawQuery('PRAGMA index_list(messages)');
    expect(
      indexes.map((row) => row['name']),
      contains('messages_chat_timestamp_message_index'),
    );
  });

  test('persists manager changes and clears only automatic memory', () async {
    final now = DateTime(2026, 8, 8);
    final summary = ConversationSummaryDocument(
      metadata: ConversationSummaryMetadata(
        id: 'summary_manager',
        chatId: 'chat_1',
        fileName: 'summary_manager.md',
        contentDigest: '',
        sourceStartMessageId: 'message_1',
        sourceEndMessageId: 'message_2',
        sourceMessageIds: const ['message_1', 'message_2'],
        sourceDigest: 'manager-sources',
        baseRevision: 0,
        createdAt: now,
        updatedAt: now,
      ),
      markdown: '# 会话摘要\n\n- Manager test',
    );
    ConversationMemoryItem item(
      String id, {
      ConversationMemoryItemState state = ConversationMemoryItemState.active,
    }) => ConversationMemoryItem(
      id: id,
      chatId: 'chat_1',
      memoryKey: 'memory.$id',
      kind: ConversationMemoryKind.fact,
      content: 'Content for $id',
      state: state,
      createdAt: now,
      updatedAt: now,
    );

    expect(
      await repository.commitCompaction(
        chatId: 'chat_1',
        expectedRevision: 0,
        summary: summary,
        items: [
          item('auto_active'),
          item('auto_forgotten', state: ConversationMemoryItemState.forgotten),
        ],
      ),
      isTrue,
    );
    await repository.saveUserItem(
      item('user_pinned', state: ConversationMemoryItemState.pinned),
    );
    await repository.saveUserItem(
      item('user_edited').copyWith(content: 'Edited by the user'),
    );
    await repository.forgetItem('chat_1', 'user_edited');
    expect(
      (await repository.getItems(
        'chat_1',
      )).singleWhere((memory) => memory.id == 'user_edited').state,
      ConversationMemoryItemState.forgotten,
    );
    await repository.restoreItem('chat_1', 'user_edited');
    await repository.setAutoMemoryEnabled('chat_1', false);

    await repository.clearAutomaticMemory('chat_1');

    expect(await repository.getActiveSummary('chat_1'), isNull);
    final state = await repository.getState('chat_1');
    expect(state.revision, 0);
    expect(state.activeSummaryId, isEmpty);
    expect(state.autoMemoryEnabled, isFalse);
    final items = await repository.getItems('chat_1');
    expect(
      {for (final memory in items) memory.id},
      {'auto_forgotten', 'user_pinned', 'user_edited'},
    );
    expect(
      items.singleWhere((memory) => memory.id == 'auto_forgotten').state,
      ConversationMemoryItemState.forgotten,
    );
    expect(
      items.singleWhere((memory) => memory.id == 'user_pinned').state,
      ConversationMemoryItemState.pinned,
    );
    final edited = items.singleWhere((memory) => memory.id == 'user_edited');
    expect(edited.content, 'Edited by the user');
    expect(edited.state, ConversationMemoryItemState.active);
    expect(
      items.every(
        (memory) =>
            memory.id == 'auto_forgotten' ||
            memory.origin == ConversationMemoryOrigin.user,
      ),
      isTrue,
    );
  });

  test('invalidates an active summary whose Markdown digest changed', () async {
    final now = DateTime(2026, 8, 8);
    final summary = ConversationSummaryDocument(
      metadata: ConversationSummaryMetadata(
        id: 'summary_1',
        chatId: 'chat_1',
        fileName: 'summary_1.md',
        contentDigest: '',
        sourceStartMessageId: 'message_1',
        sourceEndMessageId: 'message_2',
        sourceDigest: 'sources',
        baseRevision: 0,
        createdAt: now,
        updatedAt: now,
      ),
      markdown: '# 会话摘要\n\n- valid',
    );
    await repository.commitCompaction(
      chatId: 'chat_1',
      expectedRevision: 0,
      summary: summary,
      items: const [],
    );
    await File(
      path.join(root.path, 'chats', 'chat_1', 'summaries', 'summary_1.md'),
    ).writeAsString('tampered');

    expect(await repository.getActiveSummary('chat_1'), isNull);
    final segments = await database.query('conversation_summary_segments');
    expect(segments.single['status'], 'invalid');
    final state = await repository.getState('chat_1');
    expect(state.activeSummaryId, isEmpty);
    expect(state.compactionStatus, ConversationCompactionStatus.failed);
  });
}

Map<String, Object?> _botRow(String id) => <String, Object?>{
  'id': id,
  'name': 'Bot',
  'avatar': '',
  'provider': 'Provider',
  'base_url': '',
  'api_key': '',
  'api_type': 'openai',
  'model': 'model',
  'system_prompt': '',
  'parameters': '{}',
  'create_timestamp': 1,
  'modify_timestamp': 1,
};

Map<String, Object?> _chatRow(String id, String botId) => <String, Object?>{
  'id': id,
  'bot_id': botId,
  'last_message': '',
  'last_message_timestamp': 1,
  'create_timestamp': 1,
  'modify_timestamp': 1,
};
