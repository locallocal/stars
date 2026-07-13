import 'package:flutter/material.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/services/api_service.dart';
import 'package:stars/pages/common/common.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController feedbackController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    feedbackController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (feedbackController.text.trim().isEmpty || _isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 调用API服务发送反馈
      await ApiService.submitFeedback(
        content: feedbackController.text.trim(),
        contact: contactController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () {
            if (feedbackController.text.trim().isNotEmpty) {
              _submitFeedback();
            } else if (!_isSubmitting) {
              showWarningSnackBar(context, S.of(context).fillRequiredFields);
            }
          },
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
