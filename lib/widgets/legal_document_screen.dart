import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';

/// A titled section in a legal document (Terms, Privacy, etc.).
class LegalSection {
  const LegalSection({
    this.title,
    required this.body,
  });

  final String? title;
  final String body;
}

/// Scrollable legal document with consistent ChristMeets styling.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

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
          title,
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
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          32 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: $lastUpdated',
              style: AppTypography.regular(
                fontSize: 13,
                color: Colors.black45,
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 22),
              _LegalSectionBlock(section: sections[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalSectionBlock extends StatelessWidget {
  const _LegalSectionBlock({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          Text(
            section.title!,
            style: AppTypography.bold(
              fontSize: 16,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          section.body,
          style: AppTypography.regular(
            fontSize: 14,
            color: Colors.black54,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
