import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/core/services/block_service.dart';
import 'package:christian_dating_app/core/models/block_source.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';

/// Confirms then unblocks a user. Returns `true` when unblock succeeded.
Future<bool> confirmAndUnblockUser(
  BuildContext context, {
  required String blockedUserId,
  String? displayName,
}) async {
  final confirmed = await showAppConfirmDialog(
    context,
    title: 'Unblock user',
    message: displayName == null || displayName.isEmpty
        ? 'Are you sure you want to unblock this person? '
            'They will appear in discovery, likes, and messages again.'
        : 'Are you sure you want to unblock $displayName? '
            'They will appear in discovery, likes, and messages again.',
    confirmLabel: 'Unblock',
  );
  if (confirmed != true || !context.mounted) return false;

  final ok = await BlockService.unblockUser(blockedUserId);
  if (!context.mounted) return ok;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not unblock user')),
    );
  }
  return ok;
}

/// Mini bottom sheet: Block or Report.
Future<void> showBlockReportSheet(
  BuildContext context, {
  required String blockedUserId,
  required BlockSource source,
  String? displayName,
  VoidCallback? onBlocked,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
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
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              _BlockReportOption(
                label: 'Block',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirmed = await showAppConfirmDialog(
                    context,
                    title: 'Block user',
                    message: displayName == null || displayName.isEmpty
                        ? 'Are you sure you want to block this person? '
                            'They will be hidden from discovery, likes, and messages.'
                        : 'Are you sure you want to block $displayName? '
                            'They will be hidden from discovery, likes, and messages.',
                    confirmLabel: 'Block',
                  );
                  if (confirmed != true || !context.mounted) return;

                  final ok = await BlockService.blockUser(
                    blockedUserId: blockedUserId,
                    source: source,
                  );
                  if (!context.mounted) return;
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not block user')),
                    );
                    return;
                  }
                  onBlocked?.call();
                },
              ),
              const SizedBox(height: 8),
              _BlockReportOption(
                label: 'Report',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report coming soon')),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BlockReportOption extends StatelessWidget {
  const _BlockReportOption({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Center(
            child: Text(
              label,
              style: AppTypography.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
