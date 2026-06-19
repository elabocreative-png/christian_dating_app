import 'package:flutter/material.dart';

import 'app_icon.dart';

class ProfileSafetyTabContent extends StatelessWidget {
  const ProfileSafetyTabContent({super.key});

  void _showSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          _SafetyCard(
            icon: Icons.visibility_off_outlined,
            iconBackground: Colors.black87,
            iconColor: Colors.white,
            title: 'Turn on invisible mode',
            subtitle: 'Go invisible to browse privately',
            onTap: () => _showSoon(context, 'Invisible mode'),
          ),
          const SizedBox(height: 12),
          _SafetyCard(
            icon: Icons.shield_outlined,
            iconBackground: const Color(0xFFE1EBEA),
            iconColor: kBrandAccent,
            title: 'Manage your privacy',
            subtitle: 'Choose what information you share',
            onTap: () => _showSoon(context, 'Privacy settings'),
          ),
          const SizedBox(height: 12),
          _SafetyCard(
            icon: Icons.menu_book_outlined,
            iconBackground: const Color(0xFFE1EBEA),
            iconColor: kBrandAccent,
            title: 'Read our Community Guidelines',
            subtitle: 'Learn what we do and don\'t allow',
            onTap: () => _showSoon(context, 'Community Guidelines'),
          ),
        ],
      );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E8EA)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
