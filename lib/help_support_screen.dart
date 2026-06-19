import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_illustrations.dart';
import 'app_typography.dart';
import 'widgets/app_back_button.dart';
import 'widgets/app_icon.dart';

const String kSupportEmail = 'support@christmeets.com';

/// Settings → Help & Support with contact card.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kSupportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Support email copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Help & Support',
          style: AppTypography.bold(fontSize: 18, color: Colors.black87),
        ),
        leading: AppBackButton(
          color: Colors.black87,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: _WriteUsCard(onEmailTap: () => _copyEmail(context)),
      ),
    );
  }
}

class _WriteUsCard extends StatelessWidget {
  const _WriteUsCard({required this.onEmailTap});

  final VoidCallback onEmailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      size: 22,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Write Us',
                      style: AppTypography.bold(
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Facing issues with ChristMeets?',
                  style: AppTypography.extraBold(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: AppTypography.regular(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'We are ready to help you. Reach us on our business mail ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: onEmailTap,
                          child: Text(
                            kSupportEmail,
                            style: AppTypography.semiBold(
                              fontSize: 14,
                              color: kMatchOrange,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Padding(
          //   padding: const EdgeInsets.only(top: 4),
          //   child: SvgPicture.asset(
          //     AppIllustrations.supportEnvelope,
          //     width: 92,
          //     height: 102,
          //     fit: BoxFit.contain,
          //   ),
          // ),
        ],
      ),
    );
  }
}
