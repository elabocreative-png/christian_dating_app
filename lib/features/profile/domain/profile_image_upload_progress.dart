/// Combined upload byte progress for parallel full + thumb uploads.
double profileUploadByteProgress({
  required int fullBytesTransferred,
  required int thumbBytesTransferred,
  required int fullSize,
  required int thumbSize,
}) {
  final total = fullSize + thumbSize;
  if (total <= 0) return 0;
  return ((fullBytesTransferred + thumbBytesTransferred) / total)
      .clamp(0.0, 1.0);
}

/// Maps raw upload fraction into the post-compress progress range.
double blendProfileUploadProgress(
  double uploadFraction, {
  required double compressEnd,
  required double uploadEnd,
}) {
  return compressEnd + uploadFraction * (uploadEnd - compressEnd);
}
