import 'package:flutter/material.dart';

/// "Use current location" control shown beside the city field.
class UseCurrentLocationRow extends StatelessWidget {
  const UseCurrentLocationRow({
    super.key,
    required this.loading,
    required this.onPressed,
    this.locationHint,
  });

  final bool loading;
  final VoidCallback onPressed;
  final String? locationHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_outlined, size: 20),
          label: Text(loading ? 'Getting location…' : 'Use current location'),
        ),
        if (locationHint != null && locationHint!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            locationHint!,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}
