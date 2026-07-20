import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/pages/common/common.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/feedback/view_models/feedback_view_model.dart';
import 'package:stars/utils/utils.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, this.viewModel});

  final FeedbackViewModel? viewModel;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  FeedbackViewModel? _resolvedViewModel;

  FeedbackViewModel get _viewModel => widget.viewModel ?? _resolvedViewModel!;
  bool get _isSubmitting => _viewModel.isSubmitting;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolvedViewModel ??=
        widget.viewModel == null
            ? AppScope.of(context).createFeedbackViewModel()
            : null;
  }

  @override
  void dispose() {
    feedbackController.dispose();
    contactController.dispose();
    _resolvedViewModel?.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (feedbackController.text.trim().isEmpty || _isSubmitting) {
      return;
    }
    final succeeded = await _viewModel.submit(
      content: feedbackController.text,
      contact: contactController.text,
    );
    if (succeeded && mounted) Navigator.pop(context);
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }
    if (feedbackController.text.trim().isEmpty) {
      showWarningSnackBar(context, S.of(context).fillRequiredFields);
      return;
    }
    await _submitFeedback();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    if (isDesktopPlatform(context)) {
      return _buildDesktopPage(context);
    }
    return _buildMobilePage(context);
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
                    if (Navigator.of(context).canPop()) ...[
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
                      const SizedBox(width: 8),
                    ],
                    Text(
                      S.of(context).helpAndFeedback,
                      style: shadTheme.textTheme.h4,
                    ),
                  ],
                ),
              ),
            ),
            const ShadSeparator.horizontal(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ShadCard(
                      width: double.infinity,
                      title: const Text('反馈信息'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ShadTextarea(
                              controller: feedbackController,
                              placeholder: Text(
                                S.of(context).feedbackDescription,
                              ),
                              leading: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                              ),
                              minHeight: 160,
                              maxHeight: 320,
                            ),
                            const SizedBox(height: 16),
                            ShadInput(
                              controller: contactController,
                              placeholder: Text(S.of(context).contactInfoHint),
                              leading: const Icon(
                                Icons.email_outlined,
                                size: 18,
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleSubmit(),
                            ),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ShadButton(
                                enabled: !_isSubmitting,
                                onPressed: _isSubmitting ? null : _handleSubmit,
                                leading:
                                    _isSubmitting
                                        ? SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                shadTheme
                                                    .colorScheme
                                                    .primaryForeground,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.send_outlined,
                                          size: 17,
                                        ),
                                child: Text(S.of(context).submitFeedback),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePage(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyLarge?.fontSize;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          S.of(context).helpAndFeedback,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息分组
            buildSectionContainer(context, '反馈信息', [
              _buildFeedbacktInput(fontSize),
              _buildContactInput(fontSize),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
              side: BorderSide.none,
            ),
          ),
          onPressed: _handleSubmit,
          child:
              _isSubmitting
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                  : Text(
                    S.of(context).submitFeedback,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildFeedbacktInput(double? fontSize) {
    return TextField(
      controller: feedbackController,
      decoration: InputDecoration(
        hintText: S.of(context).feedbackDescription,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      maxLines: 6,
    );
  }

  Widget _buildContactInput(double? fontSize) {
    return TextField(
      controller: contactController,
      decoration: InputDecoration(
        hintText: S.of(context).contactInfoHint,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        prefixIcon: Icon(
          Icons.email,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
