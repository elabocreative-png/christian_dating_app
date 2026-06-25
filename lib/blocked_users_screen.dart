import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/services/block_service.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_users_service.dart';
import 'package:christian_dating_app/core/services/users_batch_loader.dart';
import 'widgets/app_back_button.dart';
import 'widgets/block_report_sheet.dart';
import 'widgets/profile_avatar.dart';
import 'widgets/user_profile_bottom_sheet.dart';

/// Settings → Blocked Users list with unblock actions.
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _openBlockedProfile(
    BuildContext context, {
    required BlockedUserRecord record,
    required Map<String, dynamic>? userData,
    required String name,
  }) async {
    final userWithDistance = userData == null
        ? <String, dynamic>{}
        : await DiscoveryUsersService.enrichWithDistance(userData);
    if (!context.mounted) return;

    showUserProfileBottomSheet(
      context,
      user: userWithDistance,
      profileUserId: record.blockedUserId,
      title: name,
      blockedUserId: record.blockedUserId,
    );
  }

  Future<void> _confirmUnblockFromList(
    BuildContext context, {
    required String blockedUserId,
    required String name,
  }) async {
    await confirmAndUnblockUser(
      context,
      blockedUserId: blockedUserId,
      displayName: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Blocked Members',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        leading: AppBackButton(
          color: Colors.black87,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: StreamBuilder<List<BlockedUserRecord>>(
        stream: BlockService.streamBlockedRecords(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!;
          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No blocked users',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            );
          }

          return FutureBuilder<Map<String, Map<String, dynamic>>>(
            key: ValueKey(records.map((r) => r.blockedUserId).join(',')),
            future: UsersBatchLoader.fetchByIds(
              records.map((r) => r.blockedUserId),
            ),
            builder: (context, usersSnapshot) {
              final userById = usersSnapshot.data ?? {};

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: records.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 0.6,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0xFFE5E7EB),
                ),
                itemBuilder: (context, index) {
                  final record = records[index];
                  final userData = userById[record.blockedUserId];
                  final name =
                      userData?['name']?.toString().trim().isNotEmpty == true
                          ? userData!['name'].toString().trim()
                          : 'User';

                  return _BlockedUserRow(
                    name: name,
                    userData: userData,
                    onTap: () => _openBlockedProfile(
                      context,
                      record: record,
                      userData: userData,
                      name: name,
                    ),
                    onUnblock: () => _confirmUnblockFromList(
                      context,
                      blockedUserId: record.blockedUserId,
                      name: name,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BlockedUserRow extends StatelessWidget {
  const _BlockedUserRow({
    required this.name,
    required this.userData,
    required this.onTap,
    required this.onUnblock,
  });

  final String name;
  final Map<String, dynamic>? userData;
  final VoidCallback onTap;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              ProfileAvatar(
                userData: userData ?? const {},
                radius: 26,
                backgroundColor: Colors.grey.shade300,
                iconColor: Colors.grey.shade600,
                iconSize: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onUnblock,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: const Color(0xFFF2F2F2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'unblock',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
