import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:christian_dating_app/core/navigation/app_routes.dart';
import 'package:christian_dating_app/core/photo/ios_style_image_crop_screen.dart';

/// Opens a fullscreen viewer for a single uploaded profile photo (2:3 crop).
Future<void> showProfilePhotoViewer(
  BuildContext context, {
  required String url,
}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return Future.value();
  return context.push<void>(AppRoutes.profilePhotoViewerWith(url: trimmed));
}

class ProfilePhotoViewerScreen extends StatelessWidget {
  const ProfilePhotoViewerScreen({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _ProfilePhotoViewerPage(url: url),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoViewerPage extends StatelessWidget {
  const _ProfilePhotoViewerPage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const aspect = IosStyleImageCropScreen.cropAspectRatio;
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        var width = maxW;
        var height = width / aspect;
        if (height > maxH) {
          height = maxH;
          width = height * aspect;
        }

        return Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 3,
            child: SizedBox(
              width: width,
              height: height,
              child: Image.network(
                url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  );
                },
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
