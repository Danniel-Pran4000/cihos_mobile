import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';

class AvatarPositionScreen extends StatefulWidget {
  const AvatarPositionScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<AvatarPositionScreen> createState() => _AvatarPositionScreenState();
}

class _AvatarPositionScreenState extends State<AvatarPositionScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformationController =
      TransformationController();

  double _currentScale = 1.0;
  int _quarterTurns = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(() {
      final scale = _transformationController.value.getMaxScaleOnAxis();
      if (scale != _currentScale) {
        setState(() {
          _currentScale = scale.clamp(0.5, 4.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    setState(() => _currentScale = value);
    final translation = _transformationController.value.getTranslation();
    final matrix = Matrix4.identity()
      ..translateByVector3(translation)
      ..scaleByDouble(value, value, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _rotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _reset() {
    setState(() {
      _quarterTurns = 0;
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  Future<void> _cropAndSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Small frame delay to ensure everything is rendered
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = File(
        '${tempDir.path}/avatar_cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses gambar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const double circleSize = 280.0;

    return Scaffold(
      backgroundColor: const Color(0xFF161828),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Atur Posisi Foto',
          style: AppTypography.headingMd.copyWith(
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh, color: AppColors.white),
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                'Geser dan cubit layar untuk menyesuaikan posisi serta ukuran foto di dalam lingkaran.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
            const Spacer(),
            // Cropping Area
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Repaint boundary wrapping the circle to be saved
                  RepaintBoundary(
                    key: _cropKey,
                    child: ClipOval(
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: _quarterTurns,
                              child: Image.file(
                                widget.imageFile,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Decorative circular border overlay
                  IgnorePointer(
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.8),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Controls: Slider & Rotate Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Putar Foto',
                    icon: const Icon(
                      Icons.rotate_right_rounded,
                      color: AppColors.white,
                      size: 28,
                    ),
                    onPressed: _rotate,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.zoom_out,
                    color: AppColors.white,
                    size: 20,
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentScale,
                      min: 0.5,
                      max: 4.0,
                      activeColor: AppColors.white,
                      inactiveColor: AppColors.white.withValues(alpha: 0.3),
                      onChanged: _onSliderChanged,
                    ),
                  ),
                  const Icon(
                    Icons.zoom_in,
                    color: AppColors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xl,
              ),
              child: AppButton(
                label: 'Gunakan Foto',
                expand: true,
                isLoading: _isProcessing,
                background: AppColors.accentSoft,
                onPressed: _cropAndSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
