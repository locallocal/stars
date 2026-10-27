import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/generated/l10n.dart';

void main() {
  const pageKeys = <String>{
    'mcpServers',
    'mcpServersDescription',
    'searchMcpServers',
    'noMatchingMcpServers',
    'addMcpServer',
    'remoteMcpOnly',
    'localMcpDisabledDescription',
    'mcpLocalProcessSecurityTitle',
    'mcpLocalProcessSecurityDescription',
    'mcpProgressiveDiscoveryDescription',
    'mcpHttpsRequired',
    'mcpPrivateEndpointBlocked',
    'mcpAuthorizationRequired',
    'mcpRequestTimedOut',
    'mcpUnsupportedProtocol',
    'mcpStdioStartFailed',
    'mcpInvalidStdioEnvironment',
    'mcpCredentialsInConfiguration',
    'mcpServerAlreadyExists',
    'mcpEnvironmentIsolationDescription',
    'mcpConnectionFailed',
    'deleteMcpServer',
    'confirmDeleteMcpServer',
    'mcpTools',
    'refreshMcpTools',
    'mcpServerDetails',
    'edit',
    'editMcpServer',
    'noMcpToolsDiscovered',
    'mcpToolSchemaUnsupported',
    'mcpConnected',
    'mcpConnecting',
    'mcpConnectionError',
    'mcpDisconnected',
    'mcpServerName',
    'mcpConnectionSettings',
    'mcpTransport',
    'mcpTransportStreamableHttp',
    'mcpTransportStdio',
    'mcpEndpoint',
    'mcpCommand',
    'mcpCommandDescription',
    'mcpArguments',
    'mcpArgumentsDescription',
    'mcpEnvironment',
    'mcpEnvironmentDescription',
    'mcpAuthentication',
    'mcpNoAuthentication',
    'mcpAccessToken',
    'mcpTokenStoredSecurely',
    'mcpTokenLeaveBlank',
    'saveAndConnect',
    'noMcpServers',
    'noMcpServersDescription',
  };

  test('English and Chinese catalogs define the complete MCP feature copy', () {
    for (final locale in ['en', 'zh_CN', 'zh_TW']) {
      final messages =
          jsonDecode(File('lib/l10n/intl_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      expect(
        pageKeys.difference(messages.keys.toSet()),
        isEmpty,
        reason: '$locale is missing MCP translations',
      );
      expect(messages['mcpConnectionFailed'], contains('{error}'));
      expect(messages['confirmDeleteMcpServer'], contains('{name}'));
    }
  });

  test('every locale names the MCP settings entry', () {
    final arbFiles = Directory('lib/l10n').listSync().whereType<File>().where(
      (file) => RegExp(r'intl_.+\.arb$').hasMatch(file.path),
    );

    for (final file in arbFiles) {
      final messages =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(messages['mcpServers'], isA<String>());
      expect(messages['mcpServersDescription'], isA<String>());
      expect(messages['details'], isA<String>());
      expect(messages['refresh'], isA<String>());
    }
  });

  test(
    'generated MCP messages load for English and Simplified Chinese',
    () async {
      await S.load(const Locale('en'));
      expect(S.current.mcpServers, 'MCP Servers');
      expect(S.current.searchMcpServers, 'Search MCP servers');
      expect(S.current.mcpServerDetails, 'Server details');
      expect(S.current.details, 'Details');
      expect(S.current.refresh, 'Refresh');
      expect(S.current.edit, 'Edit');
      expect(
        S.current.mcpConnectionFailed('network'),
        'MCP connection failed: network',
      );

      await S.load(const Locale('zh', 'CN'));
      expect(S.current.mcpServers, 'MCP 服务器');
      expect(S.current.searchMcpServers, '搜索 MCP 服务器');
      expect(S.current.mcpServerDetails, '服务器详情');
      expect(S.current.details, '详情');
      expect(S.current.refresh, '刷新');
      expect(S.current.edit, '编辑');
      expect(S.current.mcpConnectionFailed('网络'), 'MCP 连接失败：网络');
    },
  );

  test('generated MCP card actions load for every supported locale', () async {
    final expected = <Locale, ({String details, String refresh})>{
      Locale('en', 'US'): (details: 'Details', refresh: 'Refresh'),
      Locale('zh', 'CN'): (details: '详情', refresh: '刷新'),
      Locale('zh', 'TW'): (details: '詳情', refresh: '重新整理'),
      Locale('ja', 'JP'): (details: '詳細', refresh: '更新'),
      Locale('fr', 'FR'): (details: 'Détails', refresh: 'Actualiser'),
      Locale('de', 'DE'): (details: 'Details', refresh: 'Aktualisieren'),
      Locale('ko', 'KR'): (details: '세부 정보', refresh: '새로 고침'),
      Locale('ru', 'RU'): (details: 'Сведения', refresh: 'Обновить'),
      Locale('es', 'ES'): (details: 'Detalles', refresh: 'Actualizar'),
      Locale('hi', 'IN'): (details: 'विवरण', refresh: 'ताज़ा करें'),
      Locale('pt', 'BR'): (details: 'Detalhes', refresh: 'Atualizar'),
      Locale('it', 'IT'): (details: 'Dettagli', refresh: 'Aggiorna'),
    };

    for (final entry in expected.entries) {
      await S.load(entry.key);
      expect(
        S.current.details,
        entry.value.details,
        reason: entry.key.toString(),
      );
      expect(
        S.current.refresh,
        entry.value.refresh,
        reason: entry.key.toString(),
      );
    }
  });
}
