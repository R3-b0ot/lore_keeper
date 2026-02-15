import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:native_image_cropper/native_image_cropper.dart';

const List<double> _cropRatios = [
  1 / 1,
  2 / 3,
  3 / 2,
  4 / 3,
  3 / 4,
  4 / 5,
  5 / 4,
  16 / 9,
  9 / 16,
];

Future<({Uint8List bytes, double ratio})?> showNativeCropDialog({
  required BuildContext context,
  required Uint8List bytes,
  double initialRatio = 1.0,
}) {
  return showDialog<({Uint8List bytes, double ratio})>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        _NativeCropDialog(bytes: bytes, initialRatio: initialRatio),
  );
}

class _NativeCropDialog extends StatefulWidget {
  final Uint8List bytes;
  final double initialRatio;

  const _NativeCropDialog({required this.bytes, required this.initialRatio});

  @override
  State<_NativeCropDialog> createState() => _NativeCropDialogState();
}

class _NativeCropDialogState extends State<_NativeCropDialog>
    with TickerProviderStateMixin {
  late final CropController _controller;
  double? _targetRatio = 1.0;
  double _animatedRatio = 1.0;
  late final AnimationController _ratioController;
  Animation<double> _ratioAnimation = const AlwaysStoppedAnimation(1.0);
  bool _isCropping = false;
  String? _errorMessage;
  bool _isFreeform = false;

  @override
  void initState() {
    super.initState();
    _controller = CropController()
      ..mode = CropMode.rect
      ..bytes = widget.bytes;
    _targetRatio = widget.initialRatio > 0
        ? widget.initialRatio
        : _cropRatios.first;
    _animatedRatio = _targetRatio ?? 1.0;
    _ratioController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _ratioAnimation = AlwaysStoppedAnimation(_animatedRatio);
    _ratioController.addListener(_onRatioTick);
  }

  @override
  void dispose() {
    _ratioController.removeListener(_onRatioTick);
    _ratioController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final maskOptions = MaskOptions(
      backgroundColor: kIsWeb
          ? Colors.transparent
          : cs.surface.withValues(alpha: 0.7),
      borderColor: cs.primary,
      strokeWidth: 2,
      aspectRatio: _isFreeform ? null : _animatedRatio,
      minSize: 80,
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogHeader(onClose: _close),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: CropPreview(
                            bytes: widget.bytes,
                            controller: _controller,
                            maskOptions: maskOptions,
                            dragPointSize: 18,
                            hitSize: 16,
                            dragPointBuilder: (size, _) =>
                                CropDragPoint(size: size, color: cs.primary),
                            loadingWidget: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cropRatios.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ChoiceChip(
                        label: const Text('Custom'),
                        selected: _isFreeform,
                        onSelected: (_) {
                          setState(() {
                            _isFreeform = true;
                            _targetRatio = null;
                          });
                        },
                      );
                    }
                    final ratio = _cropRatios[index - 1];
                    final isSelected = !_isFreeform && ratio == _targetRatio;
                    return ChoiceChip(
                      label: Text(_ratioLabel(ratio)),
                      selected: isSelected,
                      onSelected: (_) => _animateRatioTo(ratio),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isCropping ? null : _close,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _isCropping ? null : _useOriginal,
                    child: const Text('Use Original'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isCropping ? null : _cropImage,
                    child: _isCropping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop();
  }

  void _animateRatioTo(double ratio) {
    if (ratio == _targetRatio && !_isFreeform) return;
    _isFreeform = false;
    _targetRatio = ratio;
    final begin = _animatedRatio;
    _ratioAnimation = Tween<double>(
      begin: begin,
      end: ratio,
    ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_ratioController);
    _ratioController.forward(from: 0);
    setState(() {});
  }

  void _onRatioTick() {
    if (!mounted) return;
    setState(() {
      _animatedRatio = _ratioAnimation.value;
    });
  }

  Future<void> _useOriginal() async {
    setState(() {
      _isCropping = true;
      _errorMessage = null;
    });
    try {
      final ratio = await _decodeRatio(widget.bytes);
      if (!mounted) return;
      Navigator.of(context).pop((bytes: widget.bytes, ratio: ratio));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCropping = false;
        _errorMessage = 'Unable to use original image.';
      });
    }
  }

  Future<void> _cropImage() async {
    if (!_canCrop) {
      setState(() {
        _errorMessage = 'Image is still loading. Please try again.';
      });
      return;
    }

    setState(() {
      _isCropping = true;
      _errorMessage = null;
    });
    try {
      final cropped = _useNativeCropper
          ? await _controller.crop(
              format: kIsWeb ? ImageFormat.png : ImageFormat.jpg,
            )
          : await _cropWithDart();
      final ratio = await _decodeRatio(cropped);
      if (!mounted) return;
      Navigator.of(context).pop((bytes: cropped, ratio: ratio));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCropping = false;
        _errorMessage = 'Unable to crop image. ${_formatError(error)}';
      });
    }
  }

  bool get _canCrop =>
      _controller.cropRect != null &&
      _controller.imageRect != null &&
      _controller.imageSize != null &&
      _controller.bytes != null;

  bool get _useNativeCropper =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String _formatError(Object error) {
    final message = error.toString();
    if (message.contains('NullPointerException')) {
      return 'Crop area is not ready.';
    }
    return 'Please try again.';
  }

  Future<Uint8List> _cropWithDart() async {
    final cropRect = _controller.cropRect;
    final imageRect = _controller.imageRect;
    final imageSize = _controller.imageSize;
    final bytes = _controller.bytes;

    if (cropRect == null ||
        imageRect == null ||
        imageSize == null ||
        bytes == null) {
      throw StateError('Crop data not ready');
    }

    final x = cropRect.left / imageRect.width * imageSize.width;
    final y = cropRect.top / imageRect.height * imageSize.height;
    final width = cropRect.width / imageRect.width * imageSize.width;
    final height = cropRect.height / imageRect.height * imageSize.height;

    final srcLeft = x.clamp(0, imageSize.width - 1);
    final srcTop = y.clamp(0, imageSize.height - 1);
    final srcWidth = width.clamp(1, imageSize.width - srcLeft);
    final srcHeight = height.clamp(1, imageSize.height - srcTop);

    final image = await _decodeUiImage(bytes);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final srcRect = Rect.fromLTWH(
      srcLeft.toDouble(),
      srcTop.toDouble(),
      srcWidth.toDouble(),
      srcHeight.toDouble(),
    );
    final dstRect = Rect.fromLTWH(
      0,
      0,
      srcWidth.toDouble(),
      srcHeight.toDouble(),
    );
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(
      srcWidth.toInt(),
      srcHeight.toInt(),
    );
    image.dispose();
    final data = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    croppedImage.dispose();
    if (data == null) {
      throw StateError('Crop failed');
    }
    return data.buffer.asUint8List();
  }

  Future<double> _decodeRatio(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    final image = await completer.future;
    final ratio = image.width / image.height;
    image.dispose();
    return ratio;
  }

  Future<ui.Image> _decodeUiImage(Uint8List bytes) async {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  String _ratioLabel(double ratio) {
    if (ratio == 1.0) return '1:1';
    if (ratio == 2 / 3) return '2:3';
    if (ratio == 3 / 2) return '3:2';
    if (ratio == 4 / 3) return '4:3';
    if (ratio == 3 / 4) return '3:4';
    if (ratio == 4 / 5) return '4:5';
    if (ratio == 5 / 4) return '5:4';
    if (ratio == 16 / 9) return '16:9';
    if (ratio == 9 / 16) return '9:16';
    return ratio.toStringAsFixed(2);
  }
}

class _DialogHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _DialogHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text('Crop Image', style: theme.textTheme.titleLarge)),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(LucideIcons.x),
        ),
      ],
    );
  }
}
