import 'dart:io';
import 'dart:typed_data';

/// Cropped profile image kept in memory and on disk for preview/upload.
class CroppedProfilePhoto {
  const CroppedProfilePhoto({
    required this.file,
    required this.bytes,
  });

  final File file;
  final Uint8List bytes;
}
