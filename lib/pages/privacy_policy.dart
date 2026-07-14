import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String _markdownData = '';
  bool _isLoading = true;
  bool _loadStarted = false; // 添加标志，防止重复加载

  @override
  void initState() {
    super.initState();
    // 不在这里调用 _loadMarkdownData()
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里加载Markdown数据，确保context已完全初始化
    if (!_loadStarted) {
      _loadStarted = true;
      _loadMarkdownData();
    }
  }

  Future<void> _loadMarkdownData() async {
    // 获取当前语言代码
    final locale = Localizations.localeOf(context);
    final fallbackTitle = S.of(context).privacyPolicy;
    final fallbackError = S.of(context).errorLoadingContent;
    String languageCode = '${locale.languageCode}_${locale.countryCode}';

    // 尝试加载对应语言的文件
    try {
      _markdownData = await rootBundle.loadString(
        'assets/markdown/privacy_policy_$languageCode.md',
      );
    } catch (e) {
      // 如果找不到对应语言的文件，加载默认英文文件
      try {
        _markdownData = await rootBundle.loadString(
          'assets/markdown/privacy_policy_en_US.md',
        );
      } catch (e) {
        // 如果英文文件也找不到，显示错误信息
        _markdownData = '# $fallbackTitle\n\n$fallbackError';
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopPlatform(context)) {
      return _buildDesktopPage(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).privacyPolicy,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Markdown(
                data: _markdownData,
                padding: const EdgeInsets.all(16.0),
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  h2: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  p: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
    );
  }

  Widget _buildDesktopPage(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    final backTooltip = MaterialLocalizations.of(context).backButtonTooltip;

    return Scaffold(
      backgroundColor: shadTheme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: backTooltip,
                      child: ShadTooltip(
                        builder: (context) => Text(backTooltip),
                        child: ShadIconButton.ghost(
                          width: 32,
                          height: 32,
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      S.of(context).privacyPolicy,
                      style: shadTheme.textTheme.h4,
                    ),
                  ],
                ),
              ),
            ),
            const ShadSeparator.horizontal(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: Markdown(
                            data: _markdownData,
                            padding: const EdgeInsets.fromLTRB(32, 28, 32, 48),
                            styleSheet: _markdownStyle(context),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    final tokens = StarsDesktopTokens.of(context);
    return MarkdownStyleSheet(
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: tokens.primaryText,
      ),
      h2: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tokens.primaryText,
      ),
      p: TextStyle(
        fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
        height: 1.65,
        color: tokens.primaryText,
      ),
      blockquoteDecoration: BoxDecoration(
        color: tokens.controlFill,
        borderRadius: DesktopThemeTokens.containerRadius,
        border: Border(left: BorderSide(color: tokens.separator, width: 3)),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.separator)),
      ),
    );
  }
}
