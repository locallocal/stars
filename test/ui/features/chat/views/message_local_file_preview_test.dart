import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'package:stars/ui/features/chat/views/video_player_widget.dart';

import '../../../../support/widget_test_support.dart';

void main() {
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

    await _pumpFileMessage(tester, files: const [], content: content);

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

    await tester.tap(
      find.byKey(const ValueKey<String>('message-local-file-close')),
    );
    await _pumpDialog(tester);

    expect(
      find.byKey(const ValueKey<String>('message-local-file-dialog')),
      findsNothing,
    );
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
}

Future<void> _pumpFileMessage(
  WidgetTester tester, {
  required List<String> files,
  String content = 'Generated artifacts',
  MessageActionViewModel? actions,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1100, 850);
  addTearDown(tester.view.reset);
  final scrollController = ScrollController();
  addTearDown(scrollController.dispose);

  await tester.pumpWidget(
    shadHarness(
      brightness: Brightness.light,
      homeBuilder:
          (context) => Scaffold(
            body: Column(
              children: [
                MessageList(
                  messages: [
                    Message(
                      messageId: 'message-with-local-files',
                      chatId: 'chat-1',
                      botId: 'bot-1',
                      senderId: 'bot-1',
                      content: content,
                      files: files,
                      timestamp: DateTime(2026),
                    ),
                  ],
                  scrollController: scrollController,
                  isStreaming: false,
                  streamingResponse: '',
                  currentUserId: 'user-1',
                  isDesktop: true,
                  actionViewModel: actions,
                ),
              ],
            ),
          ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

final class _FakeMessageActionRepository implements MessageActionRepository {
  final List<String> openedFiles = [];

  @override
  Future<bool> openLocalFile(String path) async {
    openedFiles.add(path);
    return true;
  }

  @override
  Future<bool> openExternal(Uri uri) async => true;

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
