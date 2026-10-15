import 'package:stars/domain/models/models.dart';

/// Reads supported installer command syntax as data; never starts a process.
final class SkillSourceCommandParser {
  const SkillSourceCommandParser();

  List<String> parse(String input) {
    final source = input.trim();
    if (source.isEmpty || source.length > 4096 || source.contains('\u0000')) {
      throw const SkillInstallException('Skill 来源不能为空或超过 4096 个字符。');
    }
    if (!RegExp(r'^(npx|curl)\s').hasMatch(source)) return [source];
    final tokens = _tokenize(source);
    return tokens.first == 'npx' ? _parseNpx(tokens) : _parseCurl(tokens);
  }

  List<String> _parseNpx(List<String> tokens) {
    var index = 1;
    if (index < tokens.length && {'-y', '--yes'}.contains(tokens[index])) {
      index++;
    }
    if (index + 2 >= tokens.length ||
        !RegExp(r'^skills(?:@[A-Za-z0-9._-]+)?$').hasMatch(tokens[index]) ||
        tokens[index + 1] != 'add') {
      throw const SkillInstallException('支持的命令格式为 npx skills add <来源>。');
    }
    index += 2;
    String? source;
    while (index < tokens.length) {
      final token = tokens[index++];
      // These CLI flags select installation UX/destination. Stars always uses
      // its own package store and installation approval, regardless of them.
      if ({'-y', '--yes', '-g', '--global'}.contains(token)) continue;
      if (token == '-a' || token == '--agent') {
        if (index >= tokens.length ||
            !RegExp(r'^[a-z0-9-]+$').hasMatch(tokens[index++])) {
          throw const SkillInstallException('skills add 的 agent 参数无效。');
        }
        continue;
      }
      if (token.startsWith('-') || token == '|' || source != null) {
        throw const SkillInstallException(
          '请提供一个 Skill 来源；当前不支持此 skills add 选项或组合命令。',
        );
      }
      source = token;
    }
    if (source == null) throw const SkillInstallException('缺少 Skill 来源。');
    return [source];
  }

  List<String> _parseCurl(List<String> tokens) {
    final pipe = tokens.indexOf('|');
    if (pipe < 2 ||
        pipe + 4 >= tokens.length ||
        tokens.where((token) => token == '|').length != 1 ||
        tokens[pipe + 1] != 'bash' ||
        tokens[pipe + 2] != '-s' ||
        tokens[pipe + 3] != '--') {
      throw const SkillInstallException(
        '支持的安装脚本格式为 curl <ModelScope install.sh> | bash -s -- <技能 ID>。',
      );
    }
    String? script;
    for (final token in tokens.sublist(1, pipe)) {
      if (RegExp(r'^-[fsSL]+$').hasMatch(token) ||
          {
            '--fail',
            '--silent',
            '--show-error',
            '--location',
          }.contains(token)) {
        continue;
      }
      if (script != null || token.startsWith('-')) {
        throw const SkillInstallException('不支持此 curl 选项或组合命令。');
      }
      script = token;
    }
    final uri = Uri.tryParse(script ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        !{'modelscope.cn', 'www.modelscope.cn'}.contains(uri.host) ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.path != '/skills/install.sh') {
      throw const SkillInstallException('只支持 ModelScope 官方 install.sh 来源。');
    }
    final arguments = tokens.sublist(pipe + 4);
    final sources = <String>[];
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--agent') {
        if (++index >= arguments.length ||
            !RegExp(r'^[a-z0-9-]+$').hasMatch(arguments[index])) {
          throw const SkillInstallException('安装脚本的 agent 参数无效。');
        }
      } else if (argument == '--collection') {
        if (++index >= arguments.length || sources.isNotEmpty) {
          throw const SkillInstallException('请提供一个 ModelScope 合集 ID。');
        }
        sources.add(_modelScopeUrl('collections', arguments[index]));
      } else {
        if (sources.any((source) => source.contains('/collections/'))) {
          throw const SkillInstallException('合集不能与其他 Skill 来源混用。');
        }
        sources.add(_modelScopeUrl('skills', argument));
      }
    }
    if (sources.isEmpty) throw const SkillInstallException('缺少 Skill 来源。');
    return sources;
  }

  String _modelScopeUrl(String kind, String identifier) {
    if (!RegExp(r'^@?[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$').hasMatch(identifier)) {
      throw const SkillInstallException('ModelScope ID 必须为 owner/name。');
    }
    return 'https://www.modelscope.cn/$kind/$identifier';
  }

  List<String> _tokenize(String source) {
    final tokens = <String>[];
    var buffer = StringBuffer();
    String? quote;
    void flush() {
      if (buffer.isNotEmpty) tokens.add(buffer.toString());
      buffer = StringBuffer();
    }

    for (var index = 0; index < source.length; index++) {
      final character = source[index];
      if (r'$`;<> &()'.contains(character) && character != ' ') {
        throw const SkillInstallException('不支持命令替换、重定向或组合命令。');
      }
      if (character == '\\' && index + 1 < source.length) {
        if (source[index + 1] == '\n') {
          index++;
          continue;
        }
        throw const SkillInstallException('安装命令中不支持转义表达式。');
      }
      if (quote != null) {
        if (character == quote) {
          quote = null;
        } else {
          buffer.write(character);
        }
      } else if (character == '"' || character == "'") {
        quote = character;
      } else if (RegExp(r'\s').hasMatch(character)) {
        flush();
      } else if (character == '|') {
        flush();
        tokens.add('|');
      } else {
        buffer.write(character);
      }
    }
    if (quote != null) throw const SkillInstallException('安装命令的引号未闭合。');
    flush();
    return tokens;
  }
}
