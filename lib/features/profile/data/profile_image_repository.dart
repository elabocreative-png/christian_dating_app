import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uploaded profile photo URLs (full + avatar-sized thumb).
class UploadedProfilePhoto {
  const UploadedProfilePhoto({
    required this.photoUrl,
    required this.thumbUrl,
  });

  final String photoUrl;
  final String thumbUrl;
}

/// Compresses and uploads profile images to Firebase Storage.
class ProfileImageRepository {
  ProfileImageRepository({FirebaseStorage? storage}) : _storage = storage;

  final FirebaseStorage? _storage;

  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  static const int profileMaxSide = 1080;
  static const int thumbMaxSide = 144; // ~72dp @2x
  static const int profileJpegQuality = 85;
  static const int thumbJpegQuality = 82;
  static const int defaultMaxConcurrentUploads = 2;

  static const double _progressCompressStart = 0.05;
  static const double _progressCompressMid = 0.22;
  static const double _progressCompressEnd = 0.40;
  static const double _progressUploadEnd = 0.95;

  /// Compresses both sizes, uploads full + thumb in parallel, returns download URLs.
  Future<UploadedProfilePhoto> uploadProfilePhoto(
    File source,
    String uid, {
    void Function(double progress)? onProgress,
  }) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final storage = _bucket.ref().child('user_images');

    onProgress?.call(_progressCompressStart);

    File? fullTemp;
    try {
      fullTemp = await _compressToTempFile(
        source,
        maxSide: profileMaxSide,
        quality: profileJpegQuality,
        suffix: '$stamp-full',
      );
      onProgress?.call(_progressCompressMid);

      final thumbBytes = await _compress(
        source,
        maxSide: thumbMaxSide,
        quality: thumbJpegQuality,
      );
      onProgress?.call(_progressCompressEnd);

      final fullRef = storage.child('$uid-$stamp-full.jpg');
      final thumbRef = storage.child('$uid-$stamp-thumb.jpg');

      final fullTask = fullRef.putFile(
        fullTemp,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final thumbTask = thumbRef.putData(
        thumbBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final fullSize = await fullTemp.length();
      final thumbSize = thumbBytes.length;

      StreamSubscription<TaskSnapshot>? fullSub;
      StreamSubscription<TaskSnapshot>? thumbSub;
      if (onProgress != null) {
        void emit() {
          final uploadFraction = _uploadByteProgress(
            fullTask.snapshot,
            thumbTask.snapshot,
            fullSize,
            thumbSize,
          );
          onProgress(_blendUploadProgress(uploadFraction));
        }

        emit();
        fullSub = fullTask.snapshotEvents.listen((_) => emit());
        thumbSub = thumbTask.snapshotEvents.listen((_) => emit());
      }

      try {
        await Future.wait([fullTask, thumbTask]);
        onProgress?.call(_progressUploadEnd);

        final urls = await Future.wait([
          fullRef.getDownloadURL(),
          thumbRef.getDownloadURL(),
        ]);

        onProgress?.call(1.0);

        return UploadedProfilePhoto(
          photoUrl: urls[0],
          thumbUrl: urls[1],
        );
      } finally {
        await fullSub?.cancel();
        await thumbSub?.cancel();
      }
    } finally {
      if (fullTemp != null) {
        try {
          if (await fullTemp.exists()) await fullTemp.delete();
        } catch (_) {}
      }
    }
  }

  /// Uploads [files] with at most [maxConcurrent] uploads running at once.
  Future<List<UploadedProfilePhoto>> uploadProfilePhotosParallel(
    List<File> files,
    String uid, {
    int maxConcurrent = defaultMaxConcurrentUploads,
    void Function(int fileIndex, double progress)? onProgress,
  }) async {
    if (files.isEmpty) return [];

    final results = List<UploadedProfilePhoto?>.filled(files.length, null);
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final i = nextIndex++;
        if (i >= files.length) return;
        results[i] = await uploadProfilePhoto(
          files[i],
          uid,
          onProgress:
              onProgress == null ? null : (p) => onProgress(i, p),
        );
      }
    }

    final workers = maxConcurrent < files.length
        ? maxConcurrent
        : files.length;
    await Future.wait(List.generate(workers, (_) => worker()));

    return results.cast<UploadedProfilePhoto>();
  }

  double _uploadByteProgress(
    TaskSnapshot a,
    TaskSnapshot b,
    int fullSize,
    int thumbSize,
  ) {
    final total = fullSize + thumbSize;
    if (total <= 0) return 0;
    return ((a.bytesTransferred + b.bytesTransferred) / total)
        .clamp(0.0, 1.0);
  }

  double _blendUploadProgress(double uploadFraction) {
    return _progressCompressEnd +
        uploadFraction * (_progressUploadEnd - _progressCompressEnd);
  }

  Future<File> _compressToTempFile(
    File file, {
    required int maxSide,
    required int quality,
    required String suffix,
  }) async {
    final target = File(
      '${Directory.systemTemp.path}/profile_upload_$suffix.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target.absolute.path,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (result == null) {
      throw Exception('Could not compress image');
    }
    return File(result.path);
  }

  Future<Uint8List> _compress(
    File file, {
    required int maxSide,
    required int quality,
  }) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: maxSide,
      minHeight: maxSide,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (result == null || result.isEmpty) {
      throw Exception('Could not compress image');
    }
    return Uint8List.fromList(result);
  }
}

final profileImageRepositoryProvider = Provider<ProfileImageRepository>((ref) {
  return ProfileImageRepository();
});
