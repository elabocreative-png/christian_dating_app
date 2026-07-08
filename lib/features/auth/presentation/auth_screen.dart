import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/features/auth/data/auth_errors.dart';
import 'package:christian_dating_app/features/auth/data/auth_repository.dart';
import 'package:christian_dating_app/features/auth/domain/pending_signup.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static const Color _accent = kBrandAccent;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLogin = true;
  bool _submitting = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password')),
      );
      return;
    }

    if (!isLogin) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the Terms and Privacy Policy'),
          ),
        );
        return;
      }
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')),
        );
        return;
      }
      if (password != confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      if (isLogin) {
        ref.read(pendingSignupProvider.notifier).clear();
        await ref.read(authRepositoryProvider).login(email, password);
      } else {
        ref.read(pendingSignupProvider.notifier).start(email, password);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageForAuthException(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'ChristMeets',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin ? 'Sign in to continue' : 'Create your account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: AppTypography.authFieldInput(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: AppTypography.authFieldInput(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (!isLogin) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: AppTypography.authFieldInput(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'I agree to the Terms of Service and Privacy Policy',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLogin ? 'Sign in' : 'Create account',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() {
                          isLogin = !isLogin;
                          confirmPasswordController.clear();
                        }),
                child: Text(
                  isLogin
                      ? 'Create an account'
                      : 'Already have an account? Sign in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
