import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/core/navigation/profile_edit_route_args.dart';

import 'package:christian_dating_app/core/widgets/app_back_button.dart';

/// Full-screen single-choice picker (replaces bottom sheets on Edit Profile).
class ProfileOptionPickerScreen extends StatelessWidget {
  const ProfileOptionPickerScreen({
    super.key,
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;

  static Future<String?> push(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? selected,
  }) {
    return context.push<String>(
      AppRoutes.profileEditOptions,
      extra: ProfileOptionPickerRouteArgs(
        title: title,
        options: options,
        selected: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Select one option',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ...options.map((option) {
            final isSelected = option == selected;
            return Column(
              children: [
                InkWell(
                  onTap: () => context.pop(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: Colors.black87,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE8E8EA),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
