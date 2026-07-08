import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/core/constants/gender_options.dart';
import 'package:christian_dating_app/core/utils/geo_utils.dart';
import 'package:christian_dating_app/features/discovery/presentation/widgets/discovery_mode_toggle.dart';
import 'package:christian_dating_app/core/widgets/app_back_button.dart';

/// Full-screen discovery preferences (replaces the distance bottom sheet).
class DiscoveryPreferencesScreen extends ConsumerStatefulWidget {
  const DiscoveryPreferencesScreen({super.key});

  static Future<bool?> push(BuildContext context) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const DiscoveryPreferencesScreen()),
    );
  }

  @override
  ConsumerState<DiscoveryPreferencesScreen> createState() =>
      _DiscoveryPreferencesScreenState();
}

class _DiscoveryPreferencesScreenState
    extends ConsumerState<DiscoveryPreferencesScreen> {
  bool _loading = true;
  bool _saving = false;

  String _mode = kDiscoveryModeDating;
  int _distanceStopIndex = 4;
  int _minAge = kDefaultDiscoveryMinAge;
  int _maxAge = kDefaultDiscoveryMaxAge;
  String _interestedIn = kInterestedInMen;
  String? _viewerGender;

  late String _initialMode;
  late int _initialDistanceStopIndex;
  late int _initialMinAge;
  late int _initialMaxAge;
  late String _initialInterestedIn;

  bool get _filtersDirty =>
      _mode != _initialMode ||
      _distanceStopIndex != _initialDistanceStopIndex ||
      _minAge != _initialMinAge ||
      _maxAge != _initialMaxAge ||
      _interestedIn != _initialInterestedIn;

  void _captureInitialSnapshot() {
    _initialMode = _mode;
    _initialDistanceStopIndex = _distanceStopIndex;
    _initialMinAge = _minAge;
    _initialMaxAge = _maxAge;
    _initialInterestedIn = _interestedIn;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final data =
        await ref.read(discoveryRepositoryProvider).fetchViewerProfile(uid);
    final maxKm =
        (data['maxDistanceKm'] as num?)?.toDouble() ?? kDefaultMaxDistanceKm;
    final milesStop = discoveryMilesFromKm(maxKm);

    if (!mounted) return;
    setState(() {
      _viewerGender = canonicalGender(data['gender']?.toString());
      _mode = data['discoveryMode']?.toString() == kDiscoveryModeSocial
          ? kDiscoveryModeSocial
          : kDiscoveryModeDating;
      _distanceStopIndex = discoveryMilesStopIndex(milesStop);
      _minAge = (data['discoveryMinAge'] as num?)?.round() ??
          kDefaultDiscoveryMinAge;
      _maxAge = (data['discoveryMaxAge'] as num?)?.round() ??
          kDefaultDiscoveryMaxAge;
      _interestedIn = resolvedInterestedInForMode(
        data['interestedIn']?.toString(),
        _mode,
        viewerGender: _viewerGender,
      );
      _captureInitialSnapshot();
      _loading = false;
    });
  }

  void _popWithoutSaving() {
    if (mounted) Navigator.pop(context, false);
  }

  void _handleBack() {
    if (_saving) return;
    if (_filtersDirty) {
      _saveAndPop();
    } else {
      _popWithoutSaving();
    }
  }

  Future<void> _saveAndPop() async {
    if (_saving) return;
    if (!_filtersDirty) {
      _popWithoutSaving();
      return;
    }
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      _popWithoutSaving();
      return;
    }

    setState(() => _saving = true);
    try {
      final milesStop = kDistanceMilesStops[_distanceStopIndex];
      final maxKm = discoveryKmFromMilesStop(milesStop);

      await ref.read(discoveryRepositoryProvider).saveDiscoveryPreferences(
            uid,
            mode: _mode,
            maxDistanceKm: maxKm.round(),
            minAge: _minAge,
            maxAge: _maxAge,
            interestedIn: _interestedIn,
          );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _segmentedToggle() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment(
              label: 'Dating',
              selected: _mode == kDiscoveryModeDating,
              selectedFill: DiscoveryModeToggle.datingSelectedFill,
              onTap: () => setState(() {
                _mode = kDiscoveryModeDating;
                if (_interestedIn == kInterestedInAnyone) {
                  _interestedIn =
                      defaultDatingInterestedIn(_viewerGender);
                }
              }),
            ),
            _segment(
              label: 'Social',
              selected: _mode == kDiscoveryModeSocial,
              selectedFill: DiscoveryModeToggle.socialSelectedFill,
              onTap: () => setState(() {
                _mode = kDiscoveryModeSocial;
                _interestedIn = defaultSocialInterestedIn();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required Color selectedFill,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? selectedFill : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving && !_filtersDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _saving) return;
        _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: _saving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : AppBackButton(onPressed: _handleBack),
          title: const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _segmentedToggle(),
                  const SizedBox(height: 20),
                  Text(
                    _mode == kDiscoveryModeDating
                        ? 'Discover members in your area that are open to dates!'
                        : 'Make new friends, connect over mutual interests and expand your network.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(height: 1, color: Color(0xFFE8E8EA)),
                  const SizedBox(height: 24),
                  const Text(
                    'Distance (mi)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.black87,
                      inactiveTrackColor: const Color(0xFFE0E0E4),
                      thumbColor: Colors.black87,
                      overlayColor: Colors.black12,
                      trackHeight: 1.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _distanceStopIndex.toDouble(),
                      min: 0,
                      max: (kDistanceMilesStops.length - 1).toDouble(),
                      divisions: kDistanceMilesStops.length - 1,
                      onChanged: (v) =>
                          setState(() => _distanceStopIndex = v.round()),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: kDistanceMilesStops.map((stop) {
                      return Text(
                        discoveryDistanceStopLabel(stop),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: stop ==
                                  kDistanceMilesStops[_distanceStopIndex]
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Profiles within your set distance will be shown ahead of our expert, personalized picks!',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(height: 1, color: Color(0xFFE8E8EA)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Age',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '$_minAge - $_maxAge',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.black87,
                      inactiveTrackColor: const Color(0xFFE0E0E4),
                      thumbColor: Colors.black87,
                      overlayColor: Colors.black12,
                      trackHeight: 1.5,
                      rangeThumbShape:
                          const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: RangeSlider(
                      values: RangeValues(
                        _minAge.toDouble(),
                        _maxAge.toDouble(),
                      ),
                      min: 18,
                      max: 80,
                      divisions: 62,
                      onChanged: (values) {
                        var low = values.start.round();
                        var high = values.end.round();
                        if (high - low < 1) {
                          if (low > 18) {
                            low = high - 1;
                          } else {
                            high = low + 1;
                          }
                        }
                        setState(() {
                          _minAge = low;
                          _maxAge = high;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Divider(height: 1, color: Color(0xFFE8E8EA)),
                  const SizedBox(height: 24),
                  Text(
                    _mode == kDiscoveryModeDating
                        ? 'Who are you interested in'
                        : 'Who would you like to meet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_mode == kDiscoveryModeDating
                          ? kInterestedInDatingOptions
                          : kInterestedInSocialOptions)
                      .map((option) {
                    return RadioListTile<String>(
                      value: option,
                      groupValue: _interestedIn,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.black87,
                      title: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      onChanged: (v) {
                        if (v != null) setState(() => _interestedIn = v);
                      },
                    );
                  }),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade600,
                      ),
                      children: const [
                        TextSpan(
                          text:
                              'We use this to provide and personalize your experience. ',
                        ),
                        TextSpan(
                          text: 'Learn more.',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
