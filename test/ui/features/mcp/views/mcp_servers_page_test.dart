import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/data/services/mcp/mcp_catalog_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/mcp_client.dart';
import 'package:stars/domain/repositories/mcp_credential_store.dart';
import 'package:stars/domain/repositories/mcp_server_repository.dart';
import 'package:stars/domain/use_cases/mcp_server_mutations.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/l10n/app_localizations.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/mcp/view_models/mcp_servers_view_model.dart';
import 'package:stars/ui/features/mcp/views/mcp_servers_page.dart';
import 'package:stars/utils/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop MCP page matches the Skill page content alignment', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final repository = _FakeMcpServerRepository();
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: const _UnusedMcpClient(),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final content = find.byKey(
        const ValueKey<String>('mcp-servers-desktop-content'),
      );
      expect(content, findsOneWidget);
      expect(tester.getSize(content).width, 920);
      expect(tester.getTopLeft(content), const Offset(240, 28));
      expect(find.text('MCP 服务器'), findsOneWidget);
      expect(find.text('添加 MCP 服务器'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('mcp-servers-desktop-page')),
          matching: find.byIcon(Icons.hub_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('add-mcp-server-desktop')),
        findsOneWidget,
      );
      final headerAddButton = find.byKey(
        const ValueKey<String>('add-mcp-server-desktop'),
      );
      final emptyAddButton = find.byKey(
        const ValueKey<String>('add-mcp-server-empty-desktop'),
      );
      expect(emptyAddButton, findsOneWidget);
      expect(
        tester.getSize(emptyAddButton).width,
        tester.getSize(headerAddButton).width,
      );
      final searchField = find.byKey(
        const ValueKey<String>('mcp-search-field'),
      );
      final securityAlert = find.ancestor(
        of: find.text('本地进程安全'),
        matching: find.byType(ShadAlert),
      );
      expect(searchField, findsOneWidget);
      expect(tester.getSize(searchField).width, 920);
      expect(
        tester.getTopLeft(searchField).dy,
        greaterThan(tester.getBottomLeft(securityAlert).dy),
      );
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop MCP startup error can be dismissed', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final repository = _FakeMcpServerRepository(
      getServersError: const McpException('mcp_stdio_start_failed'),
    );
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: const _UnusedMcpClient(),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('mcp-error-alert')),
        findsOneWidget,
      );
      final errorMessage = find.text('无法启动 stdio MCP 命令。');
      expect(errorMessage, findsOneWidget);
      expect(
        tester.getCenter(errorMessage).dy,
        closeTo(
          tester
              .getCenter(find.byKey(const ValueKey<String>('mcp-error-alert')))
              .dy,
          1,
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('close-mcp-error')));
      await tester.pump();

      expect(viewModel.error, isNull);
      expect(
        find.byKey(const ValueKey<String>('mcp-error-alert')),
        findsNothing,
      );
      expect(find.text('无法启动 stdio MCP 命令。'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop MCP cards show Tool counts and details in a dialog', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final now = DateTime.utc(2026, 7, 30);
    final servers = [
      McpServer(
        id: 'github',
        name: 'GitHub',
        transport: McpStreamableHttpServerTransport(
          endpoint: Uri.parse('https://example.com/github/mcp'),
        ),
        status: McpConnectionStatus.connected,
        createdAt: now,
        updatedAt: now,
      ),
      McpServer(
        id: 'filesystem',
        name: 'Filesystem',
        transport: McpStdioServerTransport(
          command: 'npx',
          arguments: const ['-y', '@example/filesystem-mcp'],
        ),
        status: McpConnectionStatus.connected,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final repository = _FakeMcpServerRepository(
      servers: servers,
      toolsByServer: {
        'github': [
          McpToolDescriptor(
            serverId: 'github',
            remoteName: 'search_issues',
            title: '搜索议题',
            description: '搜索仓库中的议题。',
            inputSchema: const {
              'type': 'object',
              'properties': <String, Object?>{},
            },
            updatedAt: now,
          ),
        ],
        'filesystem': [
          McpToolDescriptor(
            serverId: 'filesystem',
            remoteName: 'read_file',
            title: '读取文件',
            description: '读取工作区中的文件。',
            inputSchema: const {
              'type': 'object',
              'properties': <String, Object?>{},
            },
            updatedAt: now,
          ),
        ],
      },
    );
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: _UnusedMcpClient(
          processInfoByServerId: {
            'filesystem': McpStdioProcessInfo(
              processId: 4242,
              command: 'npx',
              arguments: const ['-y', '@example/filesystem-mcp'],
              startedAt: DateTime(2026, 7, 30, 9, 45),
              environmentVariableCount: 2,
            ),
          },
        ),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final githubCard = find.byKey(
        const ValueKey<String>('desktop-mcp-server-github'),
      );
      final filesystemCard = find.byKey(
        const ValueKey<String>('desktop-mcp-server-filesystem'),
      );
      expect(githubCard, findsOneWidget);
      expect(filesystemCard, findsOneWidget);

      final pageTitle = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mcp-servers-title')),
      );
      final githubTitle = tester.widget<Text>(
        find.byKey(const ValueKey<String>('desktop-mcp-server-title-github')),
      );
      expect(githubTitle.style, pageTitle.style);

      final githubRect = tester.getRect(githubCard);
      final filesystemRect = tester.getRect(filesystemCard);
      expect(githubRect.width, 453);
      expect(filesystemRect.width, 453);
      expect(githubRect.height, filesystemRect.height);
      expect(githubRect.height, StarsDesktopThemeSpec.managementCardHeight);
      expect(githubRect.top, filesystemRect.top);
      expect(filesystemRect.left - githubRect.right, 14);

      for (final card in [githubCard, filesystemCard]) {
        final tags = tester.widgetList<ShadBadge>(
          find.descendant(of: card, matching: find.byType(ShadBadge)),
        );
        expect(tags, hasLength(3));
        expect(
          tags.every((tag) => tag.variant == ShadBadgeVariant.outline),
          isTrue,
        );
      }

      final githubFooter = find.byKey(
        const ValueKey<String>('desktop-mcp-server-footer-github'),
      );
      final githubActions = find.byKey(
        const ValueKey<String>('desktop-mcp-server-actions-github'),
      );
      final githubTags = find.descendant(
        of: githubCard,
        matching: find.byType(ShadBadge),
      );
      expect(githubFooter, findsOneWidget);
      expect(githubActions, findsOneWidget);
      for (final tag in githubTags.evaluate()) {
        expect(
          tester.getCenter(find.byWidget(tag.widget)).dy,
          closeTo(tester.getCenter(githubActions).dy, 1),
        );
      }
      expect(
        githubRect.bottom - tester.getRect(githubActions).bottom,
        closeTo(tester.getRect(find.text('GitHub')).top - githubRect.top, 1),
      );

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('1 工具'), findsNWidgets(2));
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-github-search_issues'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-filesystem-read_file'),
        ),
        findsNothing,
      );
      expect(find.text('搜索议题'), findsNothing);
      expect(find.text('读取文件'), findsNothing);

      await tester.tap(githubCard, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-server-details-dialog-github'),
        ),
        findsOneWidget,
      );
      final detailsClose = find.byKey(
        const ValueKey<String>('desktop-mcp-server-details-close-github'),
      );
      expect(detailsClose, findsOneWidget);
      final detailsDialogSurface =
          find.ancestor(of: detailsClose, matching: find.byType(Stack)).first;
      expect(
        find.descendant(of: detailsClose, matching: find.byIcon(LucideIcons.x)),
        findsOneWidget,
      );
      expect(tester.getSize(detailsClose), const Size.square(44));
      expect(
        tester.getRect(detailsDialogSurface).right -
            tester.getRect(detailsClose).right,
        closeTo(8, 0.01),
      );
      expect(
        tester.getRect(detailsClose).top -
            tester.getRect(detailsDialogSurface).top,
        closeTo(12, 0.01),
      );
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-github-search_issues'),
        ),
        findsOneWidget,
      );
      final detailsTitle = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mcp-server-details-title-github')),
      );
      expect(detailsTitle.style, pageTitle.style);

      final toolSearch = find.descendant(
        of: find.byKey(
          const ValueKey<String>('desktop-mcp-tool-search-github'),
        ),
        matching: find.byType(EditableText),
      );
      expect(toolSearch, findsOneWidget);
      final searchField = find.byKey(
        const ValueKey<String>('desktop-mcp-tool-search-github'),
      );
      final toolCard = find.byKey(
        const ValueKey<String>('desktop-mcp-tool-github-search_issues'),
      );
      final detailsScrollable =
          find
              .ancestor(of: searchField, matching: find.byType(Scrollable))
              .first;
      final scrollPosition =
          tester.state<ScrollableState>(detailsScrollable).position;
      final searchRectBeforeFocus = tester.getRect(searchField);
      final toolCardRectBeforeFocus = tester.getRect(toolCard);
      final scrollOffsetBeforeFocus = scrollPosition.pixels;

      await tester.tap(toolSearch);
      await tester.pumpAndSettle();

      expect(tester.getRect(searchField), searchRectBeforeFocus);
      expect(tester.getRect(toolCard), toolCardRectBeforeFocus);
      expect(scrollPosition.pixels, scrollOffsetBeforeFocus);
      await tester.enterText(toolSearch, '仓库');
      await tester.pump();
      final searchRect = tester.getRect(searchField);
      expect(toolCard, findsOneWidget);
      final toolCardRect = tester.getRect(toolCard);
      expect(searchRect, searchRectBeforeFocus);
      expect(toolCardRect, toolCardRectBeforeFocus);
      expect(scrollPosition.pixels, scrollOffsetBeforeFocus);
      expect(searchRect.left, toolCardRect.left);
      expect(searchRect.right, toolCardRect.right);
      final shadInput = tester.widget<ShadInput>(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('desktop-mcp-tool-search-github'),
          ),
          matching: find.byType(ShadInput),
        ),
      );
      expect(shadInput.decoration?.focusedBorder?.top?.width, 1);
      expect(shadInput.decoration?.secondaryFocusedBorder?.hasBorder, isFalse);
      expect(
        find.descendant(
          of: searchField,
          matching: find.byKey(
            const ValueKey<String>('stars-search-inset-focus-ring'),
          ),
        ),
        findsOneWidget,
      );

      await tester.enterText(toolSearch, 'missing tool');
      await tester.pump();
      expect(tester.getRect(searchField), searchRectBeforeFocus);
      expect(scrollPosition.pixels, scrollOffsetBeforeFocus);
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-github-search_issues'),
        ),
        findsNothing,
      );
      expect(find.text('未找到匹配的工具'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('clear-desktop-mcp-tool-search-github'),
        ),
      );
      await tester.pump();
      expect(tester.getRect(searchField), searchRectBeforeFocus);
      expect(tester.getRect(toolCard), toolCardRectBeforeFocus);
      expect(scrollPosition.pixels, scrollOffsetBeforeFocus);
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-github-search_issues'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('关闭'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-server-details-dialog-github'),
        ),
        findsNothing,
      );

      final githubActionsFocusNode =
          tester
              .widget<ShadIconButton>(
                find.descendant(
                  of: githubActions,
                  matching: find.byType(ShadIconButton),
                ),
              )
              .focusNode!;
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-refresh-github')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-details-github')),
        findsNothing,
      );

      await tester.tap(githubActions, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-server-details-dialog-github'),
        ),
        findsNothing,
      );
      final githubActionMenu = find.byKey(
        const ValueKey<String>('desktop-mcp-server-action-menu-github'),
      );
      expect(githubActionMenu, findsOneWidget);
      expect(
        tester.getRect(githubActionMenu).right,
        closeTo(tester.getRect(githubActions).right, 1),
      );
      expect(
        find.descendant(
          of: githubActionMenu,
          matching: find.byType(ShadButton),
        ),
        findsNWidgets(4),
      );
      final githubDetails = find.byKey(
        const ValueKey<String>('desktop-mcp-server-details-github'),
      );
      expect(githubDetails, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-refresh-github')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-edit-github')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-delete-github')),
        findsOneWidget,
      );
      expect(find.text('详情'), findsOneWidget);
      expect(find.text('刷新'), findsOneWidget);
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('编辑 MCP 服务器'), findsNothing);
      expect(find.text('删除 MCP 服务器'), findsNothing);

      await tester.tap(githubDetails, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-refresh-github')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-server-details-dialog-github'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-github-search_issues'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-filesystem-read_file'),
        ),
        findsNothing,
      );
      expect(find.text('搜索议题'), findsOneWidget);
      expect(find.text('读取文件'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>(
            'desktop-mcp-tool-toggle-github-search_issues',
          ),
        ),
        findsNothing,
      );

      await tester.tap(find.text('关闭'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey<String>('desktop-mcp-tool-github-search_issues'),
        ),
        findsNothing,
      );
      expect(
        githubActionsFocusNode.hasFocus,
        isFalse,
        reason:
            'Pointer-invoked card actions must not leave a focus ring behind.',
      );

      await tester.tap(filesystemCard, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('mcp-stdio-runtime-filesystem')),
        findsOneWidget,
      );
      expect(find.text('本地进程与通信'), findsOneWidget);
      expect(find.text('进程 ID (PID)'), findsOneWidget);
      expect(find.text('4242'), findsOneWidget);
      expect(find.text('运行中'), findsOneWidget);
      expect(find.text('npx'), findsOneWidget);
      expect(find.text('-y\n@example/filesystem-mcp'), findsOneWidget);
      expect(find.text('2026-07-30 09:45:00'), findsOneWidget);
      expect(find.text('stdin / stdout / stderr（操作系统管道）'), findsOneWidget);
      expect(find.text('Socket'), findsNothing);
      expect(find.text('不适用（stdio 使用进程管道）'), findsNothing);
      expect(find.text('2 个（值已隐藏）'), findsOneWidget);
      final filesystemDetailsTitle = tester.widget<Text>(
        find.byKey(
          const ValueKey<String>('mcp-server-details-title-filesystem'),
        ),
      );
      final runtimeTitle = tester.widget<Text>(
        find.byKey(
          const ValueKey<String>('mcp-stdio-runtime-title-filesystem'),
        ),
      );
      final toolsTitle = tester.widget<Text>(
        find.byKey(const ValueKey<String>('mcp-tools-title-filesystem')),
      );
      final secondaryText =
          StarsDesktopTokens.of(
            tester.element(
              find.byKey(
                const ValueKey<String>('mcp-stdio-runtime-title-filesystem'),
              ),
            ),
          ).secondaryText;
      expect(
        runtimeTitle.style?.fontSize,
        filesystemDetailsTitle.style?.fontSize,
      );
      expect(
        toolsTitle.style?.fontSize,
        filesystemDetailsTitle.style?.fontSize,
      );
      expect(runtimeTitle.style?.color, secondaryText);
      expect(toolsTitle.style?.color, secondaryText);
      expect(
        runtimeTitle.style?.color,
        isNot(filesystemDetailsTitle.style?.color),
      );

      await tester.tap(find.text('关闭'), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      final searchInput = find.descendant(
        of: find.byKey(const ValueKey<String>('mcp-search-field')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(searchInput, 'read_file');
      await tester.pump();
      expect(githubCard, findsNothing);
      expect(filesystemCard, findsOneWidget);
      expect(find.text('读取文件'), findsNothing);

      await tester.enterText(searchInput, 'not-found');
      await tester.pump();
      expect(githubCard, findsNothing);
      expect(filesystemCard, findsNothing);
      expect(find.text('未找到匹配的 MCP 服务器'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('clear-mcp-search')));
      await tester.pump();
      expect(githubCard, findsOneWidget);
      expect(filesystemCard, findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop MCP list uses one lazy sliver viewport', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 600);
    tester.view.devicePixelRatio = 1;

    final now = DateTime.utc(2026, 8, 16);
    final servers = List<McpServer>.generate(
      60,
      (index) => McpServer(
        id: 'server-$index',
        name: 'Server ${index.toString().padLeft(2, '0')}',
        transport: McpStreamableHttpServerTransport(
          endpoint: Uri.parse('https://example.com/server-$index/mcp'),
        ),
        status: McpConnectionStatus.connected,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final repository = _FakeMcpServerRepository(servers: servers);
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: const _UnusedMcpClient(),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      final page = find.byKey(
        const ValueKey<String>('mcp-servers-desktop-page'),
      );
      final builtCards = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('desktop-mcp-server-server-');
      });

      expect(page, findsOneWidget);
      expect(tester.widget<CustomScrollView>(page), isA<CustomScrollView>());
      expect(
        find.descendant(of: page, matching: find.byType(GridView)),
        findsNothing,
      );
      expect(
        find.descendant(of: page, matching: find.byType(SliverGrid)),
        findsOneWidget,
      );
      expect(builtCards, findsWidgets);
      expect(builtCards.evaluate().length, lessThan(servers.length));
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-server-59')),
        findsNothing,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('desktop-mcp-server-server-59')),
        500,
        scrollable:
            find.descendant(of: page, matching: find.byType(Scrollable)).first,
      );

      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-server-59')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('mobile MCP details filter Tools and clear the query', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;

    final now = DateTime.utc(2026, 8, 10);
    final server = McpServer(
      id: 'github',
      name: 'GitHub',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/github/mcp'),
      ),
      status: McpConnectionStatus.connected,
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeMcpServerRepository(
      servers: [server],
      toolsByServer: {
        server.id: [
          McpToolDescriptor(
            serverId: server.id,
            remoteName: 'search_issues',
            title: '搜索议题',
            description: '搜索仓库中的议题。',
            inputSchema: const {
              'type': 'object',
              'properties': <String, Object?>{},
            },
            updatedAt: now,
          ),
        ],
      },
    );
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: const _UnusedMcpClient(),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('mobile-mcp-server-title-github')),
      );
      await tester.pumpAndSettle();

      final toolSearch = find.descendant(
        of: find.byKey(const ValueKey<String>('mobile-mcp-tool-search-github')),
        matching: find.byType(EditableText),
      );
      expect(toolSearch, findsOneWidget);
      expect(find.text('搜索议题'), findsOneWidget);

      await tester.enterText(toolSearch, 'mcp.github.search_issues');
      await tester.pump();
      expect(find.text('搜索议题'), findsOneWidget);

      await tester.enterText(toolSearch, 'not found');
      await tester.pump();
      expect(find.text('搜索议题'), findsNothing);
      expect(find.text('未找到匹配的工具'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('clear-mobile-mcp-tool-search-github'),
        ),
      );
      await tester.pump();
      expect(find.text('搜索议题'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop MCP delete dialog matches delete chat styling', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final now = DateTime.utc(2026, 7, 30);
    final server = McpServer(
      id: 'github',
      name: 'GitHub',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/github/mcp'),
      ),
      status: McpConnectionStatus.connected,
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeMcpServerRepository(servers: [server]);
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: const _UnusedMcpClient(),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-mcp-server-actions-github')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-mcp-server-delete-github')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('删除 MCP 服务器'), findsOneWidget);
      expect(find.text('确定删除“GitHub”？缓存的工具目录和安全凭据也会一并移除。'), findsOneWidget);

      final cancelButtonFinder = find.ancestor(
        of: find.text('取消'),
        matching: find.byType(ShadButton),
      );
      final deleteButtonFinder = find.ancestor(
        of: find.text('删除'),
        matching: find.byType(ShadButton),
      );
      expect(cancelButtonFinder, findsOneWidget);
      expect(deleteButtonFinder, findsOneWidget);
      expect(
        tester.widget<ShadButton>(cancelButtonFinder).variant,
        ShadButtonVariant.outline,
      );
      expect(
        tester.widget<ShadButton>(deleteButtonFinder).variant,
        ShadButtonVariant.destructive,
      );
      expect(
        tester.getCenter(cancelButtonFinder).dx,
        lessThan(tester.getCenter(deleteButtonFinder).dx),
      );

      await tester.tap(cancelButtonFinder);
      await tester.pumpAndSettle();
      expect(find.byType(ShadDialog), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('desktop-mcp-server-github')),
        findsOneWidget,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop in-use deletion error keeps original content width', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final now = DateTime.utc(2026, 7, 30);
    final server = McpServer(
      id: 'github',
      name: 'GitHub',
      transport: McpStreamableHttpServerTransport(
        endpoint: Uri.parse('https://example.com/github/mcp'),
      ),
      createdAt: now,
      updatedAt: now,
    );
    final repository = _FakeMcpServerRepository(servers: [server]);
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      botRepository: _FakeBotRepository([
        _botUsingMcpServer(server.id, now: now),
      ]),
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: const _UnusedMcpClient(),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-mcp-server-actions-github')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('desktop-mcp-server-delete-github')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.ancestor(of: find.text('删除'), matching: find.byType(ShadButton)),
      );
      await tester.pumpAndSettle();

      final content = find.byKey(
        const ValueKey<String>('mcp-servers-desktop-content'),
      );
      final errorRegion = find.byKey(
        const ValueKey<String>('mcp-error-region'),
      );
      final alert = find.byKey(const ValueKey<String>('mcp-error-alert'));
      final message = find.byKey(const ValueKey<String>('mcp-error-message'));
      final description = find.text(
        'Stars 会保存已发现的工具目录。请在编辑智能体时逐个开启工具，只有该智能体会将其提供给模型。',
      );
      final serverCard = find.byKey(
        const ValueKey<String>('desktop-mcp-server-github'),
      );
      const expectedWidth = StarsDesktopThemeSpec.formContentMaxWidth;
      expect(errorRegion, findsOneWidget);
      expect(alert, findsOneWidget);
      expect(find.text('此 MCP 服务器正被智能体使用，请先从智能体中移除后再删除。'), findsOneWidget);
      expect(tester.getSize(errorRegion).width, expectedWidth);
      expect(tester.getSize(alert).width, expectedWidth);
      expect(tester.getSize(errorRegion).height, lessThanOrEqualTo(58));
      expect(tester.getSize(alert).height, lessThanOrEqualTo(58));
      expect(tester.getRect(alert).top - tester.getRect(description).bottom, 8);
      expect(tester.getRect(serverCard).top - tester.getRect(alert).bottom, 10);
      expect(tester.getRect(errorRegion).left, tester.getRect(content).left);
      expect(tester.getRect(errorRegion).right, tester.getRect(content).right);
      expect(
        tester.getCenter(message).dx,
        closeTo(tester.getCenter(alert).dx, 1),
      );
      expect(find.byType(StarsInlineErrorAlert), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('desktop MCP editor matches the Add Bot form dialog', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;

    final repository = _FakeMcpServerRepository();
    final viewModel = _createMcpServersViewModel(
      repository: repository,
      credentialStore: const _UnusedCredentialStore(),
      catalogService: McpCatalogService(
        repository: repository,
        client: const _UnusedMcpClient(),
        toolRegistry: DynamicToolRegistry(const []),
      ),
    );
    addTearDown(viewModel.dispose);

    try {
      await tester.pumpWidget(_harness(viewModel));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('add-mcp-server-desktop')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ShadForm), findsOneWidget);
      expect(find.byType(ShadCard), findsNWidgets(2));
      expect(
        find.byWidgetPredicate((widget) => widget is StarsDesktopMenu<Object?>),
        findsNWidgets(2),
      );
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.byIcon(LucideIcons.link), findsNWidgets(2));
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('保存并连接'), findsOneWidget);
      expect(
        tester.getSize(
          find.byKey(const ValueKey<String>('mcp-server-dialog-content')),
        ),
        const Size(840, 720),
      );

      final basicSection = find.byKey(
        const ValueKey<String>('mcp-server-basic-section'),
      );
      final connectionSection = find.byKey(
        const ValueKey<String>('mcp-server-connection-section'),
      );
      expect(basicSection, findsOneWidget);
      expect(connectionSection, findsOneWidget);
      expect(
        tester.getRect(basicSection).bottom,
        lessThan(tester.getRect(connectionSection).top),
      );

      Size inputSize(String key) {
        return tester.getSize(
          find.descendant(
            of: find.byKey(ValueKey<String>(key)),
            matching: find.byType(ShadInput),
          ),
        );
      }

      final inputSizes = [
        inputSize('mcp-server-name'),
        inputSize('mcp-server-transport'),
        inputSize('mcp-server-endpoint'),
        inputSize('mcp-server-authentication'),
      ];
      expect(inputSizes.map((size) => size.width).toSet(), {
        StarsDesktopThemeSpec.addBotFormFieldWidth,
      });
      expect(inputSizes.map((size) => size.height).toSet(), {
        StarsDesktopThemeSpec.botFormFieldHeight,
      });

      final authenticationMenu = find.byKey(
        const ValueKey<String>('mcp-server-authentication-menu'),
      );
      await tester.ensureVisible(authenticationMenu);
      await tester.pumpAndSettle();
      await tester.tap(authenticationMenu);
      await tester.pumpAndSettle();
      final authenticationField = find.byKey(
        const ValueKey<String>('mcp-server-authentication'),
      );
      final authenticationInputStyle =
          tester
              .widget<EditableText>(
                find.descendant(
                  of: authenticationField,
                  matching: find.byType(EditableText),
                ),
              )
              .style;
      final accessTokenOption = find.ancestor(
        of: find.text('OAuth / Bearer 访问令牌').last,
        matching: find.byType(ShadButton),
      );
      expect(accessTokenOption, findsOneWidget);
      final accessTokenText = find.text('OAuth / Bearer 访问令牌').last;
      final accessTokenStyle = DefaultTextStyle.of(
        tester.element(accessTokenText),
      ).style.merge(tester.widget<Text>(accessTokenText).style);
      expect(accessTokenStyle.fontSize, authenticationInputStyle.fontSize);
      expect(accessTokenStyle.fontFamily, authenticationInputStyle.fontFamily);
      await tester.tap(accessTokenOption);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('mcp-server-access-token')),
        findsOneWidget,
      );
      expect(
        inputSize('mcp-server-access-token'),
        const Size(
          StarsDesktopThemeSpec.addBotFormFieldWidth,
          StarsDesktopThemeSpec.botFormFieldHeight,
        ),
      );

      final transportMenu = find.byKey(
        const ValueKey<String>('mcp-server-transport-menu'),
      );
      await tester.ensureVisible(transportMenu);
      await tester.pumpAndSettle();
      final transportField = find.byKey(
        const ValueKey<String>('mcp-server-transport'),
      );
      final transportInput = find.descendant(
        of: transportField,
        matching: find.byType(ShadInput),
      );
      await tester.tapAt(tester.getCenter(transportInput));
      await tester.pumpAndSettle();
      expect(find.text('stdio（本地进程）'), findsNothing);

      final transportMenuRect = tester.getRect(transportMenu);
      await tester.tap(transportMenu);
      await tester.pumpAndSettle();
      final transportInputStyle =
          tester
              .widget<EditableText>(
                find.descendant(
                  of: transportField,
                  matching: find.byType(EditableText),
                ),
              )
              .style;
      final stdioOption = find.ancestor(
        of: find.text('stdio（本地进程）').last,
        matching: find.byType(ShadButton),
      );
      expect(stdioOption, findsOneWidget);
      expect(
        tester.getSize(stdioOption).width,
        lessThan(inputSize('mcp-server-transport').width),
      );
      expect(
        tester.getRect(stdioOption).right,
        lessThanOrEqualTo(transportMenuRect.right),
      );
      final stdioText = find.text('stdio（本地进程）').last;
      final stdioStyle = DefaultTextStyle.of(
        tester.element(stdioText),
      ).style.merge(tester.widget<Text>(stdioText).style);
      expect(stdioStyle.fontSize, transportInputStyle.fontSize);
      expect(stdioStyle.fontFamily, transportInputStyle.fontFamily);
      await tester.tap(stdioOption);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('mcp-server-command')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mcp-server-arguments')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mcp-server-environment')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('mcp-server-endpoint')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('mcp-server-authentication')),
        findsNothing,
      );
      expect(
        inputSize('mcp-server-command'),
        const Size(
          StarsDesktopThemeSpec.addBotFormFieldWidth,
          StarsDesktopThemeSpec.botFormFieldHeight,
        ),
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets(
    'new MCP server card appears while connection is still in progress',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;

      final repository = _SavingMcpServerRepository();
      final client = _BlockingMcpClient();
      final viewModel = _createMcpServersViewModel(
        repository: repository,
        credentialStore: const _NoOpCredentialStore(),
        catalogService: McpCatalogService(
          repository: repository,
          client: client,
          toolRegistry: DynamicToolRegistry(const []),
        ),
      );
      addTearDown(viewModel.dispose);

      try {
        await tester.pumpWidget(_harness(viewModel));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey<String>('add-mcp-server-desktop')),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey<String>('mcp-server-name')),
            matching: find.byType(EditableText),
          ),
          'Slow MCP',
        );
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey<String>('mcp-server-endpoint')),
            matching: find.byType(EditableText),
          ),
          'https://example.com/slow-mcp',
        );
        await tester.tap(
          find.ancestor(
            of: find.text('保存并连接'),
            matching: find.byType(ShadButton),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(client.discoveryStarted.isCompleted, isTrue);
        expect(find.byType(ShadDialog), findsNothing);
        expect(find.text('Slow MCP'), findsOneWidget);
        expect(viewModel.servers.single.name, 'Slow MCP');
        expect(viewModel.busyServerId, viewModel.servers.single.id);

        client.continueDiscovery.complete();
        await tester.pumpAndSettle();
        expect(viewModel.busyServerId, isNull);
        expect(find.text('Slow MCP'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}

McpServersViewModel _createMcpServersViewModel({
  required McpServerRepository repository,
  BotRepository botRepository = const _FakeBotRepository(),
  required McpCredentialStore credentialStore,
  required McpCatalogService catalogService,
}) => McpServersViewModel(
  repository: repository,
  catalogService: catalogService,
  saveAndConnect: SaveAndConnectMcpServer(
    repository: repository,
    credentialStore: credentialStore,
    catalogController: catalogService,
  ),
  deleteServer: DeleteMcpServer(
    repository: repository,
    botRepository: botRepository,
    credentialStore: credentialStore,
    catalogController: catalogService,
  ),
);

final class _FakeBotRepository implements BotRepository {
  const _FakeBotRepository([this.bots = const []]);

  final List<Bot> bots;

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => bots;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Bot operation is not used by this test.');
}

Bot _botUsingMcpServer(String serverId, {required DateTime now}) => Bot(
  id: 'agent',
  name: 'Agent',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://example.com',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: '',
  parameters: {
    Bot.parameterMcpServers: [serverId],
  },
  createTimestamp: now,
  modifyTimestamp: now,
);

Widget _harness(McpServersViewModel viewModel) {
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
          home: McpServersPage(viewModel: viewModel),
        ),
  );
}

final class _FakeMcpServerRepository implements McpServerRepository {
  const _FakeMcpServerRepository({
    this.servers = const [],
    this.toolsByServer = const {},
    this.getServersError,
  });

  final List<McpServer> servers;
  final Map<String, List<McpToolDescriptor>> toolsByServer;
  final Object? getServersError;

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<void> deleteServer(String id) async {}

  @override
  Future<McpServer?> getServer(String id) async {
    for (final server in servers) {
      if (server.id == id) return server;
    }
    return null;
  }

  @override
  Future<List<McpServer>> getServers() async {
    if (getServersError case final error?) throw error;
    return servers;
  }

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async =>
      toolsByServer[serverId] ?? const [];

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {}

  @override
  Future<void> saveServer(McpServer server) async {}
}

final class _UnusedCredentialStore implements McpCredentialStore {
  const _UnusedCredentialStore();

  @override
  Future<void> delete(String serverId) => throw UnimplementedError();

  @override
  Future<McpCredential?> read(String serverId) => throw UnimplementedError();

  @override
  Future<void> write(String serverId, McpCredential credential) =>
      throw UnimplementedError();
}

final class _UnusedMcpClient implements McpClient, McpStdioProcessInfoSource {
  const _UnusedMcpClient({this.processInfoByServerId = const {}});

  final Map<String, McpStdioProcessInfo> processInfoByServerId;

  @override
  McpStdioProcessInfo? getStdioProcessInfo(String serverId) =>
      processInfoByServerId[serverId];

  @override
  Future<McpToolCallResult> callTool({
    required McpServer server,
    required String remoteName,
    required Map<String, Object?> arguments,
    required AgentCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> disconnect(McpServer server) => throw UnimplementedError();

  @override
  Future<McpServerCatalog> discoverTools(
    McpServer server, {
    AgentCancellationToken? cancellationToken,
  }) => throw UnimplementedError();
}

final class _SavingMcpServerRepository implements McpServerRepository {
  final Map<String, McpServer> _servers = {};
  final Map<String, List<McpToolDescriptor>> _tools = {};

  @override
  Stream<List<McpServer>> get changes => const Stream.empty();

  @override
  Future<void> deleteServer(String id) async {
    _servers.remove(id);
    _tools.remove(id);
  }

  @override
  Future<McpServer?> getServer(String id) async => _servers[id];

  @override
  Future<List<McpServer>> getServers() async {
    final servers =
        _servers.values.toList()
          ..sort((left, right) => left.name.compareTo(right.name));
    return List<McpServer>.unmodifiable(servers);
  }

  @override
  Future<List<McpToolDescriptor>> getTools(String serverId) async =>
      _tools[serverId] ?? const [];

  @override
  Future<void> replaceCatalog(
    McpServer server,
    List<McpToolDescriptor> tools,
  ) async {
    _servers[server.id] = server;
    _tools[server.id] = List<McpToolDescriptor>.unmodifiable(tools);
  }

  @override
  Future<void> saveServer(McpServer server) async {
    _servers[server.id] = server;
  }
}

final class _NoOpCredentialStore implements McpCredentialStore {
  const _NoOpCredentialStore();

  @override
  Future<void> delete(String serverId) async {}

  @override
  Future<McpCredential?> read(String serverId) async => null;

  @override
  Future<void> write(String serverId, McpCredential credential) async {}
}

final class _BlockingMcpClient implements McpClient {
  final Completer<void> discoveryStarted = Completer<void>();
  final Completer<void> continueDiscovery = Completer<void>();

  @override
  Future<McpToolCallResult> callTool({
    required McpServer server,
    required String remoteName,
    required Map<String, Object?> arguments,
    required AgentCancellationToken cancellationToken,
  }) => throw UnimplementedError();

  @override
  Future<void> disconnect(McpServer server) async {}

  @override
  Future<McpServerCatalog> discoverTools(
    McpServer server, {
    AgentCancellationToken? cancellationToken,
  }) async {
    discoveryStarted.complete();
    await continueDiscovery.future;
    return McpServerCatalog(
      serverName: 'Slow MCP',
      serverVersion: '1.0.0',
      capabilities: McpServerCapabilities(tools: true),
      tools: [],
    );
  }
}
