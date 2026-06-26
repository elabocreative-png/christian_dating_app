import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/features/settings/data/issue_report_service.dart';
import 'package:christian_dating_app/core/photo/profile_photo_picker.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';

/// Settings → Report an Issue (feedback form).
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const Color _photoPlaceholder = Color(0xFFF0F0F2);
  static const Color _fieldBorder = Color(0xFFE2E2E6);

  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final files = await ProfilePhotoPicker.pickAndCropFromGallery(
      context,
      _picker,
      maxCount: 1,
      allowMultiple: false,
    );
    if (files.isEmpty || !mounted) return;
    setState(() => _image = files.first);
  }

  Future<void> _showImageActions() async {
    await showAppActionDialog(
      context,
      title: 'Replace or remove?',
      primaryLabel: 'Replace',
      onPrimary: _pickImage,
      secondaryLabel: 'Remove',
      onSecondary: () => setState(() => _image = null),
    );
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your problem')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final ok = await IssueReportService.submit(
        description: description,
        image: _image,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send report. Please try again.')),
        );
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your report was sent')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.semiBold(fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _fieldBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: TextField(
        controller: _descriptionController,
        enabled: !_submitting,
        minLines: 5,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        style: AppTypography.multilineFieldInput(),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          hintText: 'Type your problem',
          hintStyle: AppTypography.regular(
            fontSize: 16,
            color: Colors.black38,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildOptionalImagePicker() {
    const slotWidth = 132.0;
    const slotHeight = 188.0;

    Widget child;
    if (_image == null) {
      child = Material(
        color: _photoPlaceholder,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _submitting ? null : _pickImage,
          child: const Center(
            child: Icon(
              Icons.add,
              size: 36,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
      );
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              _image!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withValues(alpha: 0.75),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _submitting ? null : _showImageActions,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: slotWidth,
      height: slotHeight,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _descriptionController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Report',
          style: AppTypography.bold(fontSize: 20, color: Colors.black87),
        ),
        leading: AppBackButton(
          color: Colors.black87,
          onPressed:
              _submitting ? () {} : () => Navigator.of(context).maybePop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 0.6, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Report an issue'),
                  const SizedBox(height: 12),
                  _buildDescriptionField(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Picture (optional)'),
                  const SizedBox(height: 12),
                  _buildOptionalImagePicker(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting || !canSubmit ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF2F2F2),
                    disabledForegroundColor: Colors.black45,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: AppTypography.bold(fontSize: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Report'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
