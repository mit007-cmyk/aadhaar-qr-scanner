import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Live camera QR scanner with a centered square scan frame overlay.
class QrScannerWidget extends StatelessWidget {
  const QrScannerWidget({
    super.key,
    required this.controller,
    required this.onDetect,
    this.isLoading = false,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final bool isLoading;

  static const double _scanFrameRatio = 0.72;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              onDetect: onDetect,
            ),
            CustomPaint(
              painter: _ScannerOverlayPainter(
                scanFrameRatio: _scanFrameRatio,
                borderColor: Colors.white,
                overlayColor: Colors.black.withValues(alpha: 0.55),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final frameSize = constraints.maxWidth * _scanFrameRatio;
                final frameLeft = (constraints.maxWidth - frameSize) / 2;
                final frameTop = (constraints.maxHeight - frameSize) / 2;

                return Stack(
                  children: [
                    Positioned(
                      left: frameLeft,
                      top: frameTop,
                      width: frameSize,
                      height: frameSize,
                      child: _ScanFrameCorners(color: colorScheme.primary),
                    ),
                    if (isLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            const SizedBox(height: 12),
                            Text(
                              'Decoding QRΓÇª',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({
    required this.scanFrameRatio,
    required this.borderColor,
    required this.overlayColor,
  });

  final double scanFrameRatio;
  final Color borderColor;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final frameSize = size.width * scanFrameRatio;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    final scanRect = Rect.fromLTWH(left, top, frameSize, frameSize);
    final roundedRect = RRect.fromRectAndRadius(
      scanRect,
      const Radius.circular(12),
    );

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(roundedRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);
    canvas.drawRRect(
      roundedRect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanFrameRatio != scanFrameRatio ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.overlayColor != overlayColor;
  }
}

class _ScanFrameCorners extends StatelessWidget {
  const _ScanFrameCorners({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerPainter(color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 28.0;
    const strokeWidth = 4.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset start, Offset horizontalEnd, Offset verticalEnd) {
      canvas.drawLine(start, horizontalEnd, paint);
      canvas.drawLine(start, verticalEnd, paint);
    }

    drawCorner(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      const Offset(0, cornerLength),
    );
    drawCorner(
      Offset(size.width, 0),
      Offset(size.width - cornerLength, 0),
      Offset(size.width, cornerLength),
    );
    drawCorner(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      Offset(0, size.height - cornerLength),
    );
    drawCorner(
      Offset(size.width, size.height),
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height - cornerLength),
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
