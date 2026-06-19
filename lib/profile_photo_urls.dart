/// Resolves display vs avatar URLs from Firestore user maps.
class ProfilePhotoUrls {
  ProfilePhotoUrls._();

  /// Full-size photo for discovery hero and large previews.
  static String? photoAt(Map<String, dynamic> user, {int index = 0}) {
    final photos = user['photos'];
    if (photos is! List || index >= photos.length) return null;
    final url = photos[index]?.toString().trim() ?? '';
    return url.isEmpty ? null : url;
  }

  /// Small thumb for list avatars (~72px); falls back to [photoAt].
  static String? thumbAt(Map<String, dynamic> user, {int index = 0}) {
    final thumbs = user['photoThumbs'];
    if (thumbs is List && index < thumbs.length) {
      final thumb = thumbs[index]?.toString().trim() ?? '';
      if (thumb.isNotEmpty) return thumb;
    }
    return photoAt(user, index: index);
  }
}
