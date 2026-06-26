import 'package:flutter/material.dart';

import 'package:christian_dating_app/features/auth/data/auth_service.dart';
import 'blocked_users_screen.dart';
import 'deactivate_account_screen.dart';
import 'faq_screen.dart';
import 'help_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'report_issue_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';

/// Settings list (Help, Report, Blocked, Delete, Deactivate, Terms, Privacy, FAQ).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _deletingAccount = false;
  bool _loggingOut = false;

  Future<void> _confirmLogout() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Log out',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
      if (!mounted) return;
      // Settings was pushed on the root navigator; pop it so AuthGate's
      // login screen is visible (auth already changed underneath).
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete account',
      message: 'Are you sure you want to delete your account?',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingAccount = true);
    try {
      await _authService.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_SettingsItem>[
      _SettingsItem(
        icon: Icons.headset_mic_outlined,
        label: 'Help & Support',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HelpSupportScreen(),
            ),
          );
        },
      ),
      _SettingsItem(
        icon: Icons.flag_outlined,
        label: 'Report an Issue',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ReportIssueScreen(),
            ),
          );
        },
      ),
      _SettingsItem(
        icon: Icons.block,
        label: 'Blocked Members',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BlockedUsersScreen(),
            ),
          );
        },
      ),
      _SettingsItem(
        icon: Icons.delete_outline,
        label: 'Delete Account',
        trailing: _deletingAccount
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        onTap: _deletingAccount ? null : _confirmDeleteAccount,
      ),
      _SettingsItem(
        icon: Icons.do_not_disturb_alt_outlined,
        label: 'Deactivate Account',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DeactivateAccountScreen(),
            ),
          );
        },
      ),
      _SettingsItem(
        icon: Icons.description_outlined,
        label: 'Terms and Conditions',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TermsAndConditionsScreen(),
            ),
          );
        },
      ),
      _SettingsItem(
        icon: Icons.verified_user_outlined,
        label: 'Privacy Policy',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const PrivacyPolicyScreen(),
            ),
          );
        },
      ),
      _SettingsItem(
        icon: Icons.help_outline,
        label: 'ChristMeets FAQ',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const FaqScreen(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        leading: AppBackButton(
          color: Colors.black87,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E7EB)),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 0.6,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0xFFE5E7EB),
                ),
                itemBuilder: (context, index) => _SettingsTile(item: items[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loggingOut ? null : _confirmLogout,
                  icon: _loggingOut
                      ? const SizedBox.shrink()
                      : const Icon(Icons.logout, size: 20),
                  label: _loggingOut
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black54,
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // UserReadOnlyEmail
            // Padding(
            //   padding: const EdgeInsets.only(bottom: 8),
            //
            //   // child: Text(
            //   //   email?.isNotEmpty == true ? email! : 'No email on file',
            //   //   textAlign: TextAlign.center,
            //   //   style: const TextStyle(
            //   //     color: Colors.black54,
            //   //     fontSize: 13,
            //   //     fontWeight: FontWeight.w500,
            //   //   ),
            //   // ),
            // ),

            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(item.icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
            if (item.trailing != null) item.trailing!,
          ],
        ),
      ),
    );
  }
}
