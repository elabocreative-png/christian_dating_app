import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/features/profile/domain/profile_image_upload_progress.dart';

void main() {
  group('profileUploadByteProgress', () {
    test('returns 0 when total size is 0', () {
      expect(
        profileUploadByteProgress(
          fullBytesTransferred: 10,
          thumbBytesTransferred: 5,
          fullSize: 0,
          thumbSize: 0,
        ),
        0,
      );
    });

    test('combines full and thumb byte counts', () {
      expect(
        profileUploadByteProgress(
          fullBytesTransferred: 50,
          thumbBytesTransferred: 50,
          fullSize: 100,
          thumbSize: 100,
        ),
        0.5,
      );
    });

    test('clamps to 1.0 when transfers exceed total', () {
      expect(
        profileUploadByteProgress(
          fullBytesTransferred: 120,
          thumbBytesTransferred: 100,
          fullSize: 100,
          thumbSize: 100,
        ),
        1.0,
      );
    });
  });

  group('blendProfileUploadProgress', () {
    test('maps upload fraction into compress-to-upload range', () {
      expect(
        blendProfileUploadProgress(
          0.5,
          compressEnd: 0.40,
          uploadEnd: 0.95,
        ),
        closeTo(0.675, 0.001),
      );
    });

    test('returns compressEnd when upload has not started', () {
      expect(
        blendProfileUploadProgress(
          0,
          compressEnd: 0.40,
          uploadEnd: 0.95,
        ),
        0.40,
      );
    });

    test('returns uploadEnd when upload is complete', () {
      expect(
        blendProfileUploadProgress(
          1,
          compressEnd: 0.40,
          uploadEnd: 0.95,
        ),
        0.95,
      );
    });
  });
}
