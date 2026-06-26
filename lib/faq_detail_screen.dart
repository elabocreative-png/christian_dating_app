import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'faq_content.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';

/// Single FAQ question and answer.
class FaqDetailScreen extends StatelessWidget {
  const FaqDetailScreen({
    super.key,
    required this.item,
  });

  final FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "FAQ's",
          style: AppTypography.bold(fontSize: 18, color: Colors.black87),
        ),
        leading: AppBackButton(
          color: Colors.black87,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close, color: Colors.black87, size: 24),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.question,
                style: AppTypography.bold(
                  fontSize: 17,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.answer,
                style: AppTypography.regular(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
