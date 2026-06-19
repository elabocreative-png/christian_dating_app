import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Face-centered crop hints for [IosStyleImageCropScreen].
class FaceCropSuggestion {
  const FaceCropSuggestion({
    required this.cropArea,
    required this.squareCropArea,
    required this.squarePreviewBytes,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// 2:3 crop rectangle in image pixel coordinates.
  final Rect cropArea;

  /// Square crop rectangle in image pixel coordinates (face-centered).
  final Rect squareCropArea;
  final Uint8List squarePreviewBytes;
  final int imageWidth;
  final int imageHeight;
}

/// Detects a face and suggests an initial 2:3 crop plus square preview bytes.
class FaceCropHelper {
  FaceCropHelper._();

  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.12,
    ),
  );

  /// Analyzes [imageBytes] (JPEG/PNG). Returns `null` if no face or on failure.
  static Future<FaceCropSuggestion?> analyzeBytes(Uint8List imageBytes) async {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      final w = decoded.width;
      final h = decoded.height;

      final tempPath =
          '${Directory.systemTemp.path}/face_scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final encoded = img.encodeJpg(decoded, quality: 92);
      await File(tempPath).writeAsBytes(encoded, flush: true);

      final faces = await _detector.processImage(
        InputImage.fromFilePath(tempPath),
      );

      try {
        await File(tempPath).delete();
      } catch (_) {}

      if (faces.isEmpty) return null;

      final face = _largestFace(faces);
      final box = face.boundingBox;

      final cropArea = _portraitCropFromFace(
        imageWidth: w,
        imageHeight: h,
        faceLeft: box.left,
        faceTop: box.top,
        faceWidth: box.width,
        faceHeight: box.height,
      );

      final squareArea = _squareCropFromFace(
        imageWidth: w,
        imageHeight: h,
        faceLeft: box.left,
        faceTop: box.top,
        faceWidth: box.width,
        faceHeight: box.height,
      );

      final squarePreview = img.copyCrop(
        decoded,
        x: squareArea.left.round().clamp(0, w - 1),
        y: squareArea.top.round().clamp(0, h - 1),
        width: squareArea.width.round().clamp(1, w),
        height: squareArea.height.round().clamp(1, h),
      );

      return FaceCropSuggestion(
        cropArea: cropArea,
        squareCropArea: squareArea,
        squarePreviewBytes: Uint8List.fromList(img.encodeJpg(squarePreview, quality: 88)),
        imageWidth: w,
        imageHeight: h,
      );
    } catch (_) {
      return null;
    }
  }

  static Face _largestFace(List<Face> faces) {
    Face best = faces.first;
    var bestArea = 0.0;
    for (final f in faces) {
      final b = f.boundingBox;
      final area = b.width * b.height;
      if (area > bestArea) {
        bestArea = area;
        best = f;
      }
    }
    return best;
  }

  static Rect _portraitCropFromFace({
    required int imageWidth,
    required int imageHeight,
    required double faceLeft,
    required double faceTop,
    required double faceWidth,
    required double faceHeight,
  }) {
    const aspect = 2 / 3; // width / height

    var cropH = math.max(faceHeight * 2.8, imageHeight * 0.52);
    cropH = cropH.clamp(imageHeight * 0.35, imageHeight.toDouble());
    var cropW = cropH * aspect;

    if (cropW > imageWidth) {
      cropW = imageWidth.toDouble();
      cropH = cropW / aspect;
    }

    final centerX = faceLeft + faceWidth / 2;
    final centerY = faceTop + faceHeight / 2 - faceHeight * 0.12;

    var left = centerX - cropW / 2;
    var top = centerY - cropH / 2;

    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + cropW > imageWidth) left = imageWidth - cropW;
    if (top + cropH > imageHeight) top = imageHeight - cropH;

    return Rect.fromLTWH(left, top, cropW, cropH);
  }

  static Rect _squareCropFromFace({
    required int imageWidth,
    required int imageHeight,
    required double faceLeft,
    required double faceTop,
    required double faceWidth,
    required double faceHeight,
  }) {
    var side = math.max(faceWidth, faceHeight) * 1.65;
    side = side.clamp(
      math.min(imageWidth, imageHeight) * 0.25,
      math.min(imageWidth, imageHeight).toDouble(),
    );

    final centerX = faceLeft + faceWidth / 2;
    final centerY = faceTop + faceHeight / 2 - faceHeight * 0.08;

    var left = centerX - side / 2;
    var top = centerY - side / 2;

    if (left < 0) left = 0;
    if (top < 0) top = 0;
    if (left + side > imageWidth) left = imageWidth - side;
    if (top + side > imageHeight) top = imageHeight - side;

    return Rect.fromLTWH(left, top, side, side);
  }
}
