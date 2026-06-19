import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Persists in-app issue reports from Settings → Report an Issue.
abstract final class IssueReportService {
  static Future<bool> submit({
    required String description,
    File? image,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final trimmed = description.trim();
    if (trimmed.isEmpty) return false;

    try {
      final docRef =
          FirebaseFirestore.instance.collection('issue_reports').doc();
      String? imageUrl;

      if (image != null) {
        imageUrl = await _uploadImage(uid: uid, reportId: docRef.id, file: image);
      }

      await docRef.set({
        'userId': uid,
        'description': trimmed,
        'imageUrl': ?imageUrl,
        'source': 'settings',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } on FirebaseException {
      return false;
    }
  }

  static Future<String?> _uploadImage({
    required String uid,
    required String reportId,
    required File file,
  }) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1080,
      minHeight: 1080,
      quality: 85,
    );
    if (compressed == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('issue_reports')
        .child(uid)
        .child('$reportId.jpg');

    await ref.putData(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
