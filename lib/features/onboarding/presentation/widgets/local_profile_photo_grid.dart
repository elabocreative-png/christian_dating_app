import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:christian_dating_app/profile_photo_picker.dart';
import 'package:christian_dating_app/core/widgets/app_dialog.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';

/// Three-slot local photo grid (same look as Edit Profile / settings flow).
class LocalProfilePhotoGrid extends StatefulWidget {
  const LocalProfilePhotoGrid({
    super.key,
    required this.slots,
    required this.onSlotsChanged,
    this.maxPhotos = 3,
  });

  final List<File?> slots;
  final ValueChanged<List<File?>> onSlotsChanged;
  final int maxPhotos;

  @override
  State<LocalProfilePhotoGrid> createState() => _LocalProfilePhotoGridState();
}

class _LocalProfilePhotoGridState extends State<LocalProfilePhotoGrid> {
  final ImagePicker _picker = ImagePicker();

  void _updateSlots(List<File?> next) {
    widget.onSlotsChanged(List<File?>.from(next));
  }

  String _slotBadgeLabel(int index, List<File?> slots) {
    var firstFilled = -1;
    for (var i = 0; i < slots.length; i++) {
      if (slots[i] != null) {
        firstFilled = i;
        break;
      }
    }
    if (index == firstFilled) return 'Main';
    return '${index + 1}';
  }

  Future<void> _pickAndCropIntoSlot(int index) async {
    final replacing = index < widget.slots.length && widget.slots[index] != null;

    if (replacing) {
      final files = await ProfilePhotoPicker.pickAndCropFromGallery(
        context,
        _picker,
        maxCount: 1,
        allowMultiple: false,
      );
      if (files.isEmpty || !mounted) return;
      final next = List<File?>.from(widget.slots);
      next[index] = files.first;
      _updateSlots(next);
      return;
    }

    final emptySlots = ProfilePhotoPicker.emptySlotIndices(
      widget.maxPhotos,
      (i) => i >= widget.slots.length || widget.slots[i] == null,
    );
    if (emptySlots.isEmpty) return;

    var nextEmptyIdx = 0;
    await ProfilePhotoPicker.pickAndCropFromGallery(
      context,
      _picker,
      maxCount: emptySlots.length,
      allowMultiple: true,
      skipFaceDetection: emptySlots.length > 1,
      onEachCropped: (file) {
        if (!mounted || nextEmptyIdx >= emptySlots.length) return;
        final next = List<File?>.from(widget.slots);
        while (next.length < widget.maxPhotos) {
          next.add(null);
        }
        next[emptySlots[nextEmptyIdx++]] = file;
        _updateSlots(next);
      },
    );
  }

  void _swapSlots(int from, int to) {
    if (from == to) return;
    final next = List<File?>.from(widget.slots);
    final a = next[from];
    next[from] = next[to];
    next[to] = a;
    _updateSlots(next);
  }

  void _removeSlot(int index) {
    final next = List<File?>.from(widget.slots);
    next[index] = null;
    final filled = <File>[];
    for (final f in next) {
      if (f != null) filled.add(f);
    }
    for (var i = 0; i < next.length; i++) {
      next[i] = i < filled.length ? filled[i] : null;
    }
    _updateSlots(next);
  }

  void _showPhotoActionsModal(int index) {
    showAppActionDialog(
      context,
      title: 'Replace or remove?',
      primaryLabel: 'Replace',
      onPrimary: () => _pickAndCropIntoSlot(index),
      secondaryLabel: 'Remove',
      onSecondary: () => _removeSlot(index),
    );
  }

  Widget _buildPhotoCell(int index) {
    final slots = widget.slots;
    final file = index < slots.length ? slots[index] : null;
    final hasPhoto = file != null;

    Widget imageChild;
    if (!hasPhoto) {
      imageChild = Material(
        color: const Color(0xFFF0F0F2),
        child: InkWell(
          onTap: () => _pickAndCropIntoSlot(index),
          child: const Center(
            child: Icon(Icons.add, size: 36, color: Color(0xFF8E8E93)),
          ),
        ),
      );
    } else {
      imageChild = Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final badge = _slotBadgeLabel(index, slots);

    final cell = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageChild,
          if (hasPhoto) ...[
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.75),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showPhotoActionsModal(index),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              child: badge == 'Main'
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Main',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;

        Widget dragDecorated(Widget child, List<Object?> candidateData) {
          final highlighted = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: highlighted ? kBrandAccent : Colors.transparent,
                width: 2,
              ),
            ),
            child: child,
          );
        }

        final target = DragTarget<int>(
          onWillAcceptWithDetails: (details) =>
              details.data >= 0 && details.data != index,
          onAcceptWithDetails: (details) {
            if (details.data >= 0) _swapSlots(details.data, index);
          },
          builder: (context, candidateData, rejectedData) {
            return dragDecorated(cell, candidateData);
          },
        );

        if (!hasPhoto) {
          return SizedBox(width: side, height: side, child: target);
        }

        return SizedBox(
          width: side,
          height: side,
          child: LongPressDraggable<int>(
            data: index,
            feedback: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: side * 0.92,
                height: side * 0.92,
                child: Image.file(file, fit: BoxFit.cover),
              ),
            ),
            childWhenDragging: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: target,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.maxPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 10,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
          children: List.generate(count, _buildPhotoCell),
        ),
        const SizedBox(height: 10),
        Text(
          'Hold and drag media to reorder',
          style: TextStyle(
            fontSize: 13,
            height: 1.2,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
