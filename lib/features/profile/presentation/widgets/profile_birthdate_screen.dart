import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';

import 'package:christian_dating_app/core/widgets/onboarding_birthday_input.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';

/// Result from [ProfileBirthdateScreen.push].
typedef BirthdateEditResult = ({int age, String birthdayDigits});

/// Full-screen birthday entry (MM/DD/YYYY) that returns computed age.
class ProfileBirthdateScreen extends StatefulWidget {
  const ProfileBirthdateScreen({
    super.key,
    this.initialDigits = '',
  });

  /// Eight digits MMDDYYYY from Firestore or a prior edit session.
  final String initialDigits;

  static Future<BirthdateEditResult?> push(
    BuildContext context, {
    String initialDigits = '',
  }) {
    return context.push<BirthdateEditResult>(
      AppRoutes.profileEditBirthdateWith(initialDigits: initialDigits),
    );
  }

  @override
  State<ProfileBirthdateScreen> createState() => _ProfileBirthdateScreenState();
}

class _ProfileBirthdateScreenState extends State<ProfileBirthdateScreen> {
  String _digits = '';

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDigits.replaceAll(RegExp(r'\D'), '');
    if (seed.length == 8) {
      _digits = seed;
    }
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

  void _saveAndPop() {
    final age = _parseAge();
    if (age == null) {
      final message = _digits.length < 8
          ? 'Enter your full birthday (MM/DD/YYYY)'
          : 'Enter a valid birthday (you must be 18 or older)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    Navigator.pop(
      context,
      (age: age, birthdayDigits: _digits),
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
        leading: AppBackButton(onPressed: _saveAndPop),
        title: const Text(
          'Age',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your birthday',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We show your age, not your birthday.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OnboardingBirthdayInput(
              initialDigits: widget.initialDigits,
              onBirthdayChanged: (digits, _) {
                if (_digits != digits) {
                  setState(() => _digits = digits);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
