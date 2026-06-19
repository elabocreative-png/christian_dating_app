import 'package:flutter/material.dart';

import 'help_support_screen.dart';
import 'widgets/legal_document_screen.dart';

/// Settings → Privacy Policy.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _lastUpdated = 'June 1, 2026';

  static const _sections = <LegalSection>[
    LegalSection(
      title: '1. Overview',
      body:
          'ChristMeets ("we", "us", or "our") respects your privacy. This Privacy '
          'Policy explains what information we collect when you use the ChristMeets '
          'mobile app, how we use it, and the choices available to you.',
    ),
    LegalSection(
      title: '2. Information we collect',
      body:
          'Account information: email address, password (stored securely by our '
          'authentication provider), and profile details you choose to provide '
          'such as name, age, gender, photos, bio, faith-related preferences, '
          'church information, prompts, and discovery settings.\n\n'
          'Usage and connection data: likes, matches, messages, blocks, reports, '
          'and in-app actions needed to operate discovery and chat features.\n\n'
          'Location data: with your permission, we collect approximate location '
          'to show distance and nearby profiles.\n\n'
          'Device and technical data: device identifiers, push notification tokens, '
          'app version, and diagnostic information used to deliver notifications '
          'and maintain service reliability.',
    ),
    LegalSection(
      title: '3. How we use information',
      body:
          'We use your information to create and manage your account, display your '
          'profile to other members according to your settings, recommend and rank '
          'profiles, enable messaging and matches, send service-related notifications, '
          'enforce community standards, improve ChristMeets, and respond to support '
          'requests or legal obligations.',
    ),
    LegalSection(
      title: '4. How information is shared',
      body:
          'Your profile information is visible to other ChristMeets members according '
          'to your discovery mode and app functionality. We do not sell your personal '
          'information.\n\n'
          'We use trusted service providers such as cloud hosting, authentication, '
          'storage, analytics, and messaging infrastructure to operate the app. These '
          'providers process data on our behalf under appropriate safeguards.\n\n'
          'We may disclose information if required by law, to protect rights and safety, '
          'or to investigate abuse, fraud, or violations of our Terms.',
    ),
    LegalSection(
      title: '5. Messages and user-generated content',
      body:
          'Messages you send through ChristMeets are stored so you and your match '
          'can view conversation history. Please do not share sensitive financial, '
          'medical, or government ID information in chat.',
    ),
    LegalSection(
      title: '6. Data retention',
      body:
          'We retain information while your account is active and as needed to provide '
          'the service. If you deactivate your account, your profile is hidden but '
          'your data is retained so you can reactivate by signing in again. If you '
          'delete your account, we delete or anonymize personal data within a '
          'reasonable period, except where retention is required for legal, security, '
          'or fraud-prevention purposes.',
    ),
    LegalSection(
      title: '7. Your choices and rights',
      body:
          'You can review and edit much of your profile in the app. You may block '
          'other members, deactivate your account, delete your account, and control '
          'location or notification permissions through your device settings.\n\n'
          'Depending on where you live, you may have additional rights to access, '
          'correct, or delete personal information. Contact us to make a request.',
    ),
    LegalSection(
      title: '8. Security',
      body:
          'We use administrative, technical, and organizational measures designed to '
          'protect your information. No method of transmission or storage is completely '
          'secure, and we cannot guarantee absolute security.',
    ),
    LegalSection(
      title: '9. Children\'s privacy',
      body:
          'ChristMeets is not intended for anyone under 18. We do not knowingly collect '
          'personal information from children. If you believe a minor has created an '
          'account, contact us so we can take appropriate action.',
    ),
    LegalSection(
      title: '10. International users',
      body:
          'ChristMeets may process and store information in countries other than where '
          'you live. By using the app, you understand that your information may be '
          'transferred to facilities operated by us or our service providers.',
    ),
    LegalSection(
      title: '11. Changes to this Policy',
      body:
          'We may update this Privacy Policy from time to time. We will post the '
          'updated version in the app and revise the "Last updated" date. Material '
          'changes may also be communicated through the app or by email where appropriate.',
    ),
    LegalSection(
      title: '12. Contact us',
      body:
          'For privacy questions or requests, email $kSupportEmail.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      lastUpdated: _lastUpdated,
      sections: _sections,
    );
  }
}
