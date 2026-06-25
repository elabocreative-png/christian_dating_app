import 'package:flutter/material.dart';

/// Canonical interest labels (add here to scale the list across the app).
const List<String> kInterestOptions = [
  'Board games',
  'Concerts',
  'Hiking',
  'Marathons',
  'Podcasts',
  'Video Games',
  'Movies',
  'Karaoke',
  'Bible study',
  'Worship Night',
  'Evangelism',
  'Camping',
  'Art',
];

/// Maps legacy / misspelled saved values to canonical [kInterestOptions] entries.
String canonicalInterestLabel(String raw) {
  final t = raw.trim();
  switch (t) {
    case 'Podcats':
      return 'Podcasts';
    case 'Karaoki':
      return 'Karaoke';
    default:
      return t;
  }
}

IconData iconForInterestLabel(String label) {
  final key = canonicalInterestLabel(label);
  switch (key) {
    case 'Board games':
      return Icons.extension_outlined;
    case 'Concerts':
      return Icons.music_note;
    case 'Hiking':
      return Icons.hiking;
    case 'Marathons':
      return Icons.directions_run;
    case 'Podcasts':
      return Icons.podcasts_outlined;
    case 'Video Games':
      return Icons.sports_esports_outlined;
    case 'Movies':
      return Icons.movie_outlined;
    case 'Karaoke':
      return Icons.mic_none_outlined;
    case 'Bible study':
      return Icons.menu_book_outlined;
    case 'Worship Night':
      return Icons.queue_music_outlined;
    case 'Evangelism':
      return Icons.campaign_outlined;
    case 'Camping':
      return Icons.forest_outlined;
    case 'Art':
      return Icons.palette_outlined;
    default:
      return Icons.interests_outlined;
  }
}

/// Emoji shown beside each interest chip (profile card, edit profile).
String emojiForInterestLabel(String label) {
  final key = canonicalInterestLabel(label);
  switch (key) {
    case 'Board games':
      return '🎲';
    case 'Concerts':
      return '🎵';
    case 'Hiking':
      return '🥾';
    case 'Marathons':
      return '🏃';
    case 'Podcasts':
      return '🎧';
    case 'Video Games':
      return '🎮';
    case 'Movies':
      return '🎬';
    case 'Karaoke':
      return '🎤';
    case 'Bible study':
      return '📖';
    case 'Worship Night':
      return '🎶';
    case 'Evangelism':
      return '📢';
    case 'Camping':
      return '🏕️';
    case 'Art':
      return '🎨';
    default:
      return '✨';
  }
}
