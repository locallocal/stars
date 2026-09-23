import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/ui/features/chat/views/video_player_widget.dart';

import '../../../../support/widget_test_support.dart';
import '../../../../support/file_preview_test_support.dart';

void main() {
  testWidgets('reply and all file cards first appear in the same frame', (
    tester,
  ) async {
    final first = Completer<bool>(), last = Completer<bool>();
    final repository =
        _FakeMessageActionRepository()
          ..onFileExists =
              (path) => path == '/first.md' ? first.future : last.future;
    final actions = MessageActionViewModel(repository: repository);
    const content = '报告已生成：[first](/first.md) [last](/last.md)';
    final text = find.byWidgetPredicate(
      (widget) => widget is MarkdownBody && widget.data == content,
    );
    final cards = find.byKey(const ValueKey<String>('message-file-results'));
    await _pumpFileMessage(
      tester,
      files: [],
      content: content,
      actions: actions,
    );
    expect(repository.checkedPaths, ['/first.md', '/last.md']);
    expect(text, findsNothing);
    expect(cards, findsNothing);
    expect(
      find.byKey(const ValueKey<String>('message-content-placeholder')),
      findsOneWidget,
    );

    first.complete(true);
    await tester.pump();
    expect(text, findsNothing);
    expect(cards, findsNothing);
    last.complete(true);
    await _expectAppearTogether(tester, text, [
      find.byKey(const ValueKey<String>('message-local-file-/first.md')),
      find.byKey(const ValueKey<String>('message-local-file-/last.md')),
    ]);
    expect(text, findsOneWidget);
    expect(cards, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('message-local-file-/first.md')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('message-local-file-/last.md')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('message-content-placeholder')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a remounted reply shows cached text and files without checking again',
    (tester) async {
      final repository =
          _FakeMessageActionRepository()..onFileExists = (_) async => true;
      final actions = MessageActionViewModel(repository: repository);
      const content = '[报告](/report.md)';
      await _pumpFileMessage(
        tester,
        files: [],
        content: content,
        actions: actions,
      );
      expect(repository.checkedPaths, ['/report.md']);
      await tester.pumpWidget(const SizedBox.shrink());
      // Any accidental second check would leave the remounted reply pending.
      repository.onFileExists = (_) => Completer<bool>().future;
      await _pumpFileMessage(
        tester,
        files: [],
        content: content,
        actions: actions,
      );
      expect(
        find.byKey(const ValueKey<String>('message-content-placeholder')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('message-local-file-/report.md')),
        findsOneWidget,
      );
      expect(repository.checkedPaths, ['/report.md']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'metadata refresh does not recheck files or replace visible cards',
    (tester) async {
      final repository =
          _FakeMessageActionRepository()..onFileExists = (_) async => true;
      final actions = MessageActionViewModel(repository: repository);
      const content = '[报告](/report.md)';
      await _pumpFileMessage(
        tester,
        files: [],
        content: content,
        actions: actions,
      );
      final card = find.byKey(
        const ValueKey<String>('message-local-file-/report.md'),
      );
      final original = tester.element(card);
      await _pumpFileMessage(
        tester,
        files: [],
        content: content,
        actions: actions,
        processInfo: const MessageProcessInfo(durationMs: 900),
      );
      expect(tester.element(card), same(original));
      expect(repository.checkedPaths, ['/report.md']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('streaming publishes new text only with its new file cards', (
    tester,
  ) async {
    final second = Completer<bool>();
    final repository =
        _FakeMessageActionRepository()
          ..onFileExists =
              (path) =>
                  path == '/second.md' ? second.future : Future.value(true);
    final actions = MessageActionViewModel(repository: repository);
    const first = '[first](/first.md)';
    const latest = '$first [second](/second.md)';
    Finder text(String content) => find.byWidgetPredicate(
      (widget) => widget is MarkdownBody && widget.data == content,
    );
    await _pumpFileMessage(
      tester,
      files: [],
      content: first,
      actions: actions,
      isStreaming: true,
    );
    await _pumpFileMessage(
      tester,
      files: [],
      content: latest,
      actions: actions,
      isStreaming: true,
    );
    expect(text(first), findsOneWidget);
    expect(text(latest), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('message-local-file-/second.md')),
      findsNothing,
    );
    second.complete(true);
    await _expectAppearTogether(tester, text(latest), [
      find.byKey(const ValueKey<String>('message-local-file-/second.md')),
    ]);
    expect(text(latest), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('message-local-file-/second.md')),
      findsOneWidget,
    );
    expect(repository.checkedPaths, ['/first.md', '/second.md']);
    expect(tester.takeException(), isNull);
  });

  for (final desktop in [true, false]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'file-only results fit the status area without an empty bubble ($desktop, $brightness)',
        (tester) async {
          const filePath = '/tmp/一份用于验证窄屏和大字体的很长很长的调研报告.html';
          await _pumpFileMessage(
            tester,
            files: const [filePath],
            content: '',
            size: Size(desktop ? 900 : 320, 900),
            isDesktop: desktop,
            brightness: brightness,
            textScaler: const TextScaler.linear(1.8),
            processInfo: const MessageProcessInfo(durationMs: 1200),
          );
          final results = find.byKey(
            const ValueKey<String>('message-file-results'),
          );
          final file = find.byKey(
            const ValueKey<String>('message-local-file-$filePath'),
          );
          final status = find.byType(ProcessInfoSection);
          expect(results, findsOneWidget);
          expect(file.hitTestable(), findsOneWidget);
          expect(
            find.byKey(const ValueKey<String>('message-bubble-surface')),
            findsNothing,
          );
          final resultRect = tester.getRect(results);
          final fileRect = tester.getRect(file);
          final statusRect = tester.getRect(status);
          expect(resultRect.left, closeTo(statusRect.left, 0.01));
          expect(resultRect.width, closeTo(statusRect.width, 0.01));
          expect(statusRect.top, greaterThanOrEqualTo(resultRect.bottom + 12));
          expect(fileRect.left, greaterThanOrEqualTo(resultRect.left));
          expect(fileRect.right, lessThanOrEqualTo(resultRect.right));
          expect(
            resultRect.right,
            lessThanOrEqualTo(tester.view.physicalSize.width),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('user file attachments remain inside their message bubble', (
    tester,
  ) async {
    const filePath = '/tmp/uploaded-report.md';
    await _pumpFileMessage(
      tester,
      files: const [filePath],
      content: '',
      isCurrentUser: true,
    );
    final bubble = find.byKey(const ValueKey<String>('message-bubble-surface'));
    expect(bubble, findsOneWidget);
    expect(
      find.descendant(
        of: bubble,
        matching: find.byKey(
          const ValueKey<String>('message-local-file-$filePath'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('message-file-results')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('file results and execution details fit a narrow message', (
    tester,
  ) async {
    await _pumpFileMessage(
      tester,
      files: const ['/tmp/report.html', '/tmp/report.md'],
      content: '报告已生成。',
      isDesktop: false,
      size: const Size(320, 1200),
      processInfo: const MessageProcessInfo(
        durationMs: 1200,
        toolCalls: [
          MessageToolCall(name: 'write_local_file', status: 'succeeded'),
        ],
      ),
    );
    expect(
      find.byKey(const ValueKey<String>('message-file-results')),
      findsOneWidget,
    );
    expect(find.byType(ProcessInfoSection), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('tool-lifecycle-')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('streaming files stay outside when the reply text appears', (
    tester,
  ) async {
    const filePath = '/tmp/streamed-report.md';
    // The action model, and therefore its cache, belongs to the conversation.
    final actions = MessageActionViewModel(
      repository: _FakeMessageActionRepository(),
    );
    final results = find.byKey(const ValueKey<String>('message-file-results'));
    final bubble = find.byKey(const ValueKey<String>('message-bubble-surface'));
    await _pumpFileMessage(
      tester,
      files: const [filePath],
      content: '',
      isStreaming: true,
      actions: actions,
    );
    expect(results, findsOneWidget);
    expect(bubble, findsNothing);
    final original = tester.element(results);

    await _pumpFileMessage(
      tester,
      files: const [filePath],
      content: '报告已生成。',
      isStreaming: true,
      actions: actions,
    );
    expect(results, findsOneWidget);
    expect(tester.element(results), same(original));
    expect(bubble, findsOneWidget);
    expect(find.descendant(of: bubble, matching: results), findsNothing);
    expect(find.byType(ProcessInfoSection), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kimi003 Markdown result is visible and opens a preview', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-kimi003-markdown-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/Rust学习计划.md');
    file.writeAsStringSync('# Rust 学习计划\n\n正文内容');
    final content = '''
✅ **这次文件真实写入成功了！** 已通过 shell 命令直接验证：

**stat 验证结果：**
- 📁 文件：`${file.path}`
- 📏 大小：**3,883 字节**（125 行）
- 👤 所有者：earthwind，权限 0664
- 🕐 创建时间：2026-08-30 23:52:10
- ✅ 文件开头内容正确：`# Rust 学习计划`

**问题原因说明**：之前我使用的内置文件写入工具返回了"成功"的结果，但实际上文件并未落盘到磁盘（可能是虚拟层或缓存问题），导致我多次错误地向您确认"已写入"。这是我的严重失误，非常抱歉！🙏

这次通过 shell 的 `cat` 写入 + `stat` 直接验证，文件**确定存在**。您可以自己再运行一次确认：

```bash
stat "${file.path}"
cat "${file.path}"
```

学习计划内容完整：五个阶段（12 周），从所有权基础到并发编程，并结合您对 io_uring 的兴趣推荐了系统编程方向。🦀
''';

    await _pumpFileMessage(
      tester,
      files: const [],
      content: content,
      evidence: [filePreviewEvidence(path: file.path)],
    );

    final card = find.byKey(
      ValueKey<String>('message-local-file-${file.path}'),
    );
    expect(card, findsOneWidget);
    expect(card.hitTestable(), findsOneWidget);

    await tester.tap(card);
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('message-local-file-markdown-preview')),
      findsOneWidget,
    );
    expect(find.text('Rust 学习计划'), findsOneWidget);
  });

  testWidgets('Kimi inline Markdown path becomes a deduplicated preview', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-markdown-path-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/spacex_research.md');
    file.writeAsStringSync('# SpaceX 调研简报\n\n正文内容');
    final content = '''
已写入本地文件：

`${file.path}`

[打开调研报告](${file.uri})
''';

    await _pumpFileMessage(tester, files: const [], content: content);

    final card = find.byKey(
      ValueKey<String>('message-local-file-${file.path}'),
    );
    expect(card, findsOneWidget);

    await tester.tap(card);
    await _pumpDialog(tester);
    expect(find.text('SpaceX 调研简报'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('message-local-file-close')),
    );
    await _pumpDialog(tester);

    await tester.tap(find.text('打开调研报告'));
    await _pumpDialog(tester);
    expect(
      find.byKey(const ValueKey<String>('message-local-file-dialog')),
      findsOneWidget,
    );
  });

  testWidgets('local paths inside fenced code are not treated as files', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-code-sample-path-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/sample.txt')
      ..writeAsStringSync('data');

    await _pumpFileMessage(
      tester,
      files: const [],
      content: '```text\n${file.path}\n```',
    );

    expect(
      find.byKey(ValueKey<String>('message-local-file-${file.path}')),
      findsNothing,
    );
  });

  testWidgets('plain text paths produce a shadcn file card and preview', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('stars-plain-path-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/学习报告.md')
      ..writeAsStringSync('# 已完成的报告');

    await _pumpFileMessage(
      tester,
      files: const [],
      content: '已生成：${file.path}，点击文件预览。',
      evidence: [filePreviewEvidence(path: file.path)],
      size: const Size(360, 800),
      isDesktop: false,
      brightness: Brightness.dark,
    );

    final card = find.byKey(
      ValueKey<String>('message-local-file-${file.path}'),
    );
    expect(card, findsOneWidget);
    expect(tester.widget(card), isA<ShadButton>());
    expect(tester.takeException(), isNull);
    await tester.tap(card);
    await _pumpDialog(tester);
    expect(find.byType(ShadDialog), findsOneWidget);
    expect(find.text('已完成的报告'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('relative links resolve in the conversation and deduplicate', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-relative-path-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/报告 final.md')
      ..writeAsStringSync('# 会话报告');
    final actions = MessageActionViewModel(
      repository: _FakeMessageActionRepository(),
      localFilesDirectoryProvider: () async => directory.path,
    );
    await _pumpFileMessage(
      tester,
      files: [file.path],
      content: '[打开报告](<./报告 final.md>)\n\n`${file.path}:12`',
      actions: actions,
    );

    expect(
      find.byKey(ValueKey<String>('message-local-file-${file.path}')),
      findsOneWidget,
    );
    await tester.tap(find.text('打开报告'));
    await _pumpDialog(tester);
    expect(find.text('会话报告'), findsOneWidget);
  });

  for (final desktop in [true, false]) {
    testWidgets(
      'task acknowledgement does not turn an existing filename into a result ($desktop)',
      (tester) async {
        final directory = Directory.systemTemp.createTempSync(
          'stars-ack-file-',
        );
        addTearDown(() => directory.deleteSync(recursive: true));
        final file = File('${directory.path}/登月小说第六章.md')
          ..writeAsStringSync('# 月背回声\n\n第六章正文');
        const content = '好的，我会把《月背回声》第六章正文保存到本地的 登月小说第六章.md，完成后把保存路径和校验结果告诉你。';
        await _pumpFileMessage(
          tester,
          files: const [],
          content: content,
          taskMessageKind: TaskMessageKind.acknowledgement,
          isDesktop: desktop,
          size: Size(desktop ? 900 : 360, 800),
          actions: MessageActionViewModel(
            repository: _FakeMessageActionRepository(),
            localFilesDirectoryProvider: () async => directory.path,
            evidenceRepository: FilePreviewEvidenceRepository([
              filePreviewEvidence(
                path: file.path,
                messageId: 'task-with-local-files:ack',
                observedAt: DateTime(2026, 1, 1, 0, 0, 1),
              ),
            ]),
          ),
        );

        expect(find.textContaining('好的，我会把'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('message-file-results')),
          findsNothing,
        );
        expect(
          find.byKey(ValueKey<String>('message-local-file-${file.path}')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('task results still resolve and preview their local files', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('stars-task-file-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/登月小说第六章.md')
      ..writeAsStringSync('# 月背回声\n\n第六章正文');
    await _pumpFileMessage(
      tester,
      files: const [],
      content: '已将《月背回声》第六章保存到本地的 登月小说第六章.md。',
      taskMessageKind: TaskMessageKind.result,
      actions: MessageActionViewModel(
        repository: _FakeMessageActionRepository(),
        localFilesDirectoryProvider: () async => directory.path,
        evidenceRepository: FilePreviewEvidenceRepository([
          filePreviewEvidence(
            path: file.path,
            messageId: 'task-with-local-files:ack',
          ),
        ]),
      ),
    );

    final card = find.byKey(
      ValueKey<String>('message-local-file-${file.path}'),
    );
    expect(card, findsOneWidget);
    await tester.tap(card);
    await _pumpDialog(tester);
    expect(find.text('月背回声'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing paths and directories do not become result cards', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-missing-path-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/real.txt')..writeAsStringSync('real');
    await _pumpFileMessage(
      tester,
      files: const [],
      content: '${directory.path}/missing.md，${directory.path}，${file.path}',
      evidence: [
        filePreviewEvidence(path: file.path),
        filePreviewEvidence(path: directory.path, id: 'directory'),
        filePreviewEvidence(
          path: '${directory.path}/missing.md',
          id: 'missing',
        ),
      ],
    );
    expect(
      find.byKey(ValueKey<String>('message-local-file-${file.path}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey<String>('message-local-file-${directory.path}')),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey<String>('message-local-file-${directory.path}/missing.md'),
      ),
      findsNothing,
    );
  });

  testWidgets('streamed paths resolve and remain visible after completion', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-streamed-path-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/streamed.txt')
      ..writeAsStringSync('done');
    final card = find.byKey(
      ValueKey<String>('message-local-file-${file.path}'),
    );

    await _pumpFileMessage(
      tester,
      files: const [],
      content: '生成中',
      isStreaming: true,
    );
    expect(card, findsNothing);
    await _pumpFileMessage(
      tester,
      files: const [],
      content: '已生成：[打开文件](${file.uri})',
      isStreaming: true,
    );
    expect(card, findsOneWidget);
    await _pumpFileMessage(
      tester,
      files: const [],
      content: '已生成：[打开文件](${file.uri})。',
    );
    expect(card, findsOneWidget);
    await tester.tap(card);
    await _pumpDialog(tester);
    expect(find.text('done'), findsOneWidget);
  });

  testWidgets('stale discovery cannot restore files from an earlier message', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('stars-stale-path-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/old.txt')..writeAsStringSync('old');
    final pendingDirectory = Completer<String>();
    await _pumpFileMessage(
      tester,
      files: const [],
      content: '[打开文件](old.txt)',
      actions: MessageActionViewModel(
        repository: _FakeMessageActionRepository(),
        localFilesDirectoryProvider: () => pendingDirectory.future,
      ),
    );
    await _pumpFileMessage(tester, files: const [], content: '回复已更新');
    pendingDirectory.complete(directory.path);
    await _finishFileDiscovery(tester);
    expect(
      find.byKey(ValueKey<String>('message-local-file-${file.path}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text file opens in a preview dialog and closes', (tester) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-local-file-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/notes.txt');
    file.writeAsStringSync('A local text artifact');

    await _pumpFileMessage(tester, files: [file.path]);

    final card = find.byKey(
      ValueKey<String>('message-local-file-${file.path}'),
    );
    expect(card, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('message-local-file-text-preview')),
      findsNothing,
    );

    await tester.tap(card);
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('message-local-file-dialog')),
      findsOneWidget,
    );
    expect(find.text('A local text artifact'), findsOneWidget);

    final fileType = find.byKey(
      const ValueKey<String>('message-local-file-type'),
    );
    final fileTitle = find.byKey(
      const ValueKey<String>('message-local-file-title'),
    );
    final fileMetadata = find.byKey(
      const ValueKey<String>('message-local-file-metadata'),
    );
    final filePath = find.byKey(
      const ValueKey<String>('message-local-file-path'),
    );
    expect(fileTitle, findsOneWidget);
    expect(fileMetadata, findsOneWidget);
    expect(fileType, findsOneWidget);
    expect(filePath, findsOneWidget);
    expect(tester.widget<SelectableText>(filePath).maxLines, 1);
    expect(
      tester.getTopLeft(fileMetadata).dx,
      closeTo(tester.getTopLeft(fileTitle).dx, 0.5),
    );
    expect(
      tester.getCenter(filePath).dy,
      closeTo(tester.getCenter(fileType).dy, 0.5),
    );

    final dialog = find.byKey(
      const ValueKey<String>('message-local-file-dialog'),
    );
    final maximize = find.byKey(
      const ValueKey<String>('message-local-file-maximize'),
    );
    final normalConstraints = tester.widget<ShadDialog>(dialog).constraints!;
    expect(normalConstraints.isTight, isTrue);
    expect(normalConstraints.maxWidth, 1040);
    expect(normalConstraints.maxHeight, closeTo(731, 0.001));
    expect(
      find.descendant(
        of: maximize,
        matching: find.byIcon(LucideIcons.maximize2),
      ),
      findsOneWidget,
    );

    await tester.tap(maximize);
    await tester.pump();

    var maximizedDialog = tester.widget<ShadDialog>(dialog);
    expect(maximizedDialog.constraints!.biggest, const Size(1100, 850));
    expect(maximizedDialog.radius, BorderRadius.zero);
    expect(
      find.descendant(
        of: maximize,
        matching: find.byIcon(LucideIcons.minimize2),
      ),
      findsOneWidget,
    );

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pump();
    maximizedDialog = tester.widget<ShadDialog>(dialog);
    expect(maximizedDialog.constraints!.biggest, const Size(1280, 900));

    await tester.tap(maximize);
    await tester.pump();

    final restoredConstraints = tester.widget<ShadDialog>(dialog).constraints!;
    expect(restoredConstraints.maxWidth, 1040);
    expect(restoredConstraints.maxHeight, closeTo(774, 0.001));

    await tester.tap(
      find.byKey(const ValueKey<String>('message-local-file-close')),
    );
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('message-local-file-dialog')),
      findsNothing,
    );
  });

  testWidgets('code files are detected and syntax highlighted', (tester) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-code-file-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final dartFile = File('${directory.path}/main.dart')
      ..writeAsStringSync("void main() { print('hello'); }");
    final pythonFile = File('${directory.path}/worker.py')
      ..writeAsStringSync("def run():\n    return 'ready'");
    final dockerFile = File('${directory.path}/Dockerfile')
      ..writeAsStringSync('FROM scratch');

    await _pumpFileMessage(
      tester,
      files: [dartFile.path, pythonFile.path, dockerFile.path],
    );

    expect(find.text('DART'), findsOneWidget);
    expect(find.text('PYTHON'), findsOneWidget);
    expect(find.text('DOCKERFILE'), findsOneWidget);
    expect(find.byIcon(LucideIcons.fileCode2), findsNWidgets(3));

    await tester.tap(
      find.byKey(ValueKey<String>('message-local-file-${dartFile.path}')),
    );
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('message-local-file-code-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('message-local-file-text-preview')),
      findsNothing,
    );
    expect(find.byType(SelectionArea), findsOneWidget);

    await _pumpUntilSyntaxHighlighted(tester);

    final codeText = tester.widget<Text>(
      find.byKey(const ValueKey<String>('stars-syntax-highlighted-code-text')),
    );
    final codeSpan = codeText.textSpan! as TextSpan;
    expect(codeSpan.toPlainText(), "void main() { print('hello'); }");
    final syntaxColors =
        codeSpan.children!
            .whereType<TextSpan>()
            .map((span) => span.style?.color)
            .whereType<Color>()
            .toSet();
    expect(syntaxColors.length, greaterThan(1));
  });

  testWidgets('markdown and image files use rich in-app previews', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-rich-file-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final markdownFile = File('${directory.path}/report.md');
    markdownFile.writeAsStringSync('# Preview title\n\nReport body');
    const imagePath = 'assets/images/profile/no_bots_v2.png';

    await _pumpFileMessage(tester, files: [markdownFile.path, imagePath]);

    await tester.tap(
      find.byKey(ValueKey<String>('message-local-file-${markdownFile.path}')),
    );
    await _pumpDialog(tester);
    expect(find.byType(Markdown), findsOneWidget);
    expect(find.text('Preview title'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('message-local-file-close-icon')),
    );
    await _pumpDialog(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('message-local-file-$imagePath')),
    );
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('message-local-file-image-preview')),
      findsOneWidget,
    );
  });

  testWidgets('documents open with the system action and video is recognized', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-document-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final pdf = File('${directory.path}/report.pdf');
    final word = File('${directory.path}/draft.docx');
    final video = File('${directory.path}/clip.mp4');
    pdf.writeAsBytesSync(const [0x25, 0x50, 0x44, 0x46]);
    word.writeAsBytesSync(const [0x50, 0x4b]);
    video.writeAsBytesSync(const [0]);
    final repository = _FakeMessageActionRepository();
    final actions = MessageActionViewModel(repository: repository);

    await _pumpFileMessage(
      tester,
      files: [pdf.path, word.path, video.path],
      actions: actions,
    );

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('WORD'), findsOneWidget);
    expect(find.text('VIDEO'), findsOneWidget);

    await tester.tap(
      find.byKey(ValueKey<String>('message-local-file-${pdf.path}')),
    );
    await _pumpDialog(tester);
    expect(find.text('使用系统应用打开'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('message-local-file-open-external')),
    );
    await tester.pump();
    expect(repository.openedFiles, [pdf.path]);

    await tester.tap(
      find.byKey(const ValueKey<String>('message-local-file-close')),
    );
    await _pumpDialog(tester);
    await tester.tap(
      find.byKey(ValueKey<String>('message-local-file-${video.path}')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('message-local-file-video-preview')),
      findsOneWidget,
    );
    expect(find.byType(VideoPlayerWidget), findsOneWidget);
  });

  testWidgets('local HTML keeps a readable fallback and source mode', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync(
      'stars-html-preview-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/report.html');
    const source = '''
<!doctype html>
<html>
  <head>
    <title>Launch dashboard</title>
    <meta name="description" content="A safe local report.">
    <style>body { color: red; }</style>
  </head>
  <body>
    <h1>Weekly report</h1>
    <p>Revenue increased by <strong>12%</strong>.</p>
    <script>window.shouldNotRun = true;</script>
  </body>
</html>
''';
    file.writeAsStringSync(source);

    await _pumpFileMessage(tester, files: [file.path]);

    expect(find.text('HTML'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey<String>('message-local-file-${file.path}')),
    );
    await _pumpDialog(tester);
    await _finishHtmlBackgroundWork(tester);
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('message-local-file-html-preview')),
      findsOneWidget,
    );
    expect(find.text('Launch dashboard'), findsOneWidget);
    expect(find.text('A safe local report.'), findsOneWidget);
    expect(find.textContaining('Revenue increased by 12%.'), findsOneWidget);
    expect(find.textContaining('window.shouldNotRun'), findsNothing);

    await tester.tap(find.text('源代码'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('message-local-html-source')),
      findsOneWidget,
    );
    await _pumpUntilSyntaxHighlighted(tester);
    expect(find.text(source, findRichText: true), findsOneWidget);
  });

  testWidgets('URL previews deduplicate safe links and open from their cards', (
    tester,
  ) async {
    const primaryUrl = 'https://example.com/docs?q=chat#section';
    const secondUrl = 'https://dart.dev/guides';
    final repository = _FakeMessageActionRepository();
    final actions = MessageActionViewModel(repository: repository);
    const content = '''
[OpenAI docs]($primaryUrl)

$primaryUrl

`https://ignored.example/inside-code`

[unsafe](javascript:alert('no'))

$secondUrl.
''';

    await _pumpFileMessage(
      tester,
      files: const [],
      content: content,
      actions: actions,
    );

    final primaryCard = find.byKey(
      const ValueKey<String>('message-url-preview-$primaryUrl'),
    );
    expect(primaryCard, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('message-url-preview-$secondUrl')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>(
          'message-url-preview-https://ignored.example/inside-code',
        ),
      ),
      findsNothing,
    );

    await tester.tap(primaryCard);
    await tester.pump();

    expect(repository.openedLinks, [Uri.parse(primaryUrl)]);
  });

  testWidgets('URL preview stops before Chinese sentence punctuation', (
    tester,
  ) async {
    const url = 'https://tech.dewu.com/article?id=40';
    const content = '使用fetch mcp读取一下这篇文章$url，并给出总结';
    final repository = _FakeMessageActionRepository();
    final actions = MessageActionViewModel(repository: repository);

    await _pumpFileMessage(
      tester,
      files: const [],
      content: content,
      actions: actions,
    );

    final card = find.byKey(const ValueKey<String>('message-url-preview-$url'));
    expect(card, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'message-url-preview-https://tech.dewu.com/'
          'article?id=40%EF%BC%8C%E5%B9%B6%E7%BB%99%E5%87%BA%E6%80%BB%E7%BB%93',
        ),
      ),
      findsNothing,
    );

    await tester.tap(card);
    await tester.pump();

    expect(repository.openedLinks, [Uri.parse(url)]);
  });
}

Future<void> _expectAppearTogether(
  WidgetTester tester,
  Finder text,
  List<Finder> files,
) async {
  for (var frame = 0; frame < 10; frame++) {
    // Discovery continuations may have started in runAsync during mounting.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    final visible = text.evaluate().isNotEmpty;
    for (final file in files) {
      expect(
        file.evaluate().isNotEmpty,
        visible,
        reason:
            'Text and every file card must become visible in the same frame',
      );
    }
    if (visible) return;
  }
  fail('The complete message snapshot did not appear.');
}

Future<void> _pumpFileMessage(
  WidgetTester tester, {
  required List<String> files,
  String content = 'Generated artifacts',
  MessageActionViewModel? actions,
  Size size = const Size(1100, 850),
  bool isDesktop = true,
  Brightness brightness = Brightness.light,
  bool isStreaming = false,
  bool isCurrentUser = false,
  TextScaler textScaler = TextScaler.noScaling,
  MessageProcessInfo processInfo = const MessageProcessInfo(),
  TaskMessageKind? taskMessageKind,
  List<ToolEvidenceRecord> evidence = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final scrollController = ScrollController();
  addTearDown(scrollController.dispose);

  await tester.pumpWidget(
    shadHarness(
      brightness: brightness,
      homeBuilder:
          (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: Scaffold(
              body: Column(
                children: [
                  MessageList(
                    messages: [
                      if (!isStreaming)
                        Message(
                          messageId: switch (taskMessageKind) {
                            TaskMessageKind.acknowledgement =>
                              ConversationMessageIdentity.acknowledgement(
                                'task-with-local-files',
                              ),
                            TaskMessageKind.result =>
                              ConversationMessageIdentity.result(
                                'task-with-local-files',
                              ),
                            TaskMessageKind.directReply =>
                              ConversationMessageIdentity.directReply('turn-1'),
                            TaskMessageKind.status ||
                            null => 'message-with-local-files',
                          },
                          turnId: 'turn-1',
                          taskId: switch (taskMessageKind) {
                            TaskMessageKind.acknowledgement ||
                            TaskMessageKind.result => 'task-with-local-files',
                            _ => null,
                          },
                          taskMessageKind: taskMessageKind,
                          terminalOutcome:
                              taskMessageKind == TaskMessageKind.result
                                  ? MessageTerminalOutcome.completed
                                  : null,
                          chatId: 'chat-1',
                          botId: 'bot-1',
                          senderId: isCurrentUser ? 'user-1' : 'bot-1',
                          content: content,
                          files: files,
                          processInfo: processInfo,
                          timestamp: DateTime(2026),
                        ),
                    ],
                    scrollController: scrollController,
                    isStreaming: isStreaming,
                    streamingResponse: isStreaming ? content : '',
                    streamingFiles: isStreaming ? files : const [],
                    currentUserId: 'user-1',
                    isDesktop: isDesktop,
                    actionViewModel:
                        actions ??
                        MessageActionViewModel(
                          repository: _FakeMessageActionRepository(),
                          evidenceRepository: FilePreviewEvidenceRepository(
                            evidence,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
    ),
  );
  await tester.pumpAndSettle();
  if (isStreaming) await tester.pump(const Duration(milliseconds: 250));
  await _finishFileDiscovery(tester);
}

Future<void> _finishFileDiscovery(WidgetTester tester) async {
  // File I/O runs outside FakeAsync; pump between completions to drain the
  // widget's continuations, including when several references are checked.
  for (var attempt = 0; attempt < 10; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpUntilSyntaxHighlighted(WidgetTester tester) async {
  final codeFinder = find.byKey(
    const ValueKey<String>('stars-syntax-highlighted-code-text'),
  );
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (codeFinder.evaluate().isEmpty) continue;
    final codeText = tester.widget<Text>(codeFinder);
    final codeSpan = codeText.textSpan;
    if (codeSpan is! TextSpan) continue;
    final colors =
        codeSpan.children
            ?.whereType<TextSpan>()
            .map((span) => span.style?.color)
            .whereType<Color>()
            .toSet();
    if (colors != null && colors.length > 1) return;
  }
  fail('Syntax highlighting did not finish.');
}

Future<void> _finishHtmlBackgroundWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1));
}

final class _FakeMessageActionRepository implements MessageActionRepository {
  Future<bool> Function(String)? onFileExists;
  final checkedPaths = <String>[];

  @override
  String? get localFileHomeDirectory => null;

  @override
  Future<bool> localFileExists(String path) {
    checkedPaths.add(path);
    return onFileExists?.call(path) ?? File(path).exists();
  }

  final List<String> openedFiles = [];
  final List<Uri> openedLinks = [];

  @override
  Future<bool> openLocalFile(String path) async {
    openedFiles.add(path);
    return true;
  }

  @override
  Future<bool> openExternal(Uri uri) async {
    openedLinks.add(uri);
    return true;
  }

  @override
  Future<MediaExportResult> saveImage({
    required String sourcePath,
    required String dialogTitle,
  }) async => MediaExportResult.saved;

  @override
  Future<void> shareImage({
    required String sourcePath,
    required String text,
  }) async {}
}
