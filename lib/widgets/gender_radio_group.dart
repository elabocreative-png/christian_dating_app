import 'package:flutter/material.dart';

import 'package:christian_dating_app/core/constants/gender_options.dart';

/// Male / Female radio group used on sign up and in settings.
class GenderRadioGroup extends StatelessWidget {
  const GenderRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in kGenderOptions) ...[
          Expanded(
            child: InkWell(
              onTap: () => onChanged(option),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Radio<String>(
                      value: option,
                      groupValue: value,
                      onChanged: (_) => onChanged(option),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Flexible(
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
