import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_typography.dart';

/// Inline MM / DD / YYYY entry for onboarding (Bumble-style underlines).
class OnboardingBirthdayInput extends StatefulWidget {
  const OnboardingBirthdayInput({
    super.key,
    this.initialDigits = '',
    required this.onBirthdayChanged,
  });

  /// Eight digits MMDDYYYY, restored when returning to this step.
  final String initialDigits;
  final void Function(String digits, int? age) onBirthdayChanged;

  @override
  State<OnboardingBirthdayInput> createState() =>
      _OnboardingBirthdayInputState();
}

class _OnboardingBirthdayInputState extends State<OnboardingBirthdayInput> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _hiddenController = TextEditingController();
  String _digits = '';

  static const List<String> _labels = [
    'M', 'M', 'D', 'D', 'Y', 'Y', 'Y', 'Y',
  ];

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDigits.replaceAll(RegExp(r'\D'), '');
    if (seed.length == 8) {
      _digits = seed;
      _hiddenController.text = seed;
    }
    _hiddenController.addListener(_onHiddenChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onBirthdayChanged(_digits, _parseAge());
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _hiddenController.removeListener(_onHiddenChanged);
    _hiddenController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onHiddenChanged() {
    final raw = _hiddenController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length > 8) {
      _hiddenController.value = TextEditingValue(
        text: raw.substring(0, 8),
        selection: const TextSelection.collapsed(offset: 8),
      );
      return;
    }
    if (raw != _digits) {
      setState(() => _digits = raw);
    }
    widget.onBirthdayChanged(_digits, _parseAge());
  }

  int? _parseAge() {
    if (_digits.length != 8) return null;

    final month = int.tryParse(_digits.substring(0, 2));
    final day = int.tryParse(_digits.substring(2, 4));
    final year = int.tryParse(_digits.substring(4, 8));
    if (month == null || day == null || year == null) return null;
    if (!_isValidDate(month, day, year)) return null;

    final birth = DateTime(year, month, day);
    final today = DateTime.now();
    if (birth.isAfter(today)) return null;

    var age = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      age--;
    }
    if (age < 18 || age > 120) return null;
    return age;
  }

  bool _isValidDate(int month, int day, int year) {
    if (month < 1 || month > 12) return false;
    if (year < 1900 || year > DateTime.now().year) return false;
    try {
      final dt = DateTime(year, month, day);
      return dt.year == year && dt.month == month && dt.day == day;
    } catch (_) {
      return false;
    }
  }

  String? _digitAt(int index) {
    if (index >= _digits.length) return null;
    return _digits[index];
  }

  @override
  Widget build(BuildContext context) {
    final focusIndex = _digits.length.clamp(0, 7);
    final age = _parseAge();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _DigitSlot(
                      label: _labels[0],
                      digit: _digitAt(0),
                      focused: focusIndex == 0,
                    ),
                    _DigitSlot(
                      label: _labels[1],
                      digit: _digitAt(1),
                      focused: focusIndex == 1,
                    ),
                    const _DateSlash(),
                    _DigitSlot(
                      label: _labels[2],
                      digit: _digitAt(2),
                      focused: focusIndex == 2,
                    ),
                    _DigitSlot(
                      label: _labels[3],
                      digit: _digitAt(3),
                      focused: focusIndex == 3,
                    ),
                    const _DateSlash(),
                    _DigitSlot(
                      label: _labels[4],
                      digit: _digitAt(4),
                      focused: focusIndex == 4,
                    ),
                    _DigitSlot(
                      label: _labels[5],
                      digit: _digitAt(5),
                      focused: focusIndex == 5,
                    ),
                    _DigitSlot(
                      label: _labels[6],
                      digit: _digitAt(6),
                      focused: focusIndex == 6,
                    ),
                    _DigitSlot(
                      label: _labels[7],
                      digit: _digitAt(7),
                      focused: focusIndex == 7,
                    ),
                  ],
                ),
                Opacity(
                  opacity: 0.01,
                  child: TextField(
                    controller: _hiddenController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    style: AppTypography.hiddenCaptureField(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (age != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF000000),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: "You're "),
                  TextSpan(
                    text: '$age',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: ' years old'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DigitSlot extends StatelessWidget {
  const _DigitSlot({
    required this.label,
    required this.digit,
    required this.focused,
  });

  final String label;
  final String? digit;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Column(
        children: [
          Text(
            digit ?? label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: digit != null ? Colors.black87 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            color: focused ? Colors.black87 : const Color(0xFFE0E0E4),
          ),
        ],
      ),
    );
  }
}

class _DateSlash extends StatelessWidget {
  const _DateSlash();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '/',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB0B0B8),
        ),
      ),
    );
  }
}
