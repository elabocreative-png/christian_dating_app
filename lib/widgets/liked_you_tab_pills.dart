import 'package:flutter/material.dart';

enum LikedYouListTab { likes, intros, sent }

/// Likes / Intros / Sent pill selector on [LikedYouScreen].
class LikedYouTabPills extends StatelessWidget {
  const LikedYouTabPills({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.likesCount,
    required this.introsCount,
    required this.sentCount,
  });

  final LikedYouListTab selected;
  final ValueChanged<LikedYouListTab> onChanged;
  final int likesCount;
  final int introsCount;
  final int sentCount;

  static const Color _pillFill = Color(0xFFF2F2F2);
  static const Color _selectedFill = Color(0xFF1C1C1E);
  static const Color _unselectedText = Color(0xFF5D5D5D);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _pill(
            label: 'Likes',
            count: likesCount,
            tab: LikedYouListTab.likes,
          ),
          const SizedBox(width: 8),
          _pill(
            label: 'Intros',
            count: introsCount,
            tab: LikedYouListTab.intros,
          ),
          const SizedBox(width: 8),
          _pill(
            label: 'Sent',
            count: sentCount,
            tab: LikedYouListTab.sent,
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required int count,
    required LikedYouListTab tab,
  }) {
    final isSelected = selected == tab;

    return Material(
      color: isSelected ? _selectedFill : _pillFill,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => onChanged(tab),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Text(
            '$label $count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : _unselectedText,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
