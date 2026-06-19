import 'package:flutter/material.dart';

import '../app_typography.dart';

import 'app_dialog.dart';
import 'app_back_button.dart';

/// Result from [OnboardingPromptAnswerScreen.push].
class PromptAnswerPushResult {
  const PromptAnswerPushResult._({this.answer, this.wasRemoved = false});

  final String? answer;
  final bool wasRemoved;

  static const cancelled = PromptAnswerPushResult._();
  static PromptAnswerPushResult saved(String answer) =>
      PromptAnswerPushResult._(answer: answer);
  static const removed = PromptAnswerPushResult._(wasRemoved: true);
}

/// Full-screen prompt answer entry (Bumble-style).
class OnboardingPromptAnswerScreen extends StatefulWidget {
  const OnboardingPromptAnswerScreen({
    super.key,
    required this.question,
    this.initialAnswer = '',
    this.showRemove = false,
  });

  final String question;
  final String initialAnswer;
  final bool showRemove;

  static Future<PromptAnswerPushResult> push(
    BuildContext context, {
    required String question,
    String initialAnswer = '',
    bool showRemove = false,
  }) async {
    final result = await Navigator.push<PromptAnswerPushResult>(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingPromptAnswerScreen(
          question: question,
          initialAnswer: initialAnswer,
          showRemove: showRemove,
        ),
      ),
    );
    return result ?? PromptAnswerPushResult.cancelled;
  }

  @override
  State<OnboardingPromptAnswerScreen> createState() =>
      _OnboardingPromptAnswerScreenState();
}

class _OnboardingPromptAnswerScreenState
    extends State<OnboardingPromptAnswerScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialAnswer);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _removePrompt() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Remove prompt?',
      message:
          'This will clear your prompt and answer from your profile.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !mounted) return;
    Navigator.pop(context, PromptAnswerPushResult.removed);
  }

  @override
  Widget build(BuildContext context) {
    final len = _controller.text.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Your answer',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (widget.showRemove)
            TextButton(
              onPressed: _removePrompt,
              child: Text(
                'Remove',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    maxLength: 160,
                    maxLines: 6,
                    minLines: 4,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.multilineFieldInput(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      hintText: 'Write your answer…',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$len/160',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(
                            context,
                            PromptAnswerPushResult.saved(
                              _controller.text.trim(),
                            ),
                          ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE8E8EA),
                    disabledForegroundColor: const Color(0xFF9E9EA4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
