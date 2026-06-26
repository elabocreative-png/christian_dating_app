import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:christian_dating_app/core/constants/denomination_options.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/core/constants/gender_options.dart';
import 'package:christian_dating_app/features/auth/data/auth_service.dart';
import 'package:christian_dating_app/features/auth/data/auth_errors.dart';
import 'package:christian_dating_app/features/auth/domain/pending_signup.dart';
import 'package:christian_dating_app/onboarding/onboarding_requirements.dart';
import 'package:christian_dating_app/features/profile/data/profile_image_service.dart';
import 'package:christian_dating_app/core/constants/relationship_intent.dart';
import 'package:christian_dating_app/core/services/location_service.dart';
import 'package:christian_dating_app/widgets/local_profile_photo_grid.dart';
import 'package:christian_dating_app/core/widgets/onboarding_birthday_input.dart';
import 'package:christian_dating_app/features/onboarding/presentation/widgets/onboarding_pill_button.dart';
import 'package:christian_dating_app/features/onboarding/presentation/widgets/onboarding_step_shell.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_prompt_editor_section.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';
import 'package:christian_dating_app/core/services/push_notification_service.dart';
import 'package:christian_dating_app/features/onboarding/presentation/widgets/onboarding_faith_declaration_content.dart';
import 'package:christian_dating_app/features/onboarding/presentation/widgets/onboarding_notifications_step.dart';

/// Thirteen-step onboarding after sign-up (Bumble-style layout).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const int stepCount = 13;

  /// Bump saved [onboardingStep] when resuming users mid-flow after step changes.
  static const int onboardingFlowVersion = 4;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final AuthService _authService = AuthService();

  int _step = 0;
  bool _isSaving = false;
  bool _loadingDraft = true;

  final nameController = TextEditingController();
  final churchNameController = TextEditingController();
  int? _age;
  String _birthdayDigits = '';
  final aboutMeController = TextEditingController();

  String? denomination;
  String? lookingFor;
  String? gender;
  String? _discoveryMode;

  static const int _kMaxPhotos = 3;
  final List<File?> _photoSlots = List<File?>.filled(_kMaxPhotos, null);

  final List<ProfilePromptSlot> _promptSlots = List.generate(
    ProfilePromptEditorSection.slotCount,
    (_) => ProfilePromptSlot(),
  );

  bool _locationLoading = false;
  bool _notificationsLoading = false;
  UserLocationData? _pendingLocation;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  @override
  void dispose() {
    nameController.dispose();
    churchNameController.dispose();
    aboutMeController.dispose();
    super.dispose();
  }

  int get _photoCount => _photoSlots.where((f) => f != null).length;

  bool get _hasLocation => _pendingLocation != null;

  List<Map<String, String>> get _promptsForSave =>
      profilePromptsForFirestore(_promptSlots);

  /// Continue stays grey until this step's required inputs are satisfied.
  bool _primaryEnabledForStep(int step) {
    return switch (step) {
      0 => OnboardingRequirements.validateName(nameController.text) == null,
      1 => _age != null &&
          OnboardingRequirements.validateBirthday(_age) == null,
      2 => OnboardingRequirements.validateGender(gender) == null,
      3 => OnboardingRequirements.validateDenomination(denomination) == null,
      4 => true,
      5 => OnboardingRequirements.validateLookingFor(lookingFor) == null,
      6 => true,
      7 => true,
      8 => true,
      9 => OnboardingRequirements.validateDiscoveryMode(_discoveryMode) ==
          null,
      10 => true,
      11 => !_notificationsLoading,
      12 => !_locationLoading,
      _ => false,
    };
  }

  bool get _isDeferredSignup => PendingSignup.instance.isActive;

  Future<void> _loadDraft() async {
    if (_isDeferredSignup) {
      if (mounted) setState(() => _loadingDraft = false);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingDraft = false);
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (!mounted) return;

    loadProfilePromptSlots(_promptSlots, promptsRaw: data?['prompts']);

    setState(() {
      nameController.text = data?['name']?.toString() ?? '';
      final savedStep = (data?['onboardingStep'] as num?)?.round() ?? 0;
      final ageRaw = data?['age'];
      // Only restore age after the birthday step (avoids signup placeholder).
      final digits = data?['birthdayDigits']?.toString() ?? '';
      final normalized = digits.replaceAll(RegExp(r'\D'), '');
      if (normalized.length == 8) {
        _birthdayDigits = normalized;
      }
      if (savedStep > 1 && ageRaw is num) {
        final parsed = ageRaw.round();
        if (parsed >= 18 && parsed <= 80) _age = parsed;
      }
      aboutMeController.text = data?['aboutMe']?.toString() ?? '';
      if (savedStep > 3) {
        final d = data?['denomination']?.toString().trim();
        if (d != null && d.isNotEmpty) denomination = d;
      }
      if (savedStep > 4) {
        churchNameController.text = data?['churchName']?.toString() ?? '';
      }
      if (savedStep > 5 &&
          isValidLookingFor(data?['lookingFor']?.toString())) {
        lookingFor = displayLookingForLabel(data!['lookingFor']);
      }
      if (savedStep > 2) {
        gender = canonicalGender(data?['gender']?.toString());
      }
      final mode = data?['discoveryMode']?.toString();
      if (mode == kDiscoveryModeDating || mode == kDiscoveryModeSocial) {
        _discoveryMode = mode;
      }
      var resumeStep = (data?['onboardingStep'] as num?)?.round() ?? 0;
      final flowVersion =
          (data?['onboardingFlowVersion'] as num?)?.round() ?? 1;
      if (flowVersion < ProfileSetupScreen.onboardingFlowVersion) {
        if (flowVersion < 2 && resumeStep >= 4) resumeStep += 1;
        if (flowVersion < 3 && resumeStep >= 10) resumeStep += 1;
        if (flowVersion < 4 && resumeStep >= 11) resumeStep += 1;
      }
      if (resumeStep >= 0 &&
          resumeStep < ProfileSetupScreen.stepCount) {
        _step = resumeStep;
      }
      _loadingDraft = false;
    });
  }

  Future<bool> _showLocationSettingsDialog() async {
    final open = await showAppConfirmDialog(
      context,
      title: 'Location access',
      message:
          'ChristMeets needs location permission to show matches near you. '
          'Open Settings and allow location while using the app.',
      confirmLabel: 'Open Settings',
      cancelLabel: 'Not now',
    );
    if (open == true) {
      await Geolocator.openAppSettings();
    }
    return open == true;
  }

  Future<void> _allowLocation() async {
    setState(() => _locationLoading = true);
    try {
      final data = await LocationService.getCurrentUserLocation();
      if (!mounted) return;
      setState(() => _pendingLocation = data);
    } on LocationServiceDisabled catch (e) {
      if (!mounted) return;
      final enable = await showAppConfirmDialog(
        context,
        title: 'Turn on location',
        message: e.message,
        confirmLabel: 'Open Settings',
      );
      if (enable == true) {
        await Geolocator.openLocationSettings();
      }
    } on LocationPermissionDenied catch (e) {
      if (!mounted) return;
      if (e.deniedForever) {
        await _showLocationSettingsDialog();
      } else {
        _showError(
          'Location permission is required. Tap Allow location again and '
          'choose "While using the app" (or Precise) on the system dialog.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Could not get location: $e');
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<({List<String> photos, List<String> thumbs})> _uploadImages(
    String uid,
  ) async {
    final files = _photoSlots.whereType<File>().toList();
    if (files.isEmpty) {
      return (photos: <String>[], thumbs: <String>[]);
    }
    final uploaded = await ProfileImageService.uploadProfilePhotosParallel(
      files,
      uid,
    );
    return (
      photos: uploaded.map((u) => u.photoUrl).toList(),
      thumbs: uploaded.map((u) => u.thumbUrl).toList(),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDraft({required int nextStep}) async {
    if (_isDeferredSignup) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'name': nameController.text.trim(),
        if (_age != null) 'age': _age,
        if (_birthdayDigits.length == 8) 'birthdayDigits': _birthdayDigits,
        'aboutMe': aboutMeController.text.trim(),
        'denomination': denomination,
        'churchName': churchNameController.text.trim(),
        if (lookingFor != null) 'lookingFor': lookingFor,
        'gender': canonicalGender(gender),
        'discoveryMode': _discoveryMode,
        'prompts': _promptsForSave,
        'onboardingStep': nextStep,
        'onboardingFlowVersion': ProfileSetupScreen.onboardingFlowVersion,
        if (_pendingLocation != null)
          ...LocationService.firestoreFields(_pendingLocation!),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;

    final requiredErr = OnboardingRequirements.validateRequiredBeforeFinish(
      age: _age,
      denomination: denomination,
      lookingFor: lookingFor,
    );
    if (requiredErr != null) {
      _showError(requiredErr);
      return;
    }

    final locErr = OnboardingRequirements.validateLocation(
      hasLocation: _hasLocation,
    );
    if (locErr != null) {
      _showError(locErr);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pending = PendingSignup.instance;
      final isDeferred = pending.isActive;
      final pendingEmail = pending.email;
      final pendingPassword = pending.password;

      User user;
      if (isDeferred) {
        if (pendingEmail == null || pendingPassword == null) {
          throw Exception('Missing sign-up credentials');
        }
        user = await _authService.createOrSignInForDeferredSignup(
          pendingEmail,
          pendingPassword,
        );
      } else {
        final current = FirebaseAuth.instance.currentUser;
        if (current == null) {
          if (mounted) setState(() => _isSaving = false);
          return;
        }
        user = current;
      }

      final imageResult = await _uploadImages(user.uid);
      final mode = _discoveryMode ?? kDiscoveryModeDating;
      final profileData = <String, dynamic>{
        'name': nameController.text.trim(),
        'age': _age,
        if (_birthdayDigits.length == 8) 'birthdayDigits': _birthdayDigits,
        'aboutMe': aboutMeController.text.trim(),
        'denomination': denomination,
        'churchName': churchNameController.text.trim(),
        'lookingFor': lookingFor,
        'gender': canonicalGender(gender),
        'discoveryMode': mode,
        'datingDiscoveryEnabled': mode == kDiscoveryModeDating,
        'socialDiscoveryEnabled': mode == kDiscoveryModeSocial,
        'interestedIn': mode == kDiscoveryModeSocial
            ? defaultSocialInterestedIn()
            : defaultDatingInterestedIn(canonicalGender(gender)),
        'prompts': _promptsForSave,
        'photos': imageResult.photos,
        'photoThumbs': imageResult.thumbs,
        'profileComplete': true,
        'onboardingStep': ProfileSetupScreen.stepCount,
        'onboardingFlowVersion': ProfileSetupScreen.onboardingFlowVersion,
        'onboardingDiscoveryPrefsComplete': false,
      };

      if (_pendingLocation != null) {
        profileData.addAll(
          LocationService.firestoreFields(_pendingLocation!),
        );
      }

      if (isDeferred) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          ...AuthService.defaultUserFields(pendingEmail!),
          ...profileData,
        });
        pending.clear();
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));
      }

      await FirebaseAuth.instance.currentUser?.reload();
    } catch (e) {
      if (mounted) {
        _showError(
          e is FirebaseAuthException
              ? messageForAuthException(e)
              : 'Could not save profile: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _goNext() async {
    String? err;
    switch (_step) {
      case 0:
        err = OnboardingRequirements.validateName(nameController.text);
      case 1:
        err = OnboardingRequirements.validateBirthday(_age);
      case 2:
        err = OnboardingRequirements.validateGender(gender);
      case 3:
        err = OnboardingRequirements.validateDenomination(denomination);
      case 4:
        break;
      case 5:
        err = OnboardingRequirements.validateLookingFor(lookingFor);
      case 6:
        err = OnboardingRequirements.validatePhotos(_photoCount);
      case 7:
        break;
      case 8:
        break;
      case 9:
        err = OnboardingRequirements.validateDiscoveryMode(_discoveryMode);
    }

    if (err != null) {
      _showError(err);
      return;
    }

    if (_step < ProfileSetupScreen.stepCount - 1) {
      await _saveDraft(nextStep: _step + 1);
      if (!mounted) return;
      setState(() => _step++);
    }
  }

  Future<void> _goBack() async {
    if (_step == 0) {
      await _exitOnboardingToAuth();
      return;
    }
    setState(() => _step--);
  }

  Future<void> _exitOnboardingToAuth() async {
    PendingSignup.instance.clear();
    if (FirebaseAuth.instance.currentUser != null) {
      await _authService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingDraft) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return switch (_step) {
      0 => _buildNameStep(),
      1 => _buildBirthdayStep(),
      2 => _buildGenderStep(),
      3 => _buildDenominationStep(),
      4 => _buildChurchStep(),
      5 => _buildLookingForStep(),
      6 => _buildPhotosStep(),
      7 => _buildBioStep(),
      8 => _buildPromptsStep(),
      9 => _buildModeStep(),
      10 => _buildFaithDeclarationStep(),
      11 => _buildNotificationsStep(),
      12 => _buildLocationStep(),
      _ => _buildNameStep(),
    };
  }

  Widget _shell({
    required int stepIndex,
    required String title,
    String? subtitle,
    required Widget child,
    String primaryLabel = 'Continue',
    Widget? bottomHint,
    VoidCallback? onPrimary,
    bool? primaryEnabled,
    bool showPrimaryButton = true,
    bool showBackOnFirstStep = false,
  }) {
    return OnboardingStepShell(
      stepIndex: stepIndex,
      stepCount: ProfileSetupScreen.stepCount,
      title: title,
      subtitle: subtitle,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary ?? _goNext,
      onBack: _goBack,
      showBackOnFirstStep: showBackOnFirstStep,
      primaryEnabled: primaryEnabled ?? _primaryEnabledForStep(stepIndex),
      isLoading: stepIndex == 12 && _isSaving,
      showPrimaryButton: showPrimaryButton,
      bottomHint: bottomHint,
      child: child,
    );
  }

  Widget _buildNameStep() {
    return _shell(
      stepIndex: 0,
      showBackOnFirstStep: true,
      title: "What's your first name?",
      subtitle: 'This is how you will appear on ChristMeets.',
      child: TextField(
        controller: nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 40,
        style: AppTypography.onboardingFieldInput(),
        decoration: const InputDecoration(
          counterText: '',
          hintText: 'Your first name',
          border: UnderlineInputBorder(),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black87, width: 2),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBirthdayStep() {
    return _shell(
      stepIndex: 1,
      title: "When's your birthday?",
      subtitle:
          'Required. We use this to find the best matches for you (18+).',
      child: OnboardingBirthdayInput(
        initialDigits: _birthdayDigits,
        onBirthdayChanged: (digits, age) => setState(() {
          _birthdayDigits = digits;
          _age = age;
        }),
      ),
    );
  }

  Widget _buildGenderStep() {
    return _shell(
      stepIndex: 2,
      title: 'I am a…',
      subtitle: 'Required. Choose the option that best describes you.',
      child: Column(
        children: [
          for (final option in kGenderOptions)
            OnboardingPillButton(
              label: option,
              selected: gender == option,
              onTap: () => setState(() => gender = option),
            ),
        ],
      ),
    );
  }

  Widget _buildDenominationStep() {
    return _shell(
      stepIndex: 3,
      title: 'What is your denomination?',
      subtitle: 'Required. Pick the tradition that best fits your faith.',
      child: Column(
        children: [
          for (final option in kDenominationOptions)
            OnboardingPillButton(
              label: option,
              selected: denomination == option,
              onTap: () => setState(() => denomination = option),
            ),
        ],
      ),
    );
  }

  Widget _buildChurchStep() {
    return _shell(
      stepIndex: 4,
      title: 'What church do you attend?',
      subtitle: 'Optional. You can skip this and add it later in Edit Profile.',
      child: TextField(
        controller: churchNameController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 120,
        style: AppTypography.onboardingFieldInput(),
        decoration: const InputDecoration(
          counterText: '',
          hintText: 'Your church name',
          border: UnderlineInputBorder(),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black87, width: 2),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildLookingForStep() {
    return _shell(
      stepIndex: 5,
      title: 'What are you looking for?',
      subtitle: 'Required. What outcome would you like on ChristMeets?',
      child: Column(
        children: [
          for (final option in kLookingForOptions)
            OnboardingPillButton(
              label: option,
              selected: lookingFor == option,
              onTap: () => setState(() => lookingFor = option),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return _shell(
      stepIndex: 6,
      title: 'Add 3 photos of yourself',
      subtitle:
          'Upload photos where your face is clearly visible. You can change these later. Photos are optional for now.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalProfilePhotoGrid(
            slots: _photoSlots,
            maxPhotos: _kMaxPhotos,
            onSlotsChanged: (next) => setState(() {
              for (var i = 0; i < _kMaxPhotos; i++) {
                _photoSlots[i] = next[i];
              }
            }),
          ),
          const SizedBox(height: 24),
          const Text(
            'For the best experience:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _photoTipCard(
            icon: Icons.sentiment_satisfied_alt_outlined,
            title: 'Make sure your face is visible',
            subtitle: 'Matches love to see your smile',
          ),
          const SizedBox(height: 10),
          _photoTipCard(
            icon: Icons.photo_camera_outlined,
            title: 'Avoid using only selfies',
            subtitle: 'Candid shots often feel more natural',
          ),
        ],
      ),
    );
  }

  Widget _photoTipCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    final name = nameController.text.trim().isEmpty
        ? 'You'
        : nameController.text.trim();
    final bioLen = aboutMeController.text.length;

    return _shell(
      stepIndex: 7,
      title: 'Add your bio',
      subtitle:
          'Write something short and catchy. You can edit this later from your profile.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF0F0F2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'This is how you will appear to others',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBrandAccent, width: 1.5),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: [
                TextField(
                  controller: aboutMeController,
                  maxLength: 280,
                  maxLines: 6,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTypography.multilineFieldInput(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: 'Say something about yourself…',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${aboutMeController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '$bioLen/280',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptsStep() {
    return _shell(
      stepIndex: 8,
      title: 'What makes you, you?',
      subtitle:
          'Optional — add a prompt so people know what to message you about.',
      child: ProfilePromptEditorSection(
        slots: _promptSlots,
        onChanged: () => setState(() {}),
        showTip: true,
      ),
    );
  }

  Widget _buildModeStep() {
    return _shell(
      stepIndex: 9,
      title: 'What brings you to ChristMeets?',
      subtitle:
          'Romance or friendship? Choose a mode to find your people. You can change this later.',
      child: Column(
        children: [
          _modeCard(
            title: 'Dating',
            description:
                'Find a relationship, something casual, or anything in-between.',
            selected: _discoveryMode == kDiscoveryModeDating,
            onTap: () => setState(() => _discoveryMode = kDiscoveryModeDating),
          ),
          const SizedBox(height: 12),
          _modeCard(
            title: 'Social',
            description:
                'Make new friends and find your Christian community.',
            selected: _discoveryMode == kDiscoveryModeSocial,
            onTap: () => setState(() => _discoveryMode = kDiscoveryModeSocial),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.visibility_outlined, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You will only be shown to people in the same mode as you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const accent = OnboardingStepShell.accent;

    return Material(
      color: selected ? Colors.white : const Color(0xFFF6F6F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? accent : const Color(0xFFE5E7EB),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? accent : Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeFaithDeclaration() async {
    if (_step != 10) return;
    await _saveDraft(nextStep: 11);
    if (!mounted) return;
    setState(() => _step = 11);
  }

  Future<void> _advanceFromNotifications({required bool requestPermission}) async {
    if (_step != 11 || _notificationsLoading) return;

    setState(() => _notificationsLoading = true);
    try {
      if (requestPermission) {
        await PushNotificationService.requestUserPermission();
      }
      await _saveDraft(nextStep: 12);
      if (!mounted) return;
      setState(() => _step = 12);
    } finally {
      if (mounted) setState(() => _notificationsLoading = false);
    }
  }

  Widget _buildNotificationsStep() {
    return OnboardingNotificationsStep(
      stepIndex: 11,
      stepCount: ProfileSetupScreen.stepCount,
      isLoading: _notificationsLoading,
      onBack: _goBack,
      onRequestNotifications: () => _advanceFromNotifications(requestPermission: true),
      onSkip: () => _advanceFromNotifications(requestPermission: false),
    );
  }

  Widget _buildFaithDeclarationStep() {
    return _shell(
      stepIndex: 10,
      title: 'This is a crucial step',
      subtitle:
          'ChristMeets is a strictly Christian Dating App. We would like for '
          'you to confirm with us your Christian faith with a small step '
          'before you proceed',
      showPrimaryButton: false,
      child: OnboardingFaithDeclarationContent(
        userName: nameController.text.trim(),
        onHoldComplete: _completeFaithDeclaration,
      ),
    );
  }

  Widget _buildLocationStep() {
    return _shell(
      stepIndex: 12,
      title: 'Please allow location access',
      subtitle:
          'Your location will be used to show potential matches near you.',
      primaryLabel: _locationLoading
          ? 'Getting location…'
          : _isSaving
              ? 'Saving profile…'
              : _hasLocation
                  ? 'Finish'
                  : 'Allow location',
      primaryEnabled: !_locationLoading && !_isSaving,
      onPrimary: () async {
        if (!_hasLocation) {
          await _allowLocation();
          return;
        }
        await _finishOnboarding();
      },
      child: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
          if (_pendingLocation != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Text(
                _pendingLocation!.city.isNotEmpty
                    ? 'Location saved: ${_pendingLocation!.city}'
                    : 'Location saved successfully',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomHint: _locationLoading
          ? const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : null,
    );
  }

}
