import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/legal_document.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/profile/view_models/legal_document_view_model.dart';
import 'package:stars/ui/features/profile/views/legal_document_header.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/utils/utils.dart';

/// Displays the localized privacy policy bundled with the application.
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key, this.viewModel});

  final LegalDocumentViewModel? viewModel;

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  LegalDocumentViewModel? _resolvedViewModel;
  bool _loadStarted = false;

  LegalDocumentViewModel get _viewModel =>
      widget.viewModel ?? _resolvedViewModel!;
  String get _markdownData => _viewModel.content;
  bool get _isLoading => _viewModel.isLoading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    _resolvedViewModel =
        widget.viewModel ??
        AppScope.of(
          context,
        ).createLegalDocumentViewModel(LegalDocumentType.privacyPolicy);
    _viewModel.addListener(_handleViewModelChanged);
    final locale = Localizations.localeOf(context);
    final localeName = '${locale.languageCode}_${locale.countryCode}';
    unawaited(
      _viewModel.load(
        localeName: localeName,
        fallbackContent:
            '# ${S.of(context).privacyPolicy}\n\n'
            '${S.of(context).errorLoadingContent}',
      ),
    );
  }

  void _handleViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_loadStarted) _viewModel.removeListener(_handleViewModelChanged);
    if (widget.viewModel == null) _resolvedViewModel?.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: shadTheme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            LegalDocumentHeader(title: S.of(context).privacyPolicy),
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
        borderRadius: StarsDesktopThemeSpec.containerRadius,
        border: Border(left: BorderSide(color: tokens.separator, width: 3)),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.separator)),
      ),
    );
  }
}
