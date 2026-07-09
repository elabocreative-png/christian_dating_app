import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';

import 'package:christian_dating_app/core/photo/face_crop_helper.dart';
import 'package:christian_dating_app/core/photo/static_square_crop_editor.dart';

class CropImageSource {
  const CropImageSource({
    required this.imageBytes,
    this.initialFocusFraction,
  });

  final Uint8List imageBytes;
  final Offset? initialFocusFraction;
}

/// Route arguments for [IosStyleImageCropFlowScreen] via GoRouter `extra`.
final class ImageCropRouteArgs {
  const ImageCropRouteArgs({
    required this.sources,
    this.onEachCropped,
  });

  final List<CropImageSource> sources;
  final void Function(String path, int index)? onEachCropped;
}

Future<List<CropImageSource>> loadCropImageSources(
  List<String> sourcePaths, {
  bool skipFaceDetection = false,
}) async {
  final sources = <CropImageSource>[];
  for (final path in sourcePaths) {
    final bytes = await File(path).readAsBytes();
    Offset? focusFraction;
    if (!skipFaceDetection) {
      final faceHint = await FaceCropHelper.analyzeBytes(bytes);
      if (faceHint != null) {
        final area = faceHint.cropArea;
        focusFraction = Offset(
          (area.left + area.width / 2) / faceHint.imageWidth,
          (area.top + area.height / 2) / faceHint.imageHeight,
        );
      }
    }
    sources.add(
      CropImageSource(
        imageBytes: bytes,
        initialFocusFraction: focusFraction,
      ),
    );
  }
  return sources;
}

/// Sequential crop for one or more gallery picks. Returns cropped temp paths.
Future<List<String>> pushIosStyleImageCropBatch(
  BuildContext context,
  List<String> sourcePaths, {
  bool skipFaceDetection = false,
  void Function(String path, int index)? onEachCropped,
}) async {
  if (sourcePaths.isEmpty) return [];

  final sources = await loadCropImageSources(
    sourcePaths,
    skipFaceDetection: skipFaceDetection,
  );
  if (!context.mounted) return [];

  final result = await context.push<List<String>>(
    AppRoutes.imageCrop,
    extra: ImageCropRouteArgs(
      sources: sources,
      onEachCropped: onEachCropped,
    ),
  );
  return result ?? [];
}

/// Portrait 2:3 crop UI with fixed crop window and movable image.
/// Returns a temp file path on success, or `null` if cancelled.
Future<String?> pushIosStyleImageCrop(
  BuildContext context,
  String sourcePath, {
  int selectionIndex = 0,
  int selectionCount = 1,
  bool skipFaceDetection = false,
}) async {
  final paths = await pushIosStyleImageCropBatch(
    context,
    [sourcePath],
    skipFaceDetection: skipFaceDetection,
  );
  return paths.isEmpty ? null : paths.first;
}

class IosStyleImageCropFlowScreen extends StatefulWidget {
  const IosStyleImageCropFlowScreen({
    super.key,
    required this.sources,
    this.onEachCropped,
  });

  static const double cropAspectRatio = 2 / 3;

  final List<CropImageSource> sources;
  final void Function(String path, int index)? onEachCropped;

  @override
  State<IosStyleImageCropFlowScreen> createState() =>
      _IosStyleImageCropFlowScreenState();
}

class _IosStyleImageCropFlowScreenState extends State<IosStyleImageCropFlowScreen> {
  late final PageController _pageController;
  late final List<GlobalKey<StaticSquareCropEditorState>> _editorKeys;
  final List<String> _completedPaths = [];

  var _currentIndex = 0;
  var _exporting = false;

  int get _total => widget.sources.length;
  bool get _isMulti => _total > 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _editorKeys = List.generate(
      _total,
      (_) => GlobalKey<StaticSquareCropEditorState>(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _uploadLabel {
    if (_isMulti) {
      return '${_currentIndex + 1}/$_total';
    }
    return 'Upload';
  }

  void _close() {
    context.pop(_completedPaths);
  }

  Future<void> _onUpload() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      final cropped =
          await _editorKeys[_currentIndex].currentState?.exportJpeg();
      if (cropped == null) {
        if (mounted) {
          setState(() => _exporting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not crop image')),
          );
        }
        return;
      }

      final path =
          '${Directory.systemTemp.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(cropped, flush: true);
      if (!mounted) return;

      _completedPaths.add(path);
      widget.onEachCropped?.call(path, _currentIndex);

      final isLast = _currentIndex >= _total - 1;
      if (isLast) {
        context.pop(_completedPaths);
        return;
      }

      final nextIndex = _currentIndex + 1;
      setState(() {
        _currentIndex = nextIndex;
        _exporting = false;
      });
      await _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not crop: $e')),
      );
    }
  }

  ({double width, double height}) _cropDimensions(
    BoxConstraints constraints,
  ) {
    const aspect = IosStyleImageCropFlowScreen.cropAspectRatio;
    final maxW = constraints.maxWidth * 0.88;
    final maxH = constraints.maxHeight * 0.92;

    var cropW = maxW;
    var cropH = cropW / aspect;
    if (cropH > maxH) {
      cropH = maxH;
      cropW = cropH * aspect;
    }
    return (width: cropW, height: cropH);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _exporting ? null : _close,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const Text(
                      'Crop photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crop = _cropDimensions(constraints);

                    return PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _total,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final source = widget.sources[index];
                        return Center(
                          child: StaticSquareCropEditor(
                            key: _editorKeys[index],
                            imageBytes: source.imageBytes,
                            cropWidth: crop.width,
                            cropHeight: crop.height,
                            initialFocusFraction: source.initialFocusFraction,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _exporting ? null : _onUpload,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white54,
                      disabledForegroundColor: Colors.black54,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: _exporting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        : Text(
                            _uploadLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kept for references to [cropAspectRatio] in other widgets.
typedef IosStyleImageCropScreen = IosStyleImageCropFlowScreen;
