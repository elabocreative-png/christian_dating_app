import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/core/navigation/profile_edit_route_args.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';

/// Full-screen text editor for Basic Info fields on Edit Profile.
class ProfileTextFieldScreen extends StatefulWidget {
  const ProfileTextFieldScreen({
    super.key,
    required this.title,
    required this.initial,
    this.hint,
    this.subtitle,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });

  final String title;
  final String initial;
  final String? hint;
  final String? subtitle;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  static Future<String?> push(
    BuildContext context, {
    required String title,
    required String initial,
    String? hint,
    String? subtitle,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return context.push<String>(
      AppRoutes.profileEditText,
      extra: ProfileTextFieldRouteArgs(
        title: title,
        initial: initial,
        hint: hint,
        subtitle: subtitle,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
      ),
    );
  }

  @override
  State<ProfileTextFieldScreen> createState() => _ProfileTextFieldScreenState();
}

class _ProfileTextFieldScreenState extends State<ProfileTextFieldScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveAndPop() {
    context.pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle ?? 'Enter your ${widget.title.toLowerCase()}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(onPressed: _saveAndPop),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            style: AppTypography.profileFieldInput(),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.fieldHint(),
              counterText: '',
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE8E8EA)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black87, width: 1.5),
              ),
            ),
            onSubmitted: (_) => _saveAndPop(),
          ),
        ],
      ),
    );
  }
}
