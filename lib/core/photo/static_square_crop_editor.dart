import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

enum _CropPanAxis { vertical, horizontal }

enum _ImageShape { portrait, landscape, square }

/// Fixed crop window; user pans/zooms the image underneath.
class StaticSquareCropEditor extends StatefulWidget {
  const StaticSquareCropEditor({
    super.key,
    required this.imageBytes,
    required this.cropWidth,
    required this.cropHeight,
    this.initialFocusFraction,
  });

  final Uint8List imageBytes;
  final double cropWidth;
  final double cropHeight;
  final Offset? initialFocusFraction;

  /// Scale 1.0 = fit-to-edge. Pinch can zoom in up to this factor, not out.
  static const double maxZoomInScale = 4.0;

  @override
  State<StaticSquareCropEditor> createState() => StaticSquareCropEditorState();
}

class StaticSquareCropEditorState extends State<StaticSquareCropEditor> {
  img.Image? _decoded;
  _ImageShape _shape = _ImageShape.square;
  _CropPanAxis _panAxis = _CropPanAxis.horizontal;

  double _scale = 1.0;
  double _maxScale = 1.0;
  double _minScale = 1.0;
  Offset _panOffset = Offset.zero;
  double _baseScale = 1.0;

  double? _configuredCropWidth;
  double? _configuredCropHeight;
  bool _initialized = false;

  int get _imgW => _decoded?.width ?? 1;
  int get _imgH => _decoded?.height ?? 1;

  Rect get _cropRect =>
      Rect.fromLTWH(0, 0, widget.cropWidth, widget.cropHeight);

  @override
  void initState() {
    super.initState();
    _decoded = img.decodeImage(widget.imageBytes);
  }

  @override
  void didUpdateWidget(StaticSquareCropEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cropWidth != widget.cropWidth ||
        oldWidget.cropHeight != widget.cropHeight) {
      _configuredCropWidth = null;
      _configuredCropHeight = null;
      _initialized = false;
    }
  }

  bool get isReady => _decoded != null;

  void _configureForCrop() {
    final cropW = widget.cropWidth;
    final cropH = widget.cropHeight;
    if (_decoded == null || cropW <= 0 || cropH <= 0) return;
    if (_configuredCropWidth == cropW &&
        _configuredCropHeight == cropH &&
        _initialized) {
      return;
    }

    final w = _imgW.toDouble();
    final h = _imgH.toDouble();

    if (h > w * 1.01) {
      _shape = _ImageShape.portrait;
      _panAxis = _CropPanAxis.vertical;
    } else if (w > h * 1.01) {
      _shape = _ImageShape.landscape;
      _panAxis = _CropPanAxis.horizontal;
    } else {
      _shape = _ImageShape.square;
      _panAxis = _CropPanAxis.horizontal;
    }

    _minScale = 1.0;
    _maxScale = StaticSquareCropEditor.maxZoomInScale;
    _scale = 1.0;
    _panOffset = _initialPanOffset();
    _clampPan();

    _configuredCropWidth = cropW;
    _configuredCropHeight = cropH;
    _initialized = true;
  }

  Offset _initialPanOffset() {
    final focus = widget.initialFocusFraction;
    if (focus == null) return Offset.zero;

    final display = _displaySize(1.0);

    if (_panAxis == _CropPanAxis.vertical) {
      return Offset(0, display.height * (0.5 - focus.dy));
    }

    return Offset(display.width * (0.5 - focus.dx), 0);
  }

  Size _displaySize(double scale) {
    final w = _imgW.toDouble();
    final h = _imgH.toDouble();
    final cropW = widget.cropWidth;
    final cropH = widget.cropHeight;

    switch (_shape) {
      case _ImageShape.portrait:
        final width = cropW * scale;
        return Size(width, width * (h / w));
      case _ImageShape.landscape:
      case _ImageShape.square:
        final height = cropH * scale;
        return Size(height * (w / h), height);
    }
  }

  Rect _imageRect() {
    final crop = _cropRect;
    final display = _displaySize(_scale);

    return Rect.fromLTWH(
      crop.left + (crop.width - display.width) / 2 + _panOffset.dx,
      crop.top + (crop.height - display.height) / 2 + _panOffset.dy,
      display.width,
      display.height,
    );
  }

  bool get _isZoomedIn => _scale > 1.0001;

  Rect _imageRectForPan(Offset pan) {
    final crop = _cropRect;
    final display = _displaySize(_scale);
    return Rect.fromLTWH(
      crop.left + (crop.width - display.width) / 2 + pan.dx,
      crop.top + (crop.height - display.height) / 2 + pan.dy,
      display.width,
      display.height,
    );
  }

  void _clampPan() {
    final crop = _cropRect;
    var dx = _panOffset.dx;
    var dy = _panOffset.dy;

    if (!_isZoomedIn) {
      if (_panAxis == _CropPanAxis.vertical) {
        dx = 0;
      } else {
        dy = 0;
      }
    }

    void clampHorizontal() {
      final image = _imageRectForPan(Offset(dx, dy));
      if (image.left > crop.left) {
        dx -= image.left - crop.left;
      }
      if (image.right < crop.right) {
        dx += crop.right - image.right;
      }
    }

    void clampVertical() {
      final image = _imageRectForPan(Offset(dx, dy));
      if (image.top > crop.top) {
        dy -= image.top - crop.top;
      }
      if (image.bottom < crop.bottom) {
        dy += crop.bottom - image.bottom;
      }
    }

    if (_isZoomedIn) {
      clampHorizontal();
      clampVertical();
    } else if (_panAxis == _CropPanAxis.vertical) {
      clampVertical();
    } else {
      clampHorizontal();
    }

    _panOffset = Offset(dx, dy);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    var changed = false;

    if (details.scale != 1.0) {
      final next = (_baseScale * details.scale).clamp(_minScale, _maxScale);
      if (next != _scale) {
        _scale = next;
        changed = true;
      }
    }

    if (details.focalPointDelta != Offset.zero) {
      final delta = details.focalPointDelta;
      final panDelta = _isZoomedIn
          ? delta
          : _panAxis == _CropPanAxis.vertical
              ? Offset(0, delta.dy)
              : Offset(delta.dx, 0);
      if (panDelta != Offset.zero) {
        _panOffset += panDelta;
        changed = true;
      }
    }

    if (changed) {
      _clampPan();
      setState(() {});
    }
  }

  Rect _cropPixelRect() {
    final crop = _cropRect;
    final image = _imageRect();
    final pxPerDisplayX = _imgW / image.width;
    final pxPerDisplayY = _imgH / image.height;

    var left = (crop.left - image.left) * pxPerDisplayX;
    var top = (crop.top - image.top) * pxPerDisplayY;
    var width = crop.width * pxPerDisplayX;
    var height = crop.height * pxPerDisplayY;

    left = left.clamp(0.0, _imgW.toDouble() - 1);
    top = top.clamp(0.0, _imgH.toDouble() - 1);
    width = width.clamp(1.0, _imgW - left);
    height = height.clamp(1.0, _imgH - top);

    return Rect.fromLTWH(left, top, width, height);
  }

  Future<Uint8List?> exportJpeg({int quality = 92}) async {
    final decoded = _decoded;
    if (decoded == null) return null;
    if (widget.cropWidth <= 0 || widget.cropHeight <= 0) return null;

    final src = _cropPixelRect();
    final cropped = img.copyCrop(
      decoded,
      x: src.left.round(),
      y: src.top.round(),
      width: src.width.round().clamp(1, _imgW),
      height: src.height.round().clamp(1, _imgH),
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: quality));
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    if (widget.cropWidth <= 0 || widget.cropHeight <= 0) {
      return const SizedBox.shrink();
    }

    _configureForCrop();
    final imageRect = _imageRect();

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: widget.cropWidth,
          height: widget.cropHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: imageRect.left,
                top: imageRect.top,
                width: imageRect.width,
                height: imageRect.height,
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RuleOfThirdsGridPainter(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleOfThirdsGridPainter extends CustomPainter {
  const _RuleOfThirdsGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    final dx = size.width / 3;
    final dy = size.height / 3;

    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(dx * i, 0), Offset(dx * i, size.height), paint);
      canvas.drawLine(Offset(0, dy * i), Offset(size.width, dy * i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
