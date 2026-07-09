import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/features/settings/domain/faq_content.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';

/// Settings → ChristMeets FAQ list.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  void _openItem(BuildContext context, int index) {
    context.push(AppRoutes.settingsFaqItem(index));
  }

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
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < ChristMeetsFaq.items.length; i++) ...[
                  _FaqListTile(
                    item: ChristMeetsFaq.items[i],
                    onTap: () => _openItem(context, i),
                  ),
                  if (i < ChristMeetsFaq.items.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.6,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFE5E7EB),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqListTile extends StatelessWidget {
  const _FaqListTile({
    required this.item,
    required this.onTap,
  });

  final FaqItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.question,
                  style: AppTypography.regular(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
