import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Persists picked/cropped profile photos outside [Directory.systemTemp].
///
/// Android may clear cache/temp while uploads are still queued; documents
/// storage survives until upload completes or the user removes the photo.
class ProfilePhotoFileCache {
  ProfilePhotoFileCache._();

  static const String _subdir = 'profile_photos_pending';

  static Directory? _dir;

  static Future<Directory> directory() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/$_subdir');
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
    return _dir!;
  }

  static Future<File> persistFile(File source) async {
    Uint8List bytes;
    try {
      bytes = await source.readAsBytes();
    } catch (_) {
      throw StateError(
        'Photo file is missing. Please choose the photo again.',
      );
    }
    if (bytes.isEmpty) {
      throw StateError('Photo file is empty. Please choose the photo again.');
    }
    return persistBytes(bytes);
  }

  static Future<File> persistBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw StateError('Photo file is empty. Please choose the photo again.');
    }
    final dir = await directory();
    final dest = File(
      '${dir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await dest.writeAsBytes(bytes, flush: true);
    if (!await dest.exists() || await dest.length() == 0) {
      throw StateError('Could not save photo on this device.');
    }
    return dest;
  }
}
