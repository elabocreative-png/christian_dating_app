import 'package:christian_dating_app/gender_options.dart';

const String kDiscoveryModeDating = 'dating';
const String kDiscoveryModeSocial = 'social';

const String kInterestedInMen = 'Men';
const String kInterestedInWomen = 'Women';
const String kInterestedInAnyone = 'Anyone';

const List<String> kInterestedInDatingOptions = [
  kInterestedInMen,
  kInterestedInWomen,
];

const List<String> kInterestedInOptions = [
  kInterestedInMen,
  kInterestedInWomen,
  kInterestedInAnyone,
];

const List<String> kInterestedInSocialOptions = [
  kInterestedInAnyone,
  kInterestedInMen,
  kInterestedInWomen,
];

/// Distance slider stops in miles; last entry is "Max".
const List<int> kDistanceMilesStops = [20, 30, 40, 50, 60, -1];

const int kDefaultDiscoveryMinAge = 18;
const int kDefaultDiscoveryMaxAge = 40;

const double _milesPerKm = 0.621371;

int discoveryMilesFromKm(double km) {
  if (km >= 299) return -1;
  final miles = (km * _milesPerKm).round();
  var best = kDistanceMilesStops.first;
  var bestDiff = 9999;
  for (final stop in kDistanceMilesStops) {
    if (stop < 0) continue;
    final diff = (miles - stop).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = stop;
    }
  }
  return best;
}

double discoveryKmFromMilesStop(int milesStop) {
  if (milesStop < 0) return 300;
  return milesStop / _milesPerKm;
}

int discoveryMilesStopIndex(int milesStop) {
  if (milesStop < 0) return kDistanceMilesStops.length - 1;
  final i = kDistanceMilesStops.indexOf(milesStop);
  return i >= 0 ? i : 2;
}

String discoveryDistanceStopLabel(int milesStop) {
  if (milesStop < 0) return 'Max';
  return '$milesStop';
}

String? canonicalInterestedIn(String? raw) {
  final t = raw?.trim() ?? '';
  if (kInterestedInOptions.contains(t)) return t;
  return null;
}

String resolvedInterestedIn(String? raw) {
  return canonicalInterestedIn(raw) ?? kInterestedInAnyone;
}

String defaultSocialInterestedIn() => kInterestedInAnyone;

String resolvedInterestedInForMode(
  String? raw,
  String mode, {
  String? viewerGender,
}) {
  if (mode == kDiscoveryModeDating) {
    final canonical = canonicalInterestedIn(raw);
    if (canonical == kInterestedInMen || canonical == kInterestedInWomen) {
      return canonical!;
    }
    return defaultDatingInterestedIn(viewerGender);
  }
  return canonicalInterestedIn(raw) ?? defaultSocialInterestedIn();
}

/// When switching discovery mode, pick the default interested-in for that mode.
String interestedInForModeSwitch({
  required String newMode,
  required String? currentInterestedIn,
  required String? viewerGender,
}) {
  if (newMode == kDiscoveryModeSocial) {
    return defaultSocialInterestedIn();
  }
  final canonical = canonicalInterestedIn(currentInterestedIn);
  if (canonical == kInterestedInAnyone) {
    return defaultDatingInterestedIn(viewerGender);
  }
  if (canonical == kInterestedInMen || canonical == kInterestedInWomen) {
    return canonical!;
  }
  return defaultDatingInterestedIn(viewerGender);
}

/// Dating default: opposite of the viewer's gender (Men if woman, Women if man).
String defaultDatingInterestedIn(String? viewerGender) {
  final gender = canonicalGender(viewerGender);
  if (gender == kGenderFemale) return kInterestedInMen;
  if (gender == kGenderMale) return kInterestedInWomen;
  return kInterestedInMen;
}

bool profileMatchesInterestedIn(String interestedIn, Map<String, dynamic> profile) {
  if (interestedIn == kInterestedInAnyone) return true;
  final gender = canonicalGender(profile['gender']?.toString());
  if (gender == null) return false;
  if (interestedIn == kInterestedInMen) return gender == kGenderMale;
  if (interestedIn == kInterestedInWomen) return gender == kGenderFemale;
  return true;
}

String normalizeDiscoveryMode(String? raw) {
  return raw == kDiscoveryModeSocial ? kDiscoveryModeSocial : kDiscoveryModeDating;
}

/// Gender filter for the active discovery deck.
///
/// Dating shows the opposite gender; social shows everyone.
String interestedInForDiscoveryDeck(String mode, {String? viewerGender}) {
  if (mode == kDiscoveryModeSocial) return kInterestedInAnyone;
  return defaultDatingInterestedIn(viewerGender);
}

/// True when a prior like or match in one mode should hide someone on [deckMode].
bool shouldExcludeUserFromDiscoveryDeck({
  required String deckMode,
  required String? interactionMode,
}) {
  if (interactionMode == null) return false;

  final deck = normalizeDiscoveryMode(deckMode);
  final interaction = normalizeDiscoveryMode(interactionMode);

  if (interaction == deck) return true;
  if (interaction == kDiscoveryModeDating && deck == kDiscoveryModeSocial) {
    return true;
  }
  if (interaction == kDiscoveryModeSocial && deck == kDiscoveryModeDating) {
    return true;
  }
  return false;
}

/// Resolves dating/social mode per other user from outgoing likes, then incoming.
Map<String, String> interactionModeByUserId({
  required Iterable<Map<String, dynamic>> outgoingLikes,
  required Iterable<Map<String, dynamic>> incomingLikes,
  required Set<String> matchedUserIds,
}) {
  final modes = <String, String>{};

  for (final data in outgoingLikes) {
    final targetId = data['toUserId']?.toString() ?? '';
    if (targetId.isEmpty) continue;
    modes[targetId] = normalizeDiscoveryMode(data['discoveryMode']?.toString());
  }

  for (final otherUserId in matchedUserIds) {
    if (modes.containsKey(otherUserId)) continue;
    for (final data in incomingLikes) {
      if (data['fromUserId']?.toString() == otherUserId) {
        modes[otherUserId] =
            normalizeDiscoveryMode(data['discoveryMode']?.toString());
        break;
      }
    }
  }

  return modes;
}
