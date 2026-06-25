import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';

/// ChristMeets-styled modal shell (logout, confirmations, action sheets).
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    required this.child,
  });

  final String title;
  final String? message;
  final Widget child;

  static const _titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Colors.black87,
  );

  static const _messageStyle = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: Colors.black54,
  );

  static ButtonStyle _filledBlackStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );
  }

  static ButtonStyle _outlinedStyle({Color foreground = Colors.black87}) {
    return OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: foreground == Colors.red ? Colors.red : Colors.black87),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );
  }

  static Widget cancelTextButton(
    BuildContext context, {
    VoidCallback? onPressed,
    String label = 'Cancel',
  }) {
    return TextButton(
      onPressed: onPressed ?? () => Navigator.pop(context),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, textAlign: TextAlign.center, style: _titleStyle),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: _messageStyle,
                  ),
                ],
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yes / no confirmation. Returns `true` when confirmed.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return AppDialog(
        title: title,
        message: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: AppDialog._filledBlackStyle(),
                child: Text(confirmLabel),
              ),
            ),
            const SizedBox(height: 6),
            AppDialog.cancelTextButton(
              ctx,
              label: cancelLabel,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      );
    },
  );
  return result == true;
}

/// One primary action + optional secondary + cancel (e.g. replace / remove photo).
Future<void> showAppActionDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool secondaryDestructive = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return AppDialog(
        title: title,
        message: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onPrimary();
                },
                style: AppDialog._filledBlackStyle(),
                child: Text(primaryLabel),
              ),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onSecondary();
                  },
                  style: AppDialog._outlinedStyle(
                    foreground:
                        secondaryDestructive ? Colors.red : Colors.black87,
                  ),
                  child: Text(secondaryLabel),
                ),
              ),
            ],
            const SizedBox(height: 6),
            AppDialog.cancelTextButton(ctx),
          ],
        ),
      );
    },
  );
}

/// Text entry modal (e.g. send intro message). Returns trimmed text or null.
Future<String?> showAppTextPromptDialog(
  BuildContext context, {
  required String title,
  String? message,
  String hintText = '',
  String confirmLabel = 'Send',
  int maxLines = 4,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return AppDialog(
        title: title,
        message: message,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: maxLines,
              minLines: 1,
              scrollPhysics: const ClampingScrollPhysics(),
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.dialogFieldInput(),
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E2E6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E2E6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black87, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx, text);
                },
                style: AppDialog._filledBlackStyle(),
                child: Text(confirmLabel),
              ),
            ),
            const SizedBox(height: 6),
            AppDialog.cancelTextButton(
              ctx,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    },
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  return result;
}
