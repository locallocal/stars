import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/message_file_snapshot.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/use_cases/resolve_message_local_files.dart';
import 'package:stars/domain/use_cases/conversation_message_file_cache.dart';
import 'package:stars/ui/features/chat/view_models/message_file_presentation_view_model.dart';

void main() {
  test(
    'conversation caches isolate directories and survive page replacement',
    () async {
      final repository = _Files((_) async => true);
      final cache = ConversationMessageFileCache(
        createResolver:
            (id) => ResolveMessageLocalFiles(
              repository: repository,
              directoryProvider: () async => '/$id',
            ),
      );
      MessageFileRequest request(String chat) => MessageFileRequest(
        content: '[report](report.md)',
        files: [],
        message: _message(chatId: chat),
      );
      final a = await cache.forChat('a').resolve(request('a'));
      final b = await cache.forChat('b').resolve(request('b'));
      expect(a.files, ['/a/report.md']);
      expect(b.files, ['/b/report.md']);
      expect(cache.forChat('a').cached(request('a')), same(a));
      cache.remove('b');
      expect(cache.forChat('a').cached(request('a')), same(a));
      expect(cache.forChat('b').cached(request('b')), isNull);
      expect(repository.checked, ['/a/report.md', '/b/report.md']);
    },
  );

  test(
    'clearing a conversation discards completed and in-flight cache entries',
    () async {
      final pending = Completer<bool>();
      final repository = _Files((_) => pending.future);
      final cache = ConversationMessageFileCache(
        createResolver: (_) => ResolveMessageLocalFiles(repository: repository),
      );
      final resolver = cache.forChat('chat');
      final request = MessageFileRequest(
        content: '[report](/report.md)',
        files: [],
        message: _message(),
      );
      final old = resolver.resolve(request);
      await _flush();
      resolver.clear();
      pending.complete(true);
      await old;
      expect(resolver.cached(request), isNull);
      await cache.forChat('chat').resolve(request);
      expect(repository.checked, ['/report.md', '/report.md']);
      expect(resolver.cached(request), isNotNull);
      cache.clear();
      expect(resolver.cached(request), isNull);
      expect(cache.forChat('chat').cached(request), isNull);
    },
  );

  test('publishes text and every file together after the last check', () async {
    final slow = Completer<bool>();
    final repository = _Files(
      (path) => path == '/slow.md' ? slow.future : Future.value(true),
    );
    final resolver = ResolveMessageLocalFiles(repository: repository);
    final model = MessageFilePresentationViewModel(resolver);
    addTearDown(model.dispose);
    const content = '[fast](/fast.md) [slow](/slow.md)';
    _update(model, content);
    await _flush();
    expect(repository.checked, ['/fast.md', '/slow.md']);
    expect(model.snapshot, isNull);

    slow.complete(true);
    await _flush();
    expect(model.snapshot!.content, content);
    expect(model.snapshot!.files, ['/fast.md', '/slow.md']);
    expect(() => model.snapshot!.files.clear(), throwsUnsupportedError);
  });

  test(
    'remounted messages synchronously reuse their complete snapshot',
    () async {
      final repository = _Files((_) async => true);
      var directories = 0;
      final resolver = ResolveMessageLocalFiles(
        repository: repository,
        directoryProvider: () async {
          directories++;
          return '/chat';
        },
      );
      final model = MessageFilePresentationViewModel(resolver);
      _update(model, '[report](report.md)');
      await _flush();
      final snapshot = model.snapshot;
      expect(snapshot, isNotNull);
      model.dispose();

      final remounted = MessageFilePresentationViewModel(resolver);
      addTearDown(remounted.dispose);
      _update(remounted, '[report](report.md)');
      expect(remounted.snapshot, same(snapshot));
      await _flush();
      expect(repository.checked, ['/chat/report.md']);
      expect(directories, 1);
    },
  );

  test(
    'caches empty results without a TTL or repeated existence checks',
    () async {
      var exists = false;
      final repository = _Files((_) async => exists);
      final resolver = ResolveMessageLocalFiles(repository: repository);
      final request = MessageFileRequest(
        content: '[missing](/missing.md)',
        files: [],
        message: _message(),
      );
      final snapshot = await resolver.resolve(request);
      exists = true;
      final rebuilt = MessageFileRequest(
        content: request.content,
        files: [],
        message: _message(),
      );
      expect(resolver.cached(rebuilt), same(snapshot));
      expect((await resolver.resolve(rebuilt)).files, isEmpty);
      expect(repository.checked, ['/missing.md']);
    },
  );

  test('coalesces concurrent requests for the same message revision', () async {
    final gate = Completer<bool>();
    final repository = _Files((_) => gate.future);
    final resolver = ResolveMessageLocalFiles(repository: repository);
    MessageFileRequest request() => MessageFileRequest(
      content: '[report](/report.md)',
      files: [],
      message: _message(),
    );
    final first = resolver.resolve(request());
    final second = resolver.resolve(request());
    expect(second, same(first));
    await _flush();
    expect(repository.checked, ['/report.md']);
    gate.complete(true);
    expect(await second, same(await first));
  });

  test('content and evidence scope changes invalidate the snapshot', () async {
    final repository = _Files((_) async => true);
    final resolver = ResolveMessageLocalFiles(repository: repository);
    Future<MessageFileSnapshot> read(String text, Message message) =>
        resolver.resolve(
          MessageFileRequest(content: text, files: [], message: message),
        );
    await read('[old](/old.md)', _message());
    await read('[new](/new.md)', _message());
    await read('[new](/new.md)', _message(chatId: 'another-chat'));
    await read('[new](/new.md)', _message(timestamp: DateTime(2026, 2)));
    expect(repository.checked, ['/old.md', '/new.md', '/new.md', '/new.md']);
  });

  test(
    'late results cannot replace a rewritten message or its cache',
    () async {
      final old = Completer<bool>();
      final repository = _Files(
        (path) => path == '/old.md' ? old.future : Future.value(true),
      );
      final resolver = ResolveMessageLocalFiles(repository: repository);
      final model = MessageFilePresentationViewModel(resolver);
      addTearDown(model.dispose);
      _update(model, '[old](/old.md)');
      await _flush();
      _update(model, '[new](/new.md)');
      await _flush();
      final latest = model.snapshot;
      old.complete(true);
      await _flush();
      expect(model.snapshot, same(latest));
      expect(latest!.files, ['/new.md']);
      expect(
        resolver.cached(
          MessageFileRequest(
            content: '[new](/new.md)',
            files: [],
            message: _message(),
          ),
        ),
        same(latest),
      );
    },
  );

  test(
    'streaming retains complete text and files while checking later tokens',
    () async {
      final first = Completer<bool>(), second = Completer<bool>();
      final repository = _Files(
        (path) => path == '/first.md' ? first.future : second.future,
      );
      final model = MessageFilePresentationViewModel(
        ResolveMessageLocalFiles(repository: repository),
      );
      addTearDown(model.dispose);
      const initial = '[first](/first.md)';
      const latest = '$initial [second](/second.md) latest tokens';
      void stream(String text) => model.update(
        content: text,
        files: [],
        sourceMessage: null,
        isCurrentUser: false,
      );
      stream(initial);
      await _flush();
      stream('$initial [second]');
      stream(latest);
      first.complete(true);
      await _flush();
      expect(model.snapshot!.content, initial);
      expect(model.snapshot!.files, ['/first.md']);
      expect(repository.checked, ['/first.md', '/second.md']);

      second.complete(true);
      await _flush();
      expect(model.snapshot!.content, latest);
      expect(model.snapshot!.files, ['/first.md', '/second.md']);
      expect(repository.checked, hasLength(2));
    },
  );

  test('user attachments display immediately without discovery', () {
    final repository = _Files((_) async => true);
    final model = MessageFilePresentationViewModel(
      ResolveMessageLocalFiles(repository: repository),
    );
    addTearDown(model.dispose);
    model.update(
      content: 'Upload',
      files: ['/file.md'],
      sourceMessage: _message(),
      isCurrentUser: true,
    );
    expect(model.snapshot!.content, 'Upload');
    expect(model.snapshot!.files, ['/file.md']);
    expect(repository.checked, isEmpty);
  });

  test(
    'completed replies immediately reuse fully resolved streaming links',
    () async {
      final repository = _Files((_) async => true);
      final resolver = ResolveMessageLocalFiles(repository: repository);
      const content = '[report](/report.md)';
      final streamed = await resolver.resolve(
        MessageFileRequest(content: content, files: []),
      );
      final model = MessageFilePresentationViewModel(resolver);
      addTearDown(model.dispose);
      _update(model, content);
      expect(model.snapshot, same(streamed));
      expect(repository.checked, ['/report.md']);
      // A later turn must not displace the completed message's cached snapshot.
      await resolver.resolve(
        MessageFileRequest(content: 'Next turn', files: []),
      );
      expect(
        resolver.cached(
          MessageFileRequest(content: content, files: [], message: _message()),
        ),
        same(streamed),
      );
    },
  );

  test(
    'streaming misses and prose cannot bypass final message checks',
    () async {
      var exists = false;
      final repository = _Files((_) async => exists);
      final resolver = ResolveMessageLocalFiles(repository: repository);
      const content = '[report](/report.md)';
      await resolver.resolve(MessageFileRequest(content: content, files: []));
      final completed = MessageFileRequest(
        content: content,
        files: [],
        message: _message(),
      );
      expect(resolver.cached(completed), isNull);
      exists = true;
      expect((await resolver.resolve(completed)).files, ['/report.md']);
      expect(repository.checked, ['/report.md', '/report.md']);
      await resolver.resolve(
        MessageFileRequest(content: '/prose.md', files: []),
      );
      expect(
        resolver.cached(
          MessageFileRequest(
            content: '/prose.md',
            files: [],
            message: _message(),
          ),
        ),
        isNull,
      );
    },
  );

  test(
    'disposal ignores pending UI work but retains the shared cache',
    () async {
      final gate = Completer<bool>();
      final resolver = ResolveMessageLocalFiles(
        repository: _Files((_) => gate.future),
      );
      final model = MessageFilePresentationViewModel(resolver);
      var notifications = 0;
      model.addListener(() => notifications++);
      _update(model, '[report](/report.md)');
      await _flush();
      model.dispose();
      final before = notifications;
      gate.complete(true);
      await _flush();
      expect(notifications, before);
      expect(
        resolver
            .cached(
              MessageFileRequest(
                content: '[report](/report.md)',
                files: [],
                message: _message(),
              ),
            )!
            .files,
        ['/report.md'],
      );
    },
  );
}

void _update(MessageFilePresentationViewModel model, String content) =>
    model.update(
      content: content,
      files: [],
      sourceMessage: _message(),
      isCurrentUser: false,
    );

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Message _message({String chatId = 'chat', DateTime? timestamp}) => Message(
  messageId: 'reply',
  chatId: chatId,
  botId: 'bot',
  senderId: 'bot',
  content: '',
  timestamp: timestamp ?? DateTime(2026),
);

final class _Files implements MessageActionRepository {
  _Files(this.check);
  final Future<bool> Function(String) check;
  final checked = <String>[];
  @override
  String? get localFileHomeDirectory => null;
  @override
  Future<bool> localFileExists(String path) {
    checked.add(path);
    return check(path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
