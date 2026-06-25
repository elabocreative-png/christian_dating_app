import 'package:flutter/material.dart';

import 'package:christian_dating_app/features/discovery/presentation/widgets/discovery_preferences_screen.dart';

/// Opens full-screen discovery preferences (legacy name kept for callers).
Future<bool?> showDiscoveryDistanceFilterSheet(BuildContext context) {
  return DiscoveryPreferencesScreen.push(context);
}
