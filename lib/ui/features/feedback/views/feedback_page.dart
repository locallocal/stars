import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/core/widgets/common.dart';
import 'package:stars/ui/core/widgets/desktop_page_header.dart';
import 'package:stars/ui/features/feedback/view_models/feedback_view_model.dart';
import 'package:stars/utils/theme.dart';
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
      showStarsNotice(
        context,
        S.of(context).feedbackContentRequired,
        tone: StarsNoticeTone.warning,
      );
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

    return Scaffold(
      backgroundColor: shadTheme.colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            StarsDesktopPageHeader(
              title: S.of(context).helpAndFeedback,
              showBackButton: Navigator.of(context).canPop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ShadCard(
                      width: double.infinity,
                      title: Text(S.of(context).feedbackInformation),
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
                              key: const ValueKey<String>(
                                'feedback-contact-input',
                              ),
                              controller: contactController,
                              placeholder: Text(S.of(context).contactInfoHint),
                              leading: const SizedBox(
                                width: 17,
                                height: 30,
                                child: Center(
                                  child: Icon(Icons.email_outlined, size: 17),
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minHeight:
                                    StarsDesktopThemeSpec.botFormFieldHeight,
                              ),
                              alignment: AlignmentDirectional.centerStart,
                              placeholderAlignment:
                                  AlignmentDirectional.centerStart,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleSubmit(),
                            ),
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ShadButton(
                                key: const ValueKey<String>(
                                  'feedback-submit-button',
                                ),
                                crossAxisAlignment: CrossAxisAlignment.center,
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
            buildSectionContainer(context, S.of(context).feedbackInformation, [
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
