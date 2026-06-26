import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shared shimmer wrapper for skeleton placeholders.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.child});

  final Widget child;

  static const Color blockColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppSkeleton.blockColor,
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Matches [LikedYouScreen] grid card layout.
class LikedYouCardSkeleton extends StatelessWidget {
  const LikedYouCardSkeleton({super.key});

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppSkeleton.blockColor,
          borderRadius: _radius,
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppSkeleton.blockColor),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SkeletonBox(
                      width: 88,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    SizedBox(height: 8),
                    SkeletonBox(
                      width: 64,
                      height: 12,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LikedYouGridSkeleton extends StatelessWidget {
  const LikedYouGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.72,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
  });

  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets padding;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const LikedYouCardSkeleton(),
    );
  }
}

class LikedYouScreenSkeleton extends StatelessWidget {
  const LikedYouScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: AppSkeleton(
            child: Row(
              children: const [
                SkeletonBox(
                  width: 72,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                SizedBox(width: 8),
                SkeletonBox(
                  width: 72,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                SizedBox(width: 8),
                SkeletonBox(
                  width: 64,
                  height: 34,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
            ),
          ),
        ),
        const Expanded(
          child: LikedYouGridSkeleton(),
        ),
      ],
    );
  }
}

/// Matches [_ChatListTile] row layout.
class ChatListTileSkeleton extends StatelessWidget {
  const ChatListTileSkeleton({super.key});

  static const double _avatarRadius = 31;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            SkeletonBox(
              width: _avatarRadius * 2,
              height: _avatarRadius * 2,
              borderRadius: BorderRadius.all(Radius.circular(_avatarRadius)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(
                    width: 140,
                    height: 16,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  SizedBox(height: 8),
                  SkeletonBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) => const ChatListTileSkeleton(),
    );
  }
}
