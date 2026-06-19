import 'package:flutter/material.dart';

import 'app_icon.dart';

/// How the messages list is ordered / filtered on the Chats tab.
enum ChatMessagesSort {
  mostRecent,
  unread,
  yourMove,
}

extension ChatMessagesSortLabel on ChatMessagesSort {
  String get label => switch (this) {
        ChatMessagesSort.mostRecent => 'Most recent',
        ChatMessagesSort.unread => 'Unread',
        ChatMessagesSort.yourMove => 'Your move',
      };
}

/// Bottom sheet for choosing messages list sort / filter.
Future<ChatMessagesSort?> showChatMessagesSortSheet(
  BuildContext context, {
  required ChatMessagesSort selected,
}) {
  return showModalBottomSheet<ChatMessagesSort>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ...ChatMessagesSort.values.map(
                (option) => _SortOptionTile(
                  label: option.label,
                  selected: option == selected,
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: selected
              ? kBrandAccent.withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _SortRadio(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortRadio extends StatelessWidget {
  const _SortRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.black : Colors.grey.shade400,
          width: selected ? 6 : 1.5,
        ),
        color: Colors.white,
      ),
    );
  }
}
