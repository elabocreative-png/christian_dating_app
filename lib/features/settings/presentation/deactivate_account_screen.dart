import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/features/auth/data/auth_repository.dart';
import 'package:christian_dating_app/features/matches/presentation/match_read_providers.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';

/// Settings → Deactivate Account confirmation and reason form.
class DeactivateAccountScreen extends ConsumerStatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  ConsumerState<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState
    extends ConsumerState<DeactivateAccountScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _deactivate() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tell us why you want to deactivate your account'),
        ),
      );
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Deactivate account',
      message:
          'Your profile will be hidden from other users until you sign in again. '
          'Are you sure you want to deactivate your account?',
      confirmLabel: 'Deactivate',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).deactivateAccount(reason: reason);
      ref.read(matchReadStateProvider.notifier).clear();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasonFilled = _reasonController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Deactivate Account',
          style: AppTypography.bold(fontSize: 18, color: Colors.black87),
        ),
        leading: AppBackButton(
          color: Colors.black87,
          onPressed: _submitting
              ? () {}
              : () => Navigator.of(context).maybePop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to deactivate your account?',
                    style: AppTypography.extraBold(
                      fontSize: 22,
                      color: Colors.black87,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'If you deactivate your account, your profile will be hidden '
                    'from other users. You won\'t receive any messages or match '
                    'notifications, but your data and settings will remain intact. '
                    'You can reactivate your account anytime by simply logging in.',
                    style: AppTypography.regular(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text.rich(
                    TextSpan(
                      text: 'Why do you want to deactivate your account? ',
                      style: AppTypography.bold(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E2E6)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: TextField(
                      controller: _reasonController,
                      enabled: !_submitting,
                      minLines: 4,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTypography.multilineFieldInput(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: 'Share your reason…',
                      ),
                      onChanged: (_) => setState(() {}),
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
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting || !reasonFilled ? null : _deactivate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF2F2F2),
                    disabledForegroundColor: Colors.black45,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTypography.bold(fontSize: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Deactivate my account'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
