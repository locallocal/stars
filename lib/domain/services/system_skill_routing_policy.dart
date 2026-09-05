import 'package:stars/domain/models/models.dart';

/// Selects bundled system Skills whose capabilities match the current request.
///
/// System Skills carry comparatively large instruction bodies and Tool
/// schemas. Routing them before prompt assembly keeps unrelated privileged
/// capabilities out of the model context while preserving the Bot's persisted
/// enable/disable choices.
final class SystemSkillRoutingPolicy {
  const SystemSkillRoutingPolicy();

  Set<String> select({
    required String query,
    required Set<String> enabledSkillIds,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const {};

    final selected = <String>{};
    void includeWhen(String skillId, bool relevant) {
      if (relevant && enabledSkillIds.contains(skillId)) {
        selected.add(skillId);
      }
    }

    includeWhen(shellCommandSkillId, _matchesShellIntent(normalized));
    includeWhen(
      directoryOperationsSkillId,
      _containsAny(normalized, _directoryTerms),
    );
    includeWhen(fileOperationsSkillId, _containsAny(normalized, _fileTerms));
    includeWhen(skillInstallerSkillId, _matchesSkillIntent(normalized));
    includeWhen(mcpInstallerSkillId, _matchesMcpIntent(normalized));
    return Set<String>.unmodifiable(selected);
  }

  bool _matchesShellIntent(String query) =>
      _containsAny(query, _shellTerms) ||
      (_containsAny(query, _codeTerms) &&
          _containsAny(query, _processActionTerms));

  bool _matchesSkillIntent(String query) =>
      _containsAny(query, _skillTerms) && _containsAny(query, _managementTerms);

  bool _matchesMcpIntent(String query) =>
      _containsAny(query, _mcpTerms) &&
      (_containsAny(query, _managementTerms) ||
          _containsAny(query, _inspectionTerms));

  bool _containsAny(String source, Set<String> terms) =>
      terms.any((term) => _containsTerm(source, term));

  bool _containsTerm(String source, String term) {
    if (_containsCjk(term) || term.contains('.') || term.contains(' ')) {
      return source.contains(term);
    }
    return RegExp(
      r'(^|[^a-z0-9])' + RegExp.escape(term) + r'([^a-z0-9]|$)',
    ).hasMatch(source);
  }

  bool _containsCjk(String value) => RegExp(r'[\u3400-\u9fff]').hasMatch(value);

  static const Set<String> _directoryTerms = {
    'directory',
    'directories',
    'folder',
    'folders',
    'mkdir',
    '目录',
    '文件夹',
    '資料夾',
    'フォルダ',
    'ディレクトリ',
    '폴더',
    '디렉터리',
  };

  static const Set<String> _fileTerms = {
    'file',
    'files',
    'document',
    'documents',
    'filename',
    'filepath',
    'html',
    'css',
    'json',
    'yaml',
    'yml',
    'markdown',
    'csv',
    'xml',
    'resume',
    'save locally',
    'save to disk',
    '文件',
    '文档',
    '檔案',
    '文件路径',
    '文件路徑',
    '保存到本地',
    '储存到本地',
    '儲存到本機',
    '写入本地',
    '寫入本機',
    '简历页面',
    '履歷頁面',
    'ファイル',
    '파일',
  };

  static const Set<String> _shellTerms = {
    'shell',
    'terminal',
    'command line',
    'cli',
    'git',
    'npm',
    'pnpm',
    'yarn',
    'flutter',
    'dart',
    'cargo',
    'gradle',
    '命令',
    '终端',
    '終端',
    '命令行',
    '脚本',
    '腳本',
    '提交代码',
    '提交代碼',
    '新分支',
    'コマンド',
    '터미널',
  };

  static const Set<String> _codeTerms = {
    'code',
    'project',
    'package',
    '代码',
    '代碼',
    '项目',
    '專案',
  };

  static const Set<String> _processActionTerms = {
    'build',
    'test',
    'analyze',
    'compile',
    'run',
    '构建',
    '建置',
    '测试',
    '測試',
    '分析',
    '编译',
    '編譯',
    '运行',
    '執行',
  };

  static const Set<String> _skillTerms = {'skill', 'skills', '技能', 'スキル', '스킬'};

  static const Set<String> _mcpTerms = {'mcp', 'mcp server', 'mcp 服务器'};

  static const Set<String> _managementTerms = {
    'install',
    'add',
    'configure',
    'register',
    'remove',
    'uninstall',
    '安装',
    '安裝',
    '添加',
    '新增',
    '配置',
    '設定',
    '注册',
    '註冊',
    '删除',
    '移除',
  };

  static const Set<String> _inspectionTerms = {
    'list',
    'inspect',
    'show',
    'status',
    '列表',
    '查看',
    '检查',
    '檢查',
    '状态',
    '狀態',
  };
}
