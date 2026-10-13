import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/data/repositories/local_conversation_directory_repository.dart';
import 'package:stars/ui/features/chat/view_models/conversation_directory_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_directory_page.dart';

import '../../../../support/widget_test_support.dart';

void main() {
  late Directory root;
  late ConversationDirectoryViewModel model;

  setUp(() {
    root = Directory.systemTemp.createTempSync('stars-directory-actions-');
    File('${root.path}/report.md').writeAsStringSync('original content');
    Directory('${root.path}/notes/nested').createSync(recursive: true);
    File(
      '${root.path}/notes/nested/data.txt',
    ).writeAsStringSync('folder content');
    model = ConversationDirectoryViewModel(
      chatId: 'chat',
      repository: LocalConversationDirectoryRepository(
        directoryProvider: (_) async => root.path,
      ),
    );
  });
  tearDown(() {
    model.dispose();
    root.deleteSync(recursive: true);
  });

  testWidgets('inline entry menus do not open files or navigate folders', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpPage(tester, model);

      for (final name in ['report.md', 'notes']) {
        final row = find.byKey(ValueKey('conversation-directory-$name'));
        final menu = find.byKey(ValueKey('conversation-entry-menu-$name'));
        final rowBounds = tester.getRect(row);
        final menuBounds = tester.getRect(menu);
        expect(rowBounds.contains(menuBounds.topLeft), isTrue);
        expect(rowBounds.contains(menuBounds.bottomRight), isTrue);
        expect(menuBounds.center.dy, closeTo(rowBounds.center.dy, 0.01));
        expect(menuBounds.size, const Size.square(44));
        expect(
          tester.getSemantics(menu),
          matchesSemantics(
            label: '显示菜单: $name',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );

        await tester.tap(menu, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();

        expect(model.directoryPath, root.path);
        expect(
          find.byKey(const ValueKey('message-local-file-dialog')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('conversation-entry-rename')),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('notes'));
      await _settle(tester, model);
      expect(model.directoryPath, '${root.path}/notes');
      expect(find.text('nested'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('entry rows and inline menus are inactive while reloading', (
    tester,
  ) async {
    await _pumpPage(tester, model);
    final reload = model.load();
    await tester.pump();
    expect(model.busy, isTrue);

    await tester.tap(find.text('report.md'), warnIfMissed: false);
    await tester.tap(find.text('notes'), warnIfMissed: false);
    await tester.tap(
      find.byKey(const ValueKey('conversation-entry-menu-report.md')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(model.directoryPath, root.path);
    expect(
      find.byKey(const ValueKey('message-local-file-dialog')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('conversation-entry-rename')),
      findsNothing,
    );

    await _settle(tester, model);
    await reload;
    await _openAction(tester, 'report.md', rename: true);
    expect(
      find.byKey(const ValueKey('conversation-entry-rename-dialog')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renames a file with Enter, preserving extension and updating the list',
    (tester) async {
      await _pumpPage(tester, model);
      await _openAction(tester, 'report.md', rename: true);
      final input = _nameInput();
      final controller = tester.widget<EditableText>(input).controller;
      expect(controller.text, 'report.md');
      expect(controller.selection.textInside(controller.text), 'report');
      await tester.enterText(input, 'revised.md');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _settle(tester, model);
      expect(
        find.byKey(const ValueKey('conversation-entry-rename-dialog')),
        findsNothing,
      );
      expect(File('${root.path}/report.md').existsSync(), isFalse);
      expect(
        File('${root.path}/revised.md').readAsStringSync(),
        'original content',
      );
      expect(find.text('revised.md'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid and duplicate names keep the rename dialog open for correction',
    (tester) async {
      File('${root.path}/taken.md').writeAsStringSync('do not overwrite');
      await _pumpPage(tester, model);
      await _openAction(tester, 'report.md', rename: true);
      await tester.enterText(_nameInput(), '../escape');
      await tester.tap(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('请输入有效名称，不要包含路径分隔符或保留字符。'), findsOneWidget);
      expect(File('${root.path}/report.md').existsSync(), isTrue);

      await tester.enterText(_nameInput(), 'taken.md');
      await tester.tap(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      await _settle(tester, model);
      expect(find.text('已存在同名文件或文件夹。'), findsOneWidget);
      expect(find.byType(ShadAlert), findsOneWidget);
      expect(
        File('${root.path}/taken.md').readAsStringSync(),
        'do not overwrite',
      );

      await tester.enterText(_nameInput(), 'available.md');
      await tester.tap(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      await _settle(tester, model);
      expect(find.text('available.md'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'delete requires confirmation and cancellation preserves a file',
    (tester) async {
      await _pumpPage(tester, model);
      await _openAction(tester, 'report.md', rename: false);
      final dialog = tester.widget<ShadDialog>(
        find.byKey(const ValueKey('conversation-entry-delete-dialog')),
      );
      expect(dialog.variant, ShadDialogVariant.alert);
      expect(find.text('确定永久删除“report.md”吗？此操作无法撤销。'), findsOneWidget);
      expect(File('${root.path}/report.md').existsSync(), isTrue);
      await tester.tap(find.byKey(const ValueKey('conversation-entry-cancel')));
      await tester.pumpAndSettle();
      expect(File('${root.path}/report.md').existsSync(), isTrue);
      expect(_triggerFocus(tester, 'report.md').hasFocus, isFalse);
      await _openAction(tester, 'report.md', rename: false);
      final confirm = tester.widget<ShadButton>(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      expect(confirm.variant, ShadButtonVariant.destructive);
      await tester.tap(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      await _settle(tester, model);
      expect(File('${root.path}/report.md').existsSync(), isFalse);
      expect(find.text('report.md'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opening another entry closes the previous action menu', (
    tester,
  ) async {
    await _pumpPage(tester, model);
    await tester.tap(
      find.byKey(const ValueKey('conversation-entry-menu-report.md')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('conversation-entry-menu-notes')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('conversation-entry-rename')),
      findsOneWidget,
    );
    expect(find.text('重命名文件夹'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('conversation-entry-rename')),
      findsNothing,
    );
  });

  testWidgets('keyboard actions restore focus after cancellation', (
    tester,
  ) async {
    await _pumpPage(tester, model);
    final triggerFocus = _triggerFocus(tester, 'report.md');
    triggerFocus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('conversation-entry-rename-dialog')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('conversation-entry-cancel')));
    await tester.pumpAndSettle();
    expect(triggerFocus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renames and deletes a populated folder while preserving siblings',
    (tester) async {
      await _pumpPage(tester, model);
      await _openAction(tester, 'notes', rename: true);
      expect(find.text('重命名文件夹'), findsOneWidget);
      await tester.enterText(_nameInput(), 'archive');
      await tester.tap(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      await _settle(tester, model);
      expect(
        File('${root.path}/archive/nested/data.txt').readAsStringSync(),
        'folder content',
      );
      await _openAction(tester, 'archive', rename: false);
      expect(find.text('确定永久删除“archive”及其全部内容吗？此操作无法撤销。'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      await _settle(tester, model);
      expect(Directory('${root.path}/archive').existsSync(), isFalse);
      expect(File('${root.path}/report.md').existsSync(), isTrue);
      expect(find.text('archive'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a vanished file shows a safe delete error without closing the listing',
    (tester) async {
      await _pumpPage(tester, model);
      await _openAction(tester, 'report.md', rename: false);
      File('${root.path}/report.md').deleteSync();
      await tester.tap(
        find.byKey(const ValueKey('conversation-entry-confirm')),
      );
      await _settle(tester, model);
      expect(find.text('此文件或文件夹已不存在。'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('conversation-entry-cancel')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('conversation-directory-list')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'entry actions fit narrow screens with large text in $brightness',
      (tester) async {
        await _pumpPage(
          tester,
          model,
          size: const Size(360, 800),
          brightness: brightness,
          textScale: 1.6,
        );
        await _openAction(tester, 'report.md', rename: true);
        expect(
          find
              .byKey(const ValueKey('conversation-entry-confirm'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(
          find.byKey(const ValueKey('conversation-entry-cancel')),
        );
        await tester.pumpAndSettle();
        await _openAction(tester, 'notes', rename: false);
        expect(
          find
              .byKey(const ValueKey('conversation-entry-confirm'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Finder _nameInput() => find.descendant(
  of: find.byKey(const ValueKey('conversation-entry-name')),
  matching: find.byType(EditableText),
);

FocusNode _triggerFocus(WidgetTester tester, String name) =>
    tester
        .widget<ShadIconButton>(
          find.descendant(
            of: find.byKey(ValueKey('conversation-entry-menu-$name')),
            matching: find.byType(ShadIconButton),
          ),
        )
        .focusNode!;

Future<void> _openAction(
  WidgetTester tester,
  String name, {
  required bool rename,
}) async {
  await tester.tap(find.byKey(ValueKey('conversation-entry-menu-$name')));
  await tester.pumpAndSettle();
  final triggerBounds = tester.getRect(
    find.byKey(ValueKey('conversation-entry-menu-$name')),
  );
  final itemBounds = tester.getRect(
    find.byKey(const ValueKey('conversation-entry-rename')),
  );
  expect(itemBounds.right, lessThanOrEqualTo(triggerBounds.left - 12));
  expect(itemBounds.left, greaterThanOrEqualTo(0));
  await tester.tap(
    find.byKey(
      ValueKey(
        rename ? 'conversation-entry-rename' : 'conversation-entry-delete',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPage(
  WidgetTester tester,
  ConversationDirectoryViewModel model, {
  Size size = const Size(1000, 800),
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    shadHarness(
      brightness: brightness,
      homeBuilder:
          (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: ConversationDirectoryPage(viewModel: model)),
          ),
    ),
  );
  await _settle(tester, model);
}

Future<void> _settle(
  WidgetTester tester,
  ConversationDirectoryViewModel model,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (!model.busy) break;
  }
  expect(model.busy, isFalse);
  await tester.pumpAndSettle();
}
