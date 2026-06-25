import 'package:flutter/material.dart';

import 'package:christian_dating_app/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:christian_dating_app/features/profile/domain/profile_completion.dart';
import 'package:christian_dating_app/features/profile/data/profile_image_service.dart';
import 'package:christian_dating_app/profile_photo_picker.dart';
import 'package:christian_dating_app/denomination_options.dart';
import 'package:christian_dating_app/tongues_options.dart';
import 'package:christian_dating_app/church_attendance_options.dart';
import 'package:christian_dating_app/faith_options.dart';
import 'package:christian_dating_app/gender_options.dart';
import 'package:christian_dating_app/interest_options.dart';
import 'package:christian_dating_app/profile_about_options.dart';
import 'package:christian_dating_app/relationship_intent.dart';
import 'package:christian_dating_app/geo_utils.dart';
import 'package:christian_dating_app/height_utils.dart';
import 'package:christian_dating_app/location_service.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_birthdate_screen.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_height_screen.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_option_picker_screen.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_text_field_screen.dart';
import 'package:christian_dating_app/widgets/profile_photo_placeholder.dart';
import 'package:christian_dating_app/widgets/use_current_location_row.dart';
import 'package:christian_dating_app/widgets/app_back_button.dart';
import 'package:christian_dating_app/widgets/app_icon.dart';
import 'package:christian_dating_app/widgets/user_profile_bottom_sheet.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_completion_indicator.dart';
import 'package:christian_dating_app/features/profile/presentation/widgets/profile_prompt_editor_section.dart';
import 'package:christian_dating_app/widgets/app_dialog.dart';

/// Profile photo slot: network URL, or local file (optionally uploading).
class _PhotoSlot {
  const _PhotoSlot.network(this.url, {this.thumbUrl})
      : file = null,
        uploadProgress = null,
        uploadError = false;

  const _PhotoSlot.local(
    this.file, {
    this.uploadProgress,
    this.uploadError = false,
  })  : url = null,
        thumbUrl = null;

  final String? url;
  final String? thumbUrl;
  final File? file;
  final double? uploadProgress;
  final bool uploadError;

  bool get isEmpty => url == null && file == null;
  bool get isNetwork => url != null;
  bool get isLocal => file != null && url == null;
  bool get isUploading =>
      isLocal &&
      !uploadError &&
      uploadProgress != null &&
      uploadProgress! < 1.0;

  bool get showsUploadOverlay =>
      isLocal && !uploadError && uploadProgress != null && uploadProgress! < 1.0;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  User? user;

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final cityController = TextEditingController();
  final aboutMeController = TextEditingController();
  final churchNameController = TextEditingController();
  String _birthdayDigits = '';
  final List<ProfilePromptSlot> _promptSlots = List.generate(
    ProfilePromptEditorSection.slotCount,
    (_) => ProfilePromptSlot(),
  );

  bool isLoading = true;
  bool isSaving = false;

  String? denomination;
  String? speaksInTongues;
  String? faithLevel;
  String? churchAttendance;
  String? exercise;
  String? lookingFor;
  String? alcohol;
  String? smoking;
  String? gender;
  String? kids;
  String? bodyType;
  String? personality;
  String? tattoos;
  int? _heightInches;

  final Set<String> _interests = {};

  /// Visible edit grid: 3 slots (more slots reserved for a future build).
  static const int _kMaxPhotos = 3;

  /// Fixed 3 slots; `null` = empty. Index 0 = main profile photo.
  final List<_PhotoSlot?> _photoSlots = List<_PhotoSlot?>.filled(_kMaxPhotos, null);

  /// URLs beyond the first 3 from Firestore; kept on save so nothing is dropped until a 6-slot UI exists.
  List<String> _overflowPhotoUrls = [];
  List<String> _overflowPhotoThumbs = [];

  final picker = ImagePicker();

  bool _locationLoading = false;
  UserLocationData? _pendingLocation;
  String? _locationHint;

  /// Last loaded Firestore doc; merged with in-form values for profile preview.
  Map<String, dynamic> _baseUserData = {};

  static const int _kMaxConcurrentUploads = 2;
  final List<int> _uploadQueue = [];
  final Set<int> _uploadsInFlight = {};
  final Map<int, int> _uploadGeneration = {};
  Timer? _photosPersistDebounce;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locationLoading = true;
      _locationHint = null;
    });
    try {
      final data = await LocationService.getCurrentUserLocation();
      if (!mounted) return;
      setState(() {
        _pendingLocation = data;
        if (data.city.isNotEmpty) {
          cityController.text = data.city;
        }
        _locationHint = 'Location will be saved when you go back.';
      });
    } on LocationServiceDisabled catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on LocationPermissionDenied catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!doc.exists) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
        'name': '',
        'age': 18,
        'city': '',
        'aboutMe': '',
        'interests': <String>[],
        'photos': [],
        'photoThumbs': [],
        'prompts': [
          {'question': '', 'answer': ''},
          {'question': '', 'answer': ''},
        ],
        'denomination': null,
        'speaksInTongues': null,
        'faithLevel': null,
        'churchAttendance': null,
        'churchName': '',
        'exercise': null,
        'lookingFor': kDefaultLookingFor,
        'alcohol': null,
        'smoking': null,
        'gender': null,
        'kids': null,
        'bodyType': null,
        'personality': null,
        'tattoos': null,
        'heightInches': null,
        'profileComplete': false,
        'maxDistanceKm': kDefaultMaxDistanceKm.round(),
      });
    }

    final newDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final data = newDoc.data();
    _baseUserData = Map<String, dynamic>.from(data ?? {});

    if (!mounted) return;

    loadProfilePromptSlots(
      _promptSlots,
      promptsRaw: data?['prompts'],
    );

    nameController.text = data?['name'] ?? '';
    ageController.text = data?['age']?.toString() ?? '';
    final digits = data?['birthdayDigits']?.toString() ?? '';
    final normalizedDigits = digits.replaceAll(RegExp(r'\D'), '');
    if (normalizedDigits.length == 8) {
      _birthdayDigits = normalizedDigits;
    }
    cityController.text = data?['city'] ?? '';
    if (parseUserGeoPoint(data?['location']) != null) {
      _locationHint = 'Location is saved on your profile. Tap below to refresh.';
    }
    aboutMeController.text = data?['aboutMe']?.toString() ?? '';
    churchNameController.text = data?['churchName']?.toString() ?? '';

    denomination = data?['denomination'];
    speaksInTongues = canonicalTongues(data?['speaksInTongues']?.toString());
    faithLevel = data?['faithLevel'];
    churchAttendance =
        canonicalChurchAttendance(data?['churchAttendance']?.toString());
    exercise = data?['exercise'];
    final rawLookingFor = data?['lookingFor']?.toString().trim() ?? '';
    lookingFor = rawLookingFor.isEmpty
        ? kDefaultLookingFor
        : displayLookingForLabel(rawLookingFor);
    alcohol = data?['alcohol'];
    smoking = data?['smoking'];
    gender = canonicalGender(data?['gender']?.toString());
    kids = canonicalKids(data?['kids']?.toString());
    bodyType = canonicalBodyType(data?['bodyType']?.toString());
    personality = canonicalPersonality(data?['personality']?.toString());
    tattoos = canonicalTattoos(data?['tattoos']?.toString());
    _heightInches = parseHeightInches(data?['heightInches']);

    _interests.clear();
    final interestRaw = data?['interests'];
    if (interestRaw is List) {
      for (final e in interestRaw) {
        final t = e?.toString().trim() ?? '';
        if (t.isEmpty) continue;
        final c = canonicalInterestLabel(t);
        if (kInterestOptions.contains(c)) {
          _interests.add(c);
        }
      }
    }

    final urls = List<String>.from(data?['photos'] ?? []);
    final thumbUrls = List<String>.from(data?['photoThumbs'] ?? []);
    final normalized = urls
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (var i = 0; i < _kMaxPhotos; i++) {
      if (i < normalized.length) {
        final thumb = i < thumbUrls.length
            ? thumbUrls[i].toString().trim()
            : '';
        _photoSlots[i] = _PhotoSlot.network(
          normalized[i],
          thumbUrl: thumb.isNotEmpty ? thumb : null,
        );
      } else {
        _photoSlots[i] = null;
      }
    }
    if (normalized.length > _kMaxPhotos) {
      _overflowPhotoUrls = normalized.sublist(_kMaxPhotos);
      _overflowPhotoThumbs = List.generate(_overflowPhotoUrls.length, (j) {
        final i = _kMaxPhotos + j;
        if (i < thumbUrls.length) {
          final t = thumbUrls[i].toString().trim();
          if (t.isNotEmpty) return t;
        }
        return _overflowPhotoUrls[j];
      });
    } else {
      _overflowPhotoUrls = [];
      _overflowPhotoThumbs = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  int _bumpUploadGeneration(int index) {
    final next = (_uploadGeneration[index] ?? 0) + 1;
    _uploadGeneration[index] = next;
    return next;
  }

  void _scheduleSlotUpload(int index) {
    if (_uploadQueue.contains(index)) return;
    _uploadQueue.add(index);
    _drainUploadQueue();
  }

  void _drainUploadQueue() {
    while (_uploadsInFlight.length < _kMaxConcurrentUploads &&
        _uploadQueue.isNotEmpty) {
      final index = _uploadQueue.removeAt(0);
      final slot = _photoSlots[index];
      if (slot == null || !slot.isLocal) continue;
      if (_uploadsInFlight.contains(index)) continue;

      _uploadsInFlight.add(index);
      _uploadSlot(index).whenComplete(() {
        _uploadsInFlight.remove(index);
        _drainUploadQueue();
      });
    }
  }

  Future<void> _uploadSlot(int index) async {
    final gen = _uploadGeneration[index] ?? 0;
    final slot = _photoSlots[index];
    if (slot == null || !slot.isLocal) return;
    final file = slot.file!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _photoSlots[index] = _PhotoSlot.local(file, uploadError: true);
      if (mounted) setState(() {});
      return;
    }

    try {
      final result = await ProfileImageService.uploadProfilePhoto(
        file,
        uid,
        onProgress: (progress) {
          if (!mounted || _uploadGeneration[index] != gen) return;
          final current = _photoSlots[index];
          if (current == null || current.file != file) return;
          setState(() {
            _photoSlots[index] = _PhotoSlot.local(
              file,
              uploadProgress: progress,
            );
          });
        },
      ).timeout(const Duration(seconds: 90));
      if (_uploadGeneration[index] != gen) return;
      if (_photoSlots[index]?.file != file) return;
      _photoSlots[index] = _PhotoSlot.network(
        result.photoUrl,
        thumbUrl: result.thumbUrl,
      );
      if (mounted) setState(() {});
      await _persistPhotosToFirestore();
    } catch (e) {
      if (_uploadGeneration[index] != gen) return;
      if (_photoSlots[index]?.file != file) return;
      _photoSlots[index] = _PhotoSlot.local(file, uploadError: true);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo upload failed. Tap the photo to retry.'),
          ),
        );
      }
    }
  }

  Future<void> _persistPhotosToFirestore() async {
    _photosPersistDebounce?.cancel();
    _photosPersistDebounce = Timer(const Duration(milliseconds: 600), () async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final photoResult = _collectPhotoListsFromSlots();
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photos': photoResult.photos,
          'photoThumbs': photoResult.thumbs,
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save photos: $e')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _photosPersistDebounce?.cancel();
    nameController.dispose();
    ageController.dispose();
    cityController.dispose();
    aboutMeController.dispose();
    churchNameController.dispose();
    super.dispose();
  }

  void _retrySlotUpload(int index) {
    final slot = _photoSlots[index];
    if (slot == null || !slot.isLocal || !slot.uploadError) return;
    setState(() {
      _photoSlots[index] = _PhotoSlot.local(
        slot.file!,
        uploadProgress: 0,
      );
    });
    _scheduleSlotUpload(index);
  }

  void _compactPhotos() {
    final filled = <_PhotoSlot>[];
    for (var i = 0; i < _kMaxPhotos; i++) {
      final s = _photoSlots[i];
      if (s != null && !s.isEmpty) filled.add(s);
    }
    for (var i = 0; i < _kMaxPhotos; i++) {
      _photoSlots[i] = i < filled.length ? filled[i] : null;
    }
  }

  List<int> get _emptyPhotoSlotIndices => ProfilePhotoPicker.emptySlotIndices(
        _kMaxPhotos,
        (i) {
          final s = _photoSlots[i];
          return s == null || s.isEmpty;
        },
      );

  void _assignFileToSlot(int index, File file) {
    setState(() {
      _bumpUploadGeneration(index);
      _photoSlots[index] = _PhotoSlot.local(file, uploadProgress: 0);
    });
    _scheduleSlotUpload(index);
  }

  Future<void> _pickAndCropIntoSlot(int index) async {
    final slot = _photoSlots[index];
    final replacing = slot != null && !slot.isEmpty;

    if (replacing) {
      final files = await ProfilePhotoPicker.pickAndCropFromGallery(
        context,
        picker,
        maxCount: 1,
        allowMultiple: false,
      );
      if (files.isEmpty || !mounted) return;
      _assignFileToSlot(index, files.first);
      return;
    }

    final emptySlots = _emptyPhotoSlotIndices;
    if (emptySlots.isEmpty) return;

    var nextEmptyIdx = 0;
    await ProfilePhotoPicker.pickAndCropFromGallery(
      context,
      picker,
      maxCount: emptySlots.length,
      allowMultiple: true,
      skipFaceDetection: emptySlots.length > 1,
      onEachCropped: (file) {
        if (!mounted || nextEmptyIdx >= emptySlots.length) return;
        _assignFileToSlot(emptySlots[nextEmptyIdx++], file);
      },
    );
  }

  void _swapSlots(int from, int to) {
    if (from == to) return;
    setState(() {
      final a = _photoSlots[from];
      _photoSlots[from] = _photoSlots[to];
      _photoSlots[to] = a;
    });
    _persistPhotosToFirestore();
  }

  void _showPhotoActionsModal(int index) {
    final slot = _photoSlots[index];
    if (slot == null || slot.isEmpty) return;

    showAppActionDialog(
      context,
      title: 'Replace or remove?',
      primaryLabel: 'Replace',
      onPrimary: () => _pickAndCropIntoSlot(index),
      secondaryLabel: 'Remove',
      onSecondary: () {
        setState(() {
          _bumpUploadGeneration(index);
          _photoSlots[index] = null;
          _compactPhotos();
        });
        _persistPhotosToFirestore();
      },
    );
  }

  Map<String, dynamic> _buildPreviewUserMap() {
    final photoLists = _collectPhotoListsFromSlots();
    final map = Map<String, dynamic>.from(_baseUserData);

    map['name'] = nameController.text.trim();
    map['age'] = int.tryParse(ageController.text.trim()) ??
        (map['age'] is int ? map['age'] as int : 0);
    map['city'] = cityController.text.trim();
    map['aboutMe'] = aboutMeController.text.trim();
    map['churchName'] = churchNameController.text.trim();
    map['interests'] = _interests.toList();
    map['denomination'] = denomination;
    map['speaksInTongues'] = tonguesForFirestore(denomination, speaksInTongues);
    map['faithLevel'] = faithLevel;
    map['churchAttendance'] = churchAttendance;
    map['exercise'] = exercise;
    map['lookingFor'] = resolvedLookingForForSave(lookingFor);
    map['alcohol'] = alcohol;
    map['smoking'] = smoking;
    map['gender'] = gender;
    map['kids'] = kids;
    map['bodyType'] = bodyType;
    map['personality'] = personality;
    map['tattoos'] = tattoos;
    map['heightInches'] = _heightInches;
    map['photos'] = photoLists.photos;
    map['photoThumbs'] = photoLists.thumbs;
    map['prompts'] = profilePromptsForFirestore(_promptSlots);

    if (_pendingLocation != null) {
      map['location'] = _pendingLocation!.geoPoint;
      final city = cityController.text.trim();
      map['city'] =
          city.isNotEmpty ? city : _pendingLocation!.city;
    }

    return map;
  }

  void _showProfilePreview() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showUserProfileBottomSheet(
      context,
      user: _buildPreviewUserMap(),
      profileUserId: uid,
      title: 'Preview',
      showBlockReportLinks: false,
      showHeroTopActions: false,
    );
  }

  ({List<String> photos, List<String> thumbs}) _collectPhotoListsFromSlots() {
    final photos = <String>[];
    final thumbs = <String>[];
    for (var i = 0; i < _kMaxPhotos; i++) {
      final s = _photoSlots[i];
      if (s == null || s.isEmpty) continue;
      if (s.isNetwork) {
        photos.add(s.url!);
        thumbs.add(s.thumbUrl ?? s.url!);
      }
    }
    photos.addAll(_overflowPhotoUrls);
    for (var i = 0; i < _overflowPhotoUrls.length; i++) {
      thumbs.add(
        i < _overflowPhotoThumbs.length
            ? _overflowPhotoThumbs[i]
            : _overflowPhotoUrls[i],
      );
    }
    return (photos: photos, thumbs: thumbs);
  }

  Future<bool> _saveTextFieldsOnly() async {
    if (isSaving) return false;

    if (!isValidLookingFor(lookingFor)) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select what you are looking for')),
      );
      return false;
    }

    setState(() => isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final updates = <String, dynamic>{
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text) ?? 0,
        if (_birthdayDigits.length == 8) 'birthdayDigits': _birthdayDigits,
        'city': cityController.text.trim(),
        'aboutMe': aboutMeController.text.trim(),
        'churchName': churchNameController.text.trim(),
        'interests': _interests.toList(),
        'denomination': denomination,
        'speaksInTongues': tonguesForFirestore(denomination, speaksInTongues),
        'faithLevel': faithLevel,
        'churchAttendance': churchAttendance,
        'exercise': exercise,
        'lookingFor': resolvedLookingForForSave(lookingFor),
        'alcohol': alcohol,
        'smoking': smoking,
        'gender': gender,
        'kids': kids,
        'bodyType': bodyType,
        'personality': personality,
        'tattoos': tattoos,
        'heightInches': _heightInches,
        'prompts': profilePromptsForFirestore(_promptSlots),
      };

      if (_pendingLocation != null) {
        updates.addAll(
          LocationService.firestoreFields(
            _pendingLocation!,
            cityOverride: cityController.text.trim(),
          ),
        );
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updates);

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e',
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _saveAndPop() async {
    if (!mounted) return;
    await _saveTextFieldsOnly();
    if (mounted) Navigator.pop(context);
  }

  String _slotBadgeLabel(int index) {
    final slot = _photoSlots[index];
    if (slot == null || slot.isEmpty) return '';
    var firstFilled = -1;
    for (var i = 0; i < _kMaxPhotos; i++) {
      final s = _photoSlots[i];
      if (s != null && !s.isEmpty) {
        firstFilled = i;
        break;
      }
    }
    if (index == firstFilled) return 'Main';
    var order = 0;
    for (var i = 0; i <= index; i++) {
      final s = _photoSlots[i];
      if (s != null && !s.isEmpty) order++;
    }
    return '$order';
  }

  static const Color _kPhotoPlaceholder = Color(0xFFF0F0F2);
  static const double _kPhotoCrossGap = 4;
  static const double _kPhotoMainGap = 4;
  static const double _kPhotoCornerRadius = 8;

  /// Large square main left + two smaller squares stacked right.
  Widget _buildPhotoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW = constraints.maxWidth;
        const crossGap = _kPhotoCrossGap;
        const mainGap = _kPhotoMainGap;
        final smallSide = (totalW - mainGap - crossGap) / 3;
        final mainSide = 2 * smallSide + mainGap;

        return SizedBox(
          height: mainSide,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoCell(
                0,
                width: mainSide,
                height: mainSide,
              ),
              const SizedBox(width: crossGap),
              SizedBox(
                width: smallSide,
                height: mainSide,
                child: Column(
                  children: [
                    _buildPhotoCell(
                      1,
                      width: smallSide,
                      height: smallSide,
                    ),
                    const SizedBox(height: mainGap),
                    _buildPhotoCell(
                      2,
                      width: smallSide,
                      height: smallSide,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoCell(
    int index, {
    required double width,
    required double height,
  }) {
    final slot = _photoSlots[index];
    final hasPhoto = slot != null && !slot.isEmpty;

    final addIconSize = height < 140 ? 28.0 : 36.0;

    Widget imageChild;
    if (!hasPhoto) {
      imageChild = Material(
        color: _kPhotoPlaceholder,
        child: InkWell(
          onTap: () => _pickAndCropIntoSlot(index),
          child: Center(
            child: Icon(
              Icons.add,
              size: addIconSize,
              color: const Color(0xFF8E8E93),
            ),
          ),
        ),
      );
    } else {
      final s = slot;
      if (s.isNetwork) {
        imageChild = NetworkProfileImage(
          url: s.url!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        imageChild = Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              s.file!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return const ColoredBox(color: _kPhotoPlaceholder);
              },
            ),
            if (s.showsUploadOverlay) ...[
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.48),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: s.uploadProgress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.35),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            if (s.uploadError)
              Positioned.fill(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: InkWell(
                    onTap: () => _retrySlotUpload(index),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tap to retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }
    }

    const kCloseHalfExtent = 8.0;

    final Widget cell;
    final radius = _kPhotoCornerRadius;

    if (!hasPhoto) {
      cell = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageChild,
      );
    } else {
      cell = Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: imageChild,
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: _slotBadgeLabel(index) == 'Main'
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Main',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _slotBadgeLabel(index),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: -kCloseHalfExtent,
            right: -kCloseHalfExtent,
            child: Material(
              color: Colors.black.withValues(alpha: 1),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _showPhotoActionsModal(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget dragDecorated(Widget child, List<Object?> candidateData) {
      final highlighted = candidateData.isNotEmpty;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: highlighted ? kBrandAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      );
    }

    final target = DragTarget<int>(
      onWillAcceptWithDetails: (details) =>
          details.data >= 0 && details.data != index,
      onAcceptWithDetails: (details) {
        if (details.data >= 0) _swapSlots(details.data, index);
      },
      builder: (context, candidateData, rejectedData) {
        return dragDecorated(cell, candidateData);
      },
    );

    if (!hasPhoto) {
      return SizedBox(
        width: width,
        height: height,
        child: target,
      );
    }

    final dragged = slot;
    return SizedBox(
      width: width,
      height: height,
      child: LongPressDraggable<int>(
        data: index,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width * 0.92,
            height: height * 0.92,
            child: dragged.isNetwork
                ? Image.network(dragged.url!, fit: BoxFit.cover)
                : Image.file(dragged.file!, fit: BoxFit.cover),
          ),
        ),
        childWhenDragging: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: target,
      ),
    );
  }

  Future<String?> _editText({
    required String title,
    required String current,
    String? hint,
    String? subtitle,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return ProfileTextFieldScreen.push(
      context,
      title: title,
      initial: current,
      hint: hint,
      subtitle: subtitle,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
    );
  }

  Future<String?> _pickFromOptions({
    required String title,
    required List<String> options,
    String? current,
  }) {
    return ProfileOptionPickerScreen.push(
      context,
      title: title,
      options: options,
      selected: current,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final previewUser = _buildPreviewUserMap();
    final completion = profileCompletionFraction(previewUser);
    final showCompletion = !isProfileFullyComplete(previewUser);

    return PopScope(
      canPop: !isSaving,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || isSaving) return;
        _saveAndPop();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Edit Profile'),
        leading: isSaving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : AppBackButton(onPressed: _saveAndPop),
        actions: [
          if (!isSaving)
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Preview profile',
              onPressed: _showProfilePreview,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (showCompletion) ...[
              ProfileStrengthSection(completion: completion),
              const SizedBox(height: 24),
            ],
            const Text(
              'Photos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pick some that show the true you.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            _buildPhotoGrid(),
            const SizedBox(height: 10),
            Text(
              'Hold and drag media to reorder',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            const _SectionTitle('Basic Info'),
            const SizedBox(height: 4),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Name',
              value: nameController.text,
              onTap: () async {
                final v = await _editText(
                  title: 'Name',
                  current: nameController.text,
                  hint: 'Your name',
                );
                if (v != null) setState(() => nameController.text = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: ageController.text,
              onTap: () async {
                final result = await ProfileBirthdateScreen.push(
                  context,
                  initialDigits: _birthdayDigits,
                );
                if (result != null) {
                  setState(() {
                    ageController.text = result.age.toString();
                    _birthdayDigits = result.birthdayDigits;
                  });
                }
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Gender',
              value: gender,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Gender',
                  options: kGenderOptions,
                  current: gender,
                );
                if (v != null) setState(() => gender = v);
              },
            ),
            const SizedBox(height: 28),
            const _SectionTitle('My location'),
            const SizedBox(height: 4),
            _InfoRow(
              leadingEmoji: '📍',
              label: 'City',
              value: cityController.text,
              onTap: () async {
                final v = await _editText(
                  title: 'City',
                  current: cityController.text,
                  hint: 'Your city',
                );
                if (v != null) setState(() => cityController.text = v);
              },
            ),
            const SizedBox(height: 8),
            UseCurrentLocationRow(
              loading: _locationLoading,
              onPressed: _useCurrentLocation,
              locationHint: _locationHint,
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Prompts'),
            const SizedBox(height: 12),
            ProfilePromptEditorSection(
              slots: _promptSlots,
              onChanged: () => setState(() {}),
            ),

            const SizedBox(height: 28),
            const _SectionTitle(
              'About me',
              subtitle: 'Write a fun and punchy intro.',
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E2E6)),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: aboutMeController,
                maxLength: 500,
                maxLines: 8,
                minLines: 3,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.multilineFieldInput(),
                decoration: const InputDecoration(
                  hintText: 'Share a little about yourself…',
                  border: InputBorder.none,
                  isCollapsed: true,
                  counterText: '',
                ),
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Church I Attend'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E2E6)),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: TextField(
                controller: churchNameController,
                maxLength: 120,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                style: AppTypography.multilineFieldInput(),
                decoration: const InputDecoration(
                  hintText: 'Name of your church (optional)',
                  border: InputBorder.none,
                  isCollapsed: true,
                  counterText: '',
                ),
              ),
            ),

            const SizedBox(height: 28),
            const _SectionTitle('Faith'),
            const SizedBox(height: 4),
            _InfoRow(
              leadingEmoji: '⛪',
              label: 'Denomination',
              value: denomination,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Denomination',
                  options: kDenominationOptions,
                  current: denomination,
                );
                if (v != null) {
                  setState(() {
                    denomination = v;
                    if (!isPentecostalDenomination(v)) {
                      speaksInTongues = null;
                    }
                  });
                }
              },
            ),
            if (isPentecostalDenomination(denomination)) ...[
              const _RowDivider(),
              _InfoRow(
                leadingEmoji: '🗣️',
                label: 'Tongues',
                value: speaksInTongues,
                onTap: () async {
                  final v = await _pickFromOptions(
                    title: 'Tongues',
                    options: kTonguesOptions,
                    current: speaksInTongues,
                  );
                  if (v != null) setState(() => speaksInTongues = v);
                },
              ),
            ],
            const _RowDivider(),
            _InfoRow(
              leadingEmoji: '🪑',
              label: 'Church attendance',
              value: churchAttendance,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Church attendance',
                  options: kChurchAttendanceOptions,
                  current: churchAttendance,
                );
                if (v != null) setState(() => churchAttendance = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              leadingEmoji: '✝️',
              label: 'Faith level',
              value: faithLevel,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Faith level',
                  options: kFaithLevelOptions,
                  current: faithLevel,
                );
                if (v != null) setState(() => faithLevel = v);
              },
            ),

            const SizedBox(height: 28),
            const _SectionTitle(
              'My Basics',
              subtitle: 'Cover the things most people are curious about.',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.search,
              label: 'Looking for',
              value: lookingFor,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Looking for',
                  options: kLookingForOptions,
                  current: lookingFor,
                );
                if (v != null) setState(() => lookingFor = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.child_care_outlined,
              label: 'Do you have kids?',
              value: kids,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Kids',
                  options: kKidsOptions,
                  current: kids,
                );
                if (v != null) setState(() => kids = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.accessibility_new_outlined,
              label: 'Body type',
              value: bodyType,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Body type',
                  options: kBodyTypeOptions,
                  current: bodyType,
                );
                if (v != null) setState(() => bodyType = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.straighten_outlined,
              label: 'Height',
              value: _heightInches == null
                  ? null
                  : formatHeightInches(_heightInches!),
              onTap: () async {
                final v = await ProfileHeightScreen.push(
                  context,
                  initialHeightInches: _heightInches,
                );
                if (v != null) setState(() => _heightInches = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.psychology_outlined,
              label: 'Personality',
              value: personality,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Personality',
                  options: kPersonalityOptions,
                  current: personality,
                );
                if (v != null) setState(() => personality = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.brush_outlined,
              label: 'Tattoos',
              value: tattoos,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Tattoos',
                  options: kTattoosOptions,
                  current: tattoos,
                );
                if (v != null) setState(() => tattoos = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.fitness_center_outlined,
              label: 'Exercise',
              value: exercise,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Exercise',
                  options: const ['Never', 'Sometimes', 'Often'],
                  current: exercise,
                );
                if (v != null) setState(() => exercise = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.local_bar_outlined,
              label: 'Drinking',
              value: alcohol,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Drinking',
                  options: const ['No', 'Occasionally', 'Yes'],
                  current: alcohol,
                );
                if (v != null) setState(() => alcohol = v);
              },
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.smoke_free_outlined,
              label: 'Smoking',
              value: smoking,
              onTap: () async {
                final v = await _pickFromOptions(
                  title: 'Smoking',
                  options: const ['No', 'Yes'],
                  current: smoking,
                );
                if (v != null) setState(() => smoking = v);
              },
            ),

            const SizedBox(height: 28),
            const Text(
              'Interests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick all that apply',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kInterestOptions.map((label) {
                final selected = _interests.contains(label);
                return FilterChip(
                  label: Text('${emojiForInterestLabel(label)} $label'),
                  selected: selected,
                  showCheckmark: false,
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: selected ? Colors.black87 : const Color(0xFFE0E0E4),
                  ),
                  onSelected: (on) {
                    setState(() {
                      if (on) {
                        _interests.add(label);
                      } else {
                        _interests.remove(label);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    this.icon,
    this.leadingEmoji,
    required this.label,
    required this.onTap,
    this.value,
  }) : assert(icon != null || leadingEmoji != null);

  final IconData? icon;
  final String? leadingEmoji;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.trim().isNotEmpty;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            if (leadingEmoji != null)
              Text(
                leadingEmoji!,
                style: const TextStyle(fontSize: 22, height: 1.1),
              )
            else
              Icon(icon!, size: 22, color: Colors.black87),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hasValue ? value! : 'Add',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: hasValue ? Colors.black87 : Colors.grey.shade500,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F2),
      indent: 36,
    );
  }
}

