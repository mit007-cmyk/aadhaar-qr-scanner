import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/decode_result.dart';
import '../services/aadhaar_qr_local_decoder.dart';
import '../widgets/qr_scanner_widget.dart';
import 'qr_details_screen.dart';

class DecodeScreen extends StatefulWidget {
  const DecodeScreen({super.key});

  @override
  State<DecodeScreen> createState() => _DecodeScreenState();
}

class _DecodeScreenState extends State<DecodeScreen> {
  final _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  late final AadhaarQrLocalDecoder _decoder = AadhaarQrLocalDecoder();

  bool _loading = false;
  String? _error;

  Future<void> _onBarcode(BarcodeCapture capture) async {
    if (_loading) return;

    for (final barcode in capture.barcodes) {
      setState(() {
        _loading = true;
        _error = null;
      });

      try {
        final result = _decoder.decodePayload(
          rawBytes: barcode.rawBytes == null ? null : Uint8List.fromList(barcode.rawBytes!),
          rawText: barcode.rawValue,
        );

        try {
          final logData = {
            'name': result.name,
            'dob': result.dob,
            'gender': result.gender,
            'address': result.address,
            'id_number': result.idNumber,
            'reference_id': result.referenceId,
            'pin': result.pin,
            'e_signed': result.eSigned,
            'photo_present': result.photoPresent,
            'photo_preview_base64': result.photoPreviewBase64 != null ? '<BASE64_PREVIEW_DATA_TRUNCATED>' : null,
            'photo_base64': result.photoBase64 != null ? '<BASE64_IMAGE_DATA_TRUNCATED>' : null,
          };
          debugPrint("============Photo Preview:==============");
          _printLongString(result.photoPreviewBase64);
          debugPrint("========================================");
          debugPrint('=== Aadhaar QR Local Decode Success ===');
          debugPrint(const JsonEncoder.withIndent('  ').convert(logData));
          debugPrint('=======================================');
        } catch (e) {
          debugPrint('Aadhaar QR Local Decode Success: Name: ${result.name}, DOB: ${result.dob}');
        }
        await _cameraController.stop();
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QrDetailsScreen(data: result),
          ),
        );
        if (!mounted) return;
        await _cameraController.start();
        return;
      } on DecodeException catch (e) {
        if (!mounted) return;
        setState(() => _error = e.message);
      } catch (e) {
        if (!mounted) return;
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _printLongString(String? text) {
    if (text == null) return;
    final int chunkSize = 800;
    for (int i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint(text.substring(i, end));
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aadhaar QR Scanner'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Scan the Aadhaar QR code using your camera. '
                'Decoding happens entirely on your device.',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: QrScannerWidget(
                      controller: _cameraController,
                      onDetect: _onBarcode,
                      isLoading: _loading,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.center_focus_strong_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please position the QR code in the center of the square for accurate scanning.',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Material(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade900, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
