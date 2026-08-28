import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/features/bots/views/add_bot.dart';
import 'package:stars/ui/features/bots/views/edit_bot.dart';
import 'package:stars/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('existing bot enables an MCP Tool without confirmation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Bot? saved;
    await tester.pumpWidget(
      _editHarness(
        bot: _bot(supportsMcp: true),
        includeSecondServer: true,
        includeSecondTool: true,
        onSaved: (bot) async => saved = bot,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('add-bot-mcp-server')));
    await tester.pumpAndSettle();
    final serverSearch = find.descendant(
      of: find.byKey(const ValueKey<String>('bot-mcp-server-search')),
      matching: find.byType(EditableText),
    );
    expect(serverSearch, findsOneWidget);
    await tester.enterText(serverSearch, 'Analytics');
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('available-bot-mcp-server-server-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('available-bot-mcp-server-server-2')),
      findsOneWidget,
    );
    await tester.enterText(serverSearch, 'missing server');
    await tester.pump();
    expect(find.text('未找到匹配的 MCP 服务器'), findsOneWidget);
    final emptyServerSearch = find.byKey(
      const ValueKey<String>('bot-mcp-server-search-empty'),
    );
    expect(emptyServerSearch, findsOneWidget);
    expect(
      tester.widget<Padding>(emptyServerSearch).padding,
      const EdgeInsets.symmetric(vertical: 20),
    );
    expect(
      find.descendant(of: emptyServerSearch, matching: find.byType(TextButton)),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('clear-bot-mcp-server-search')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('available-bot-mcp-server-server-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('available-bot-mcp-server-server-2')),
      findsOneWidget,
    );
    final availableServer = find.byKey(
      const ValueKey<String>('available-bot-mcp-server-server-1'),
    );
    _expectPrimaryTextColor(
      tester,
      find.descendant(of: availableServer, matching: find.text('Docs')),
    );
    expect(
      find.descendant(
        of: availableServer,
        matching: find.byIcon(Icons.hub_outlined),
      ),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('select-bot-mcp-server-server-1')),
    );
    await tester.pumpAndSettle();
    final selectedServer = find.byKey(
      const ValueKey<String>('bot-mcp-server-server-1'),
    );
    _expectPrimaryTextColor(
      tester,
      find.descendant(of: selectedServer, matching: find.text('Docs')),
    );
    expect(
      find.descendant(
        of: selectedServer,
        matching: find.byIcon(Icons.hub_outlined),
      ),
      findsNothing,
    );
    await tester.ensureVisible(selectedServer);
    await tester.tap(selectedServer);
    await tester.pumpAndSettle();
    _expectPrimaryTextColor(
      tester,
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('bot-mcp-tools-dialog-server-1'),
        ),
        matching: find.text('Docs'),
      ),
    );

    final toolSearch = find.descendant(
      of: find.byKey(const ValueKey<String>('bot-mcp-tool-search-server-1')),
      matching: find.byType(EditableText),
    );
    expect(toolSearch, findsOneWidget);
    await tester.enterText(toolSearch, 'Fetch');
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-search')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-fetch')),
      findsOneWidget,
    );

    await tester.enterText(toolSearch, 'missing tool');
    await tester.pump();
    expect(find.text('未找到匹配的工具'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('clear-bot-mcp-tool-search-server-1')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-fetch')),
      findsOneWidget,
    );

    final toolToggle = find.byKey(
      const ValueKey<String>('bot-mcp-tool-toggle-server-1-search'),
    );
    final noApprovalToggle = find.byKey(
      const ValueKey<String>('bot-mcp-tool-no-approval-server-1-search'),
    );
    final toolRow = find.byKey(
      const ValueKey<String>('bot-mcp-tool-server-1-search'),
    );
    _expectPrimaryTextColor(
      tester,
      find.descendant(of: toolRow, matching: find.text('Search')),
    );
    final toolDescription = find.byKey(
      const ValueKey<String>('bot-mcp-tool-description-server-1-search'),
    );
    final toolControls = find.byKey(
      const ValueKey<String>('bot-mcp-tool-controls-server-1-search'),
    );
    final disabledStatus = find.descendant(
      of: toolRow,
      matching: find.text('已关闭'),
    );
    await tester.ensureVisible(toolToggle);
    expect(tester.widget<Switch>(toolToggle).value, isFalse);
    expect(disabledStatus, findsOneWidget);
    expect(
      (tester.getCenter(toolToggle).dy - tester.getCenter(noApprovalToggle).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      tester.getRect(toolToggle).right,
      lessThan(tester.getRect(noApprovalToggle).left),
    );
    expect(
      (tester.getCenter(toolDescription).dy - tester.getCenter(toolControls).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      tester.getRect(toolDescription).right,
      lessThan(tester.getRect(toolControls).left),
    );
    await tester.tap(toolToggle);
    await tester.pump();

    expect(
      find.descendant(of: toolRow, matching: find.text('已开启')),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(noApprovalToggle).value, isFalse);
    await tester.tap(noApprovalToggle);
    await tester.pump();

    await tester.tap(find.text('关闭').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('保存修改'));
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(saved?.configuredSupportsMcp, isTrue);
    expect(saved?.mcpServerIds, {'server-1'});
    expect(saved?.mcpTools, {
      McpToolConfiguration(
        serverId: 'server-1',
        remoteName: 'search',
        requiresApproval: false,
      ),
    });
  });

  testWidgets('existing bot can disable a configured MCP Tool', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Bot? saved;
    await tester.pumpWidget(
      _editHarness(
        bot: _bot(
          supportsMcp: true,
          tools: {
            McpToolConfiguration(serverId: 'server-1', remoteName: 'search'),
          },
        ),
        onSaved: (bot) async => saved = bot,
      ),
    );
    await tester.pumpAndSettle();

    final selectedServer = find.byKey(
      const ValueKey<String>('bot-mcp-server-server-1'),
    );
    expect(
      find.descendant(
        of: selectedServer,
        matching: find.byIcon(Icons.hub_outlined),
      ),
      findsNothing,
    );
    await tester.ensureVisible(selectedServer);
    await tester.tap(selectedServer);
    await tester.pumpAndSettle();

    final toolToggle = find.byKey(
      const ValueKey<String>('bot-mcp-tool-toggle-server-1-search'),
    );
    await tester.ensureVisible(toolToggle);
    expect(tester.widget<Switch>(toolToggle).value, isTrue);
    await tester.tap(toolToggle);
    await tester.pump();

    await tester.tap(find.text('关闭').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('保存修改'));
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(saved?.mcpTools, isEmpty);
    expect(saved?.mcpServerIds, {'server-1'});
  });

  testWidgets('existing bot can update all MCP Tool settings at once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Bot? saved;
    await tester.pumpWidget(
      _editHarness(
        bot: _bot(supportsMcp: true, serverIds: const {'server-1'}),
        includeSecondTool: true,
        onSaved: (bot) async => saved = bot,
      ),
    );
    await tester.pumpAndSettle();

    final selectedServer = find.byKey(
      const ValueKey<String>('bot-mcp-server-server-1'),
    );
    await tester.ensureVisible(selectedServer);
    await tester.tap(selectedServer);
    await tester.pumpAndSettle();

    final toggleAll = find.byKey(
      const ValueKey<String>('bot-mcp-tools-toggle-all-server-1'),
    );
    final toggleAllNoApproval = find.byKey(
      const ValueKey<String>('bot-mcp-tools-no-approval-all-server-1'),
    );
    expect(find.text('全部开启工具'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(toggleAllNoApproval).onPressed,
      isNull,
    );

    await tester.tap(toggleAll);
    await tester.pump();
    expect(find.text('全部关闭工具'), findsOneWidget);
    for (final remoteName in ['search', 'fetch']) {
      expect(
        tester
            .widget<Switch>(
              find.byKey(
                ValueKey<String>('bot-mcp-tool-toggle-server-1-$remoteName'),
              ),
            )
            .value,
        isTrue,
      );
    }

    await tester.tap(toggleAllNoApproval);
    await tester.pump();
    expect(find.text('全部关闭免确认'), findsOneWidget);
    for (final remoteName in ['search', 'fetch']) {
      expect(
        tester
            .widget<Switch>(
              find.byKey(
                ValueKey<String>(
                  'bot-mcp-tool-no-approval-server-1-$remoteName',
                ),
              ),
            )
            .value,
        isTrue,
      );
    }

    await tester.tap(toggleAllNoApproval);
    await tester.pump();
    expect(find.text('全部开启免确认'), findsOneWidget);

    await tester.tap(toggleAll);
    await tester.pump();
    expect(find.text('全部开启工具'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(toggleAllNoApproval).onPressed,
      isNull,
    );

    await tester.tap(toggleAll);
    await tester.pump();
    await tester.tap(toggleAllNoApproval);
    await tester.pump();

    await tester.tap(find.text('关闭').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存修改'));
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(saved?.mcpTools, {
      McpToolConfiguration(
        serverId: 'server-1',
        remoteName: 'search',
        requiresApproval: false,
      ),
      McpToolConfiguration(
        serverId: 'server-1',
        remoteName: 'fetch',
        requiresApproval: false,
      ),
    });
  });

  testWidgets('existing bot removes an MCP Server and its Tool settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Bot? saved;
    await tester.pumpWidget(
      _editHarness(
        bot: _bot(
          supportsMcp: true,
          serverIds: const {'server-1'},
          tools: {
            McpToolConfiguration(serverId: 'server-1', remoteName: 'search'),
          },
        ),
        onSaved: (bot) async => saved = bot,
      ),
    );
    await tester.pumpAndSettle();

    final removeServer = find.byKey(
      const ValueKey<String>('remove-bot-mcp-server-server-1'),
    );
    await tester.ensureVisible(removeServer);
    await tester.tap(removeServer);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-server-server-1')),
      findsNothing,
    );

    await tester.ensureVisible(find.text('保存修改'));
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(saved?.mcpServerIds, isEmpty);
    expect(saved?.mcpTools, isEmpty);
  });

  testWidgets('bot without MCP model support hides Tool configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      _editHarness(bot: _bot(supportsMcp: false), onSaved: (_) async {}),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-toggle-server-1-search')),
      findsNothing,
    );
  });

  testWidgets('read-only bot details hide MCP Server addition', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Bot? saved;
    await tester.pumpWidget(
      _editHarness(
        bot: _bot(supportsMcp: true, serverIds: const {'server-1'}),
        readOnly: true,
        includeSecondTool: true,
        onSaved: (bot) async => saved = bot,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('add-bot-mcp-server')),
      findsNothing,
    );
    final selectedServer = find.byKey(
      const ValueKey<String>('bot-mcp-server-server-1'),
    );
    expect(
      find.descendant(
        of: selectedServer,
        matching: find.byIcon(Icons.hub_outlined),
      ),
      findsNothing,
    );
    await tester.ensureVisible(selectedServer);
    await tester.tap(selectedServer);
    await tester.pumpAndSettle();

    final toolSearch = find.descendant(
      of: find.byKey(const ValueKey<String>('bot-mcp-tool-search-server-1')),
      matching: find.byType(EditableText),
    );
    expect(toolSearch, findsOneWidget);
    await tester.enterText(toolSearch, 'mcp.server-1.fetch');
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-search')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-fetch')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('clear-bot-mcp-tool-search-server-1')),
    );
    await tester.pump();

    final toolToggle = find.byKey(
      const ValueKey<String>('bot-mcp-tool-toggle-server-1-search'),
    );
    await tester.ensureVisible(toolToggle);
    expect(tester.widget<Switch>(toolToggle).onChanged, isNull);
    await tester.tap(toolToggle, warnIfMissed: false);
    await tester.pump();

    expect(tester.widget<Switch>(toolToggle).value, isFalse);
    expect(find.text('保存修改'), findsNothing);
    expect(saved, isNull);
  });

  for (final readOnly in [false, true]) {
    testWidgets('desktop MCP Server dialog aligns its close button in '
        '${readOnly ? 'query' : 'edit'} mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _editHarness(
          bot: _bot(supportsMcp: true, serverIds: const {'server-1'}),
          embedded: true,
          readOnly: readOnly,
          onSaved: (_) async {},
        ),
      );
      await tester.pumpAndSettle();

      final selectedServer = find.byKey(
        const ValueKey<String>('bot-mcp-server-server-1'),
      );
      await tester.ensureVisible(selectedServer);
      await tester.tap(selectedServer);
      await tester.pumpAndSettle();

      _expectDesktopDialogCloseAligned(
        tester,
        dialogKey: 'bot-mcp-tools-dialog-server-1',
        closeKey: 'bot-mcp-tools-close-server-1',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('bot-mcp-tools-close-server-1')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('bot-mcp-tools-dialog-server-1')),
        findsNothing,
      );
    });
  }

  testWidgets('a new bot configures all MCP Tools at once', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Bot? added;
    await tester.pumpWidget(
      _addHarness(
        enableMcp: true,
        includeSecondServer: true,
        includeSecondTool: true,
        onAdded: (bot, _) async => added = bot,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('add-bot-name')),
        matching: find.byType(EditableText),
      ),
      'Assistant',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('add-bot-api-key')),
        matching: find.byType(EditableText),
      ),
      'secret',
    );
    await tester.tap(find.byIcon(LucideIcons.refreshCw));
    await tester.pumpAndSettle();

    final mcpSection = find.byKey(
      const ValueKey<String>('add-bot-mcp-section'),
    );
    expect(mcpSection, findsOneWidget);
    await tester.ensureVisible(mcpSection);
    await tester.tap(find.byKey(const ValueKey<String>('add-bot-mcp-server')));
    await tester.pumpAndSettle();
    final serverSearchField = find.byKey(
      const ValueKey<String>('bot-mcp-server-search'),
    );
    final serverSearch = find.descendant(
      of: serverSearchField,
      matching: find.byType(EditableText),
    );
    expect(serverSearch, findsOneWidget);
    final serverDialog = find.byKey(
      const ValueKey<String>('bot-add-mcp-server-dialog'),
    );
    _expectDesktopDialogCloseAligned(
      tester,
      dialogKey: 'bot-add-mcp-server-dialog',
      closeKey: 'bot-add-mcp-server-close',
    );
    final serverDialogRect = tester.getRect(serverDialog);
    final serverSearchRect = tester.getRect(serverSearchField);
    await tester.tap(serverSearch);
    await tester.pumpAndSettle();
    expect(tester.getRect(serverDialog), serverDialogRect);
    expect(tester.getRect(serverSearchField), serverSearchRect);
    expect(
      find.descendant(
        of: serverSearchField,
        matching: find.byKey(
          const ValueKey<String>('stars-search-inset-focus-ring'),
        ),
      ),
      findsOneWidget,
    );
    await tester.enterText(serverSearch, 'mcp.server-2.search');
    await tester.pump();
    expect(tester.getRect(serverDialog), serverDialogRect);
    expect(tester.getRect(serverSearchField), serverSearchRect);
    expect(
      find.byKey(const ValueKey<String>('available-bot-mcp-server-server-1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('available-bot-mcp-server-server-2')),
      findsOneWidget,
    );
    await tester.enterText(serverSearch, 'missing server');
    await tester.pump();
    final emptyServerSearch = find.byKey(
      const ValueKey<String>('bot-mcp-server-search-empty'),
    );
    expect(emptyServerSearch, findsOneWidget);
    expect(find.text('未找到匹配的 MCP 服务器'), findsOneWidget);
    expect(tester.getRect(serverDialog), serverDialogRect);
    expect(
      find.descendant(of: emptyServerSearch, matching: find.byType(TextButton)),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('clear-bot-mcp-server-search')),
    );
    await tester.pump();
    expect(tester.getRect(serverDialog), serverDialogRect);
    expect(tester.getRect(serverSearchField), serverSearchRect);
    final availableServer = find.byKey(
      const ValueKey<String>('available-bot-mcp-server-server-1'),
    );
    _expectPrimaryTextColor(
      tester,
      find.descendant(of: availableServer, matching: find.text('Docs')),
    );
    expect(
      find.descendant(
        of: availableServer,
        matching: find.byIcon(Icons.hub_outlined),
      ),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('select-bot-mcp-server-server-1')),
    );
    await tester.pumpAndSettle();
    final selectedServer = find.byKey(
      const ValueKey<String>('bot-mcp-server-server-1'),
    );
    _expectPrimaryTextColor(
      tester,
      find.descendant(of: selectedServer, matching: find.text('Docs')),
    );
    expect(
      find.descendant(
        of: selectedServer,
        matching: find.byIcon(Icons.hub_outlined),
      ),
      findsNothing,
    );
    await tester.ensureVisible(selectedServer);
    await tester.tap(selectedServer);
    await tester.pumpAndSettle();

    final toolSearchField = find.byKey(
      const ValueKey<String>('bot-mcp-tool-search-server-1'),
    );
    final toolSearch = find.descendant(
      of: toolSearchField,
      matching: find.byType(EditableText),
    );
    expect(toolSearch, findsOneWidget);
    final searchRect = tester.getRect(toolSearchField);
    final toolDialog = find.byKey(
      const ValueKey<String>('bot-mcp-tools-dialog-server-1'),
    );
    _expectPrimaryTextColor(
      tester,
      find.descendant(of: toolDialog, matching: find.text('Docs')),
    );
    final dialogRect = tester.getRect(toolDialog);
    await tester.tap(toolSearch);
    await tester.pumpAndSettle();
    expect(tester.getRect(toolDialog), dialogRect);
    expect(tester.getRect(toolSearchField), searchRect);
    expect(
      find.descendant(
        of: toolSearchField,
        matching: find.byKey(
          const ValueKey<String>('stars-search-inset-focus-ring'),
        ),
      ),
      findsOneWidget,
    );
    await tester.enterText(toolSearch, 'mcp.server-1.fetch');
    await tester.pump();
    expect(tester.getRect(toolSearchField), searchRect);
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-search')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-server-1-fetch')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('clear-bot-mcp-tool-search-server-1')),
    );
    await tester.pump();
    expect(tester.getRect(toolSearchField), searchRect);

    final searchToolRow = find.byKey(
      const ValueKey<String>('bot-mcp-tool-server-1-search'),
    );
    _expectPrimaryTextColor(
      tester,
      find.descendant(of: searchToolRow, matching: find.text('Search')),
    );
    final searchToolToggle = find.byKey(
      const ValueKey<String>('bot-mcp-tool-toggle-server-1-search'),
    );
    final searchNoApprovalToggle = find.byKey(
      const ValueKey<String>('bot-mcp-tool-no-approval-server-1-search'),
    );
    final searchToolDescription = find.byKey(
      const ValueKey<String>('bot-mcp-tool-description-server-1-search'),
    );
    final searchToolControls = find.byKey(
      const ValueKey<String>('bot-mcp-tool-controls-server-1-search'),
    );
    expect(
      find.descendant(of: searchToolRow, matching: find.text('已关闭')),
      findsOneWidget,
    );
    expect(
      (tester.getCenter(searchToolToggle).dy -
              tester.getCenter(searchNoApprovalToggle).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      tester.getRect(searchToolToggle).right,
      lessThan(tester.getRect(searchNoApprovalToggle).left),
    );
    expect(
      (tester.getCenter(searchToolDescription).dy -
              tester.getCenter(searchToolControls).dy)
          .abs(),
      lessThanOrEqualTo(1),
    );
    expect(
      tester.getRect(searchToolDescription).right,
      lessThan(tester.getRect(searchToolControls).left),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('bot-mcp-tools-toggle-all-server-1')),
    );
    await tester.pump();
    expect(
      find.descendant(of: searchToolRow, matching: find.text('已开启')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('bot-mcp-tools-no-approval-all-server-1'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('关闭').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('add-bot-submit')),
    );
    await tester.tap(find.byKey(const ValueKey<String>('add-bot-submit')));
    await tester.pumpAndSettle();

    expect(added?.mcpServerIds, {'server-1'});
    expect(added?.mcpTools, {
      McpToolConfiguration(
        serverId: 'server-1',
        remoteName: 'search',
        requiresApproval: false,
      ),
      McpToolConfiguration(
        serverId: 'server-1',
        remoteName: 'fetch',
        requiresApproval: false,
      ),
    });
  });

  testWidgets('a bot is created without MCP Tool configuration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Bot? added;
    await tester.pumpWidget(
      _addHarness(onAdded: (bot, _) async => added = bot),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tools-empty')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('bot-mcp-tool-toggle-server-1-search')),
      findsNothing,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('add-bot-name')),
        matching: find.byType(EditableText),
      ),
      'Assistant',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey<String>('add-bot-api-key')),
        matching: find.byType(EditableText),
      ),
      'secret',
    );
    await tester.tap(find.byKey(const ValueKey<String>('add-bot-submit')));
    await tester.pumpAndSettle();

    expect(added?.mcpTools, isEmpty);
    expect(added?.mcpServerIds, isEmpty);
  });
}

void _expectPrimaryTextColor(WidgetTester tester, Finder textFinder) {
  expect(textFinder, findsOneWidget);
  expect(
    tester.widget<Text>(textFinder).style?.color,
    StarsDesktopThemeSpec.text(tester.element(textFinder)),
  );
}

void _expectDesktopDialogCloseAligned(
  WidgetTester tester, {
  required String dialogKey,
  required String closeKey,
}) {
  final dialog = find.byKey(ValueKey<String>(dialogKey));
  final close = find.byKey(ValueKey<String>(closeKey));
  expect(dialog, findsOneWidget);
  expect(close, findsOneWidget);
  final dialogSurface =
      find.ancestor(of: close, matching: find.byType(Stack)).first;
  expect(tester.getSize(close), const Size.square(44));
  expect(
    find.descendant(of: close, matching: find.byIcon(LucideIcons.x)),
    findsOneWidget,
  );
  expect(
    tester.getRect(dialogSurface).right - tester.getRect(close).right,
    closeTo(8, 0.01),
  );
  expect(
    tester.getRect(close).top - tester.getRect(dialogSurface).top,
    closeTo(12, 0.01),
  );
}

Widget _editHarness({
  required Bot bot,
  required Future<void> Function(Bot) onSaved,
  bool embedded = false,
  bool readOnly = false,
  bool includeSecondServer = false,
  bool includeSecondTool = false,
}) {
  final server = _server();
  final secondServer = _server(id: 'server-2', name: 'Analytics');
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
  );
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: shadTheme,
    appBuilder:
        (shadContext) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(
            context: shadContext,
            fontSize: 16,
          ),
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: EditBotPage(
            bot: bot,
            embedded: embedded,
            readOnly: readOnly,
            mcpCatalogLoader:
                () async => (
                  servers: [server, if (includeSecondServer) secondServer],
                  toolsByServer: {
                    server.id: [
                      _tool(server),
                      if (includeSecondTool)
                        _tool(server, remoteName: 'fetch', title: 'Fetch'),
                    ],
                    if (includeSecondServer)
                      secondServer.id: [_tool(secondServer)],
                  },
                ),
            onBotUpdated: onSaved,
            onBotDeleted: () async {},
          ),
        ),
  );
}

Widget _addHarness({
  required Future<void> Function(Bot, List<BotSkillBinding>) onAdded,
  bool enableMcp = false,
  bool includeSecondServer = false,
  bool includeSecondTool = false,
}) {
  final server = _server();
  final secondServer = _server(id: 'server-2', name: 'Analytics');
  final shadTheme = buildStarsShadTheme(
    brightness: Brightness.light,
    fontSize: 16,
  );
  return ShadApp.custom(
    themeMode: ThemeMode.light,
    theme: shadTheme,
    appBuilder:
        (shadContext) => MaterialApp(
          theme: buildShadMaterialBridgeTheme(
            context: shadContext,
            fontSize: 16,
          ),
          locale: const Locale('zh', 'CN'),
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalShadLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            S.delegate,
          ],
          builder: (context, child) => ShadAppBuilder(child: child!),
          home: AddBotPage(
            embedded: true,
            botId: 'bot-new',
            modelLoader:
                enableMcp
                    ? (_) async => [
                      AiModelInfo(
                        modelId: 'gpt-test',
                        providerId: 'openai',
                        inputModalities: const [InputModality.text],
                        outputModalities: const [OutputModality.text],
                        supportsMcp: true,
                      ),
                    ]
                    : null,
            mcpCatalogLoader:
                () async => (
                  servers: [server, if (includeSecondServer) secondServer],
                  toolsByServer: {
                    server.id: [
                      _tool(server),
                      if (includeSecondTool)
                        _tool(server, remoteName: 'fetch', title: 'Fetch'),
                    ],
                    if (includeSecondServer)
                      secondServer.id: [_tool(secondServer)],
                  },
                ),
            onBotAdded: onAdded,
          ),
        ),
  );
}

Bot _bot({
  required bool supportsMcp,
  Set<String>? serverIds,
  Set<McpToolConfiguration> tools = const {},
}) => Bot(
  id: 'bot-1',
  name: 'Assistant',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://api.example.test',
  apiKey: 'secret',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  parameters: {
    Bot.parameterSupportsMcp: supportsMcp,
    if (serverIds != null) Bot.parameterMcpServers: serverIds.toList(),
    Bot.parameterMcpTools: [
      for (final configuration in tools) configuration.toMap(),
    ],
  },
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

McpServer _server({String id = 'server-1', String name = 'Docs'}) => McpServer(
  id: id,
  name: name,
  transport: McpStreamableHttpServerTransport(
    endpoint: Uri.parse('https://mcp.example.test/$id'),
  ),
  status: McpConnectionStatus.connected,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

McpToolDescriptor _tool(
  McpServer server, {
  String remoteName = 'search',
  String title = 'Search',
}) => McpToolDescriptor(
  serverId: server.id,
  remoteName: remoteName,
  title: title,
  description: '$title documentation.',
  inputSchema: const {'type': 'object'},
  updatedAt: DateTime(2026),
);
