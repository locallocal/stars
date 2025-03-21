import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:bubble/generated/l10n.dart';

class UserAgreementPage extends StatefulWidget {
  const UserAgreementPage({super.key});

  @override
  State<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends State<UserAgreementPage> {
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
    String languageCode = '${locale.languageCode}_${locale.countryCode}';

    // 尝试加载对应语言的文件
    try {
      _markdownData = await rootBundle.loadString(
        'assets/markdown/user_agreement_$languageCode.md',
      );
    } catch (e) {
      // 如果找不到对应语言的文件，加载默认英文文件
      try {
        _markdownData = await rootBundle.loadString(
          'assets/markdown/user_agreement_en_US.md',
        );
      } catch (e) {
        // 如果英文文件也找不到，显示错误信息
        _markdownData =
            '# ${S.of(context).userAgreement}\n\n${S.of(context).errorLoadingContent}';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).userAgreement,
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
}
