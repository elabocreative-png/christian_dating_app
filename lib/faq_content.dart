/// ChristMeets help FAQ entries shown under Settings → ChristMeets FAQ.
class FaqItem {
  const FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

abstract final class ChristMeetsFaq {
  ChristMeetsFaq._();

  static const List<FaqItem> items = [
    FaqItem(
      question: 'What is ChristMeets?',
      answer:
          'ChristMeets is a Christian community app for meaningful dating and '
          'friendship. You can meet people who share your faith through profile '
          'discovery, likes, matches, and messaging—all in a respectful environment '
          'built for believers.',
    ),
    FaqItem(
      question: 'What is the difference between Dating and Social mode?',
      answer:
          'Dating mode is for romantic connection. Social mode is for Christian '
          'friendship and community. You choose a mode during onboarding and can '
          'change it later. You are only shown to people in the same mode, so '
          'dating profiles do not appear in social discovery and vice versa.',
    ),
    FaqItem(
      question: 'How do I discover new people?',
      answer:
          'Open the Discover tab to browse profiles near you. Swipe or use the '
          'action buttons to pass, like, or send an intro message. You can adjust '
          'distance and age preferences from discovery filters. Profiles you have '
          'already liked, matched with, or blocked will not appear again in your deck.',
    ),
    FaqItem(
      question: 'What is Liked You and how do Intros work?',
      answer:
          'Liked You shows people who liked your profile. The Likes tab lists '
          'standard likes; Intros includes likes that came with a message. The Sent '
          'tab shows profiles you have liked. Tap a profile to preview it and match '
          'or respond.',
    ),
    FaqItem(
      question: 'How do matches and messaging work?',
      answer:
          'When you and another member both like each other, you match and can chat '
          'in Messages. New Connections shows recent matches at the top of your inbox. '
          'Open a conversation from Messages to send and receive text. You will receive '
          'push notifications for new matches and messages if notifications are enabled.',
    ),
    FaqItem(
      question: 'How do I update my profile?',
      answer:
          'Go to the Profile tab and tap Edit Profile. You can update photos, bio, '
          'prompts, church details, faith preferences, and discovery settings. Changes '
          'save to your profile so other members see your latest information.',
    ),
    FaqItem(
      question: 'How do I block or report someone?',
      answer:
          'From a profile card, tap Block or Report at the bottom. Blocking hides '
          'someone from discovery, likes, and messages. You can manage blocked members '
          'in Settings → Blocked Members and unblock them from the list or their profile. '
          'To report a technical issue with the app, use Settings → Report an Issue.',
    ),
    FaqItem(
      question: 'What happens when I choose "Not for me"?',
      answer:
          'On a new connection or message preview, Not for me removes the match and '
          'conversation and returns that person to discovery so you can keep browsing. '
          'It is useful when a match is not the right fit but you still want to meet '
          'new people.',
    ),
    FaqItem(
      question: 'How do I unmatch with someone?',
      answer:
          'Open the member\'s profile from Messages or New Connections and use Unmatch '
          'when available. Unmatching removes the conversation and prevents further '
          'messaging between you and that person.',
    ),
    FaqItem(
      question: 'How do I deactivate or delete my account?',
      answer:
          'In Settings → Deactivate Account you can hide your profile while keeping '
          'your data. Sign in again anytime to reactivate. Settings → Delete Account '
          'permanently removes your account and profile data. Deactivation is reversible; '
          'deletion is not.',
    ),
    FaqItem(
      question: 'Why does ChristMeets need my location?',
      answer:
          'Location helps show distance on profiles and surface members near you. '
          'ChristMeets uses location only with your permission. You can change location '
          'access anytime in your device settings, though discovery works best when '
          'location is allowed while using the app.',
    ),
    FaqItem(
      question: 'How do I get help or contact support?',
      answer:
          'Visit Settings → Help & Support to email our team at support@christmeets.com. '
          'For app bugs or feedback, use Settings → Report an Issue. You can also review '
          'our Terms and Conditions and Privacy Policy in Settings.',
    ),
  ];
}
