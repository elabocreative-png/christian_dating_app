import 'package:flutter/material.dart';

import 'help_support_screen.dart';
import 'widgets/legal_document_screen.dart';

/// Settings → Terms and Conditions.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const _lastUpdated = 'June 1, 2026';

  static const _sections = <LegalSection>[
    LegalSection(
      title: '1. Acceptance of these Terms',
      body:
          'By creating a ChristMeets account or using the app, you agree to '
          'these Terms and Conditions and our Privacy Policy. If you do not '
          'agree, do not use ChristMeets.',
    ),
    LegalSection(
      title: '2. Who may use ChristMeets',
      body:
          'You must be at least 18 years old and legally able to enter a '
          'binding agreement. ChristMeets is a Christian community platform '
          'for dating and social connection. You represent that the information '
          'you provide is accurate and that you will use the service respectfully '
          'and in good faith.',
    ),
    LegalSection(
      title: '3. Your account',
      body:
          'You are responsible for keeping your login credentials secure and '
          'for activity on your account. You may update your profile, deactivate '
          'your account temporarily, or delete your account from Settings. We may '
          'suspend or terminate accounts that violate these Terms or harm other '
          'members or the community.',
    ),
    LegalSection(
      title: '4. Community standards',
      body:
          'ChristMeets expects honest profiles, respectful communication, and '
          'conduct consistent with Christian values. You may not harass, abuse, '
          'threaten, impersonate, spam, solicit money, promote illegal activity, '
          'post explicit or hateful content, or use the app for commercial '
          'solicitation without permission. We provide tools to block and report '
          'other users; please use them when needed.',
    ),
    LegalSection(
      title: '5. Your content',
      body:
          'You retain ownership of content you submit, including photos, bio text, '
          'and messages. You grant ChristMeets a non-exclusive, worldwide license '
          'to host, display, and process your content solely to operate and improve '
          'the service. You confirm you have the right to share any content you '
          'upload and that it does not infringe others\' rights.',
    ),
    LegalSection(
      title: '6. Matching, discovery, and messaging',
      body:
          'ChristMeets helps you discover and connect with other members through '
          'likes, matches, and messaging. We do not guarantee matches, responses, '
          'or relationship outcomes. Features such as discovery mode, distance '
          'filters, and visibility may change over time.',
    ),
    LegalSection(
      title: '7. Location and notifications',
      body:
          'With your permission, ChristMeets uses your device location to show '
          'nearby profiles and distance information. You may control location and '
          'notification permissions in your device settings. Push notifications '
          'may include new matches and messages.',
    ),
    LegalSection(
      title: '8. Paid features',
      body:
          'Some features may become paid in the future. If we introduce paid '
          'services, we will present applicable pricing and billing terms before '
          'you are charged.',
    ),
    LegalSection(
      title: '9. Safety disclaimer',
      body:
          'Online interactions carry inherent risks. You are responsible for your '
          'choices when meeting people offline. ChristMeets does not conduct '
          'criminal background checks on users. Use caution, meet in public when '
          'appropriate, and report suspicious or harmful behavior through the app.',
    ),
    LegalSection(
      title: '10. Termination',
      body:
          'You may stop using ChristMeets at any time by deactivating or deleting '
          'your account. We may suspend or terminate access if you breach these '
          'Terms, create risk for others, or if required by law.',
    ),
    LegalSection(
      title: '11. Disclaimers and limitation of liability',
      body:
          'ChristMeets is provided "as is" and "as available" without warranties '
          'of any kind, to the fullest extent permitted by law. To the maximum '
          'extent permitted by applicable law, ChristMeets and its operators will '
          'not be liable for indirect, incidental, special, consequential, or '
          'punitive damages arising from your use of the service.',
    ),
    LegalSection(
      title: '12. Changes to these Terms',
      body:
          'We may update these Terms from time to time. Material changes will be '
          'communicated in the app or by other reasonable means. Continued use '
          'after changes take effect constitutes acceptance of the updated Terms.',
    ),
    LegalSection(
      title: '13. Contact',
      body:
          'Questions about these Terms may be sent to $kSupportEmail.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms and Conditions',
      lastUpdated: _lastUpdated,
      sections: _sections,
    );
  }
}
