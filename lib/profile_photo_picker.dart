import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'widgets/ios_style_image_crop_screen.dart';

/// Gallery multi-pick + sequential crop for profile photo slots.
class ProfilePhotoPicker {
  ProfilePhotoPicker._();

  static Future<List<File>> pickAndCropFromGallery(
    BuildContext context,
    ImagePicker picker, {
    required int maxCount,
    bool allowMultiple = true,
    bool skipFaceDetection = false,
    void Function(File file)? onEachCropped,
  }) async {
    if (maxCount <= 0) return [];

    try {
      final List<XFile> picked;
      if (allowMultiple && maxCount > 1) {
        picked = await picker.pickMultiImage(
          limit: maxCount,
          imageQuality: 85,
          maxWidth: 1080,
          maxHeight: 1080,
        );
      } else {
        final one = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1080,
          maxHeight: 1080,
        );
        picked = one == null ? [] : [one];
      }

      if (picked.isEmpty) return [];

      final toProcess = picked.take(maxCount).toList();
      final skipFace = skipFaceDetection && toProcess.length > 1;
      final files = <File>[];

      if (!context.mounted) return files;

      await pushIosStyleImageCropBatch(
        context,
        toProcess.map((x) => x.path).toList(),
        skipFaceDetection: skipFace,
        onEachCropped: (path, index) {
          final file = File(path);
          files.add(file);
          onEachCropped?.call(file);
        },
      );
      return files;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
      return [];
    }
  }

  /// Indices of empty slots in order (0..maxPhotos-1).
  static List<int> emptySlotIndices(
    int maxPhotos,
    bool Function(int index) isEmpty,
  ) {
    return [
      for (var i = 0; i < maxPhotos; i++)
        if (isEmpty(i)) i,
    ];
  }
}
