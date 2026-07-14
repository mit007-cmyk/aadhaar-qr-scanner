import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/decode_result.dart';
import '../services/jp2_decoder_service.dart';

class QrDetailsScreen extends StatefulWidget {
  final AadhaarQrData data;
  final String? qualityWarning;

  const QrDetailsScreen({
    super.key,
    required this.data,
    this.qualityWarning,
  });

  @override
  State<QrDetailsScreen> createState() => _QrDetailsScreenState();
}

class _QrDetailsScreenState extends State<QrDetailsScreen> {
  Uint8List? _photoBytes;
  bool _isDecoding = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final previewB64 = widget.data.photoPreviewBase64;
    final previewMime = widget.data.photoPreviewMime;
    final mainB64 = widget.data.photoBase64;
    final mainMime = widget.data.photoMime;

    // Decode synchronously only if the preview is a standard image (like PNG/JPEG from API)
    if (previewB64 != null && previewB64.isNotEmpty && previewMime != 'image/jp2') {
      try {
        final cleanB64 = previewB64.replaceAll(RegExp(r'\s+'), '');
        setState(() {
          _photoBytes = base64Decode(cleanB64);
        });
      } catch (_) {}
      return;
    }

    final targetB64 = mainB64 ?? previewB64;
    final targetMime = mainMime ?? previewMime;
    debugPrint("============Target MIME:============== $targetMime ===================");

    if (targetB64 != null && targetB64.isNotEmpty) {
      final isJp2 = targetMime == 'image/jp2';
      try {
        final cleanB64 = targetB64.replaceAll(RegExp(r'\s+'), '');
        final rawBytes = base64Decode(cleanB64);

        if (isJp2) {
          setState(() {
            _isDecoding = true;
          });
          final pngBytes = await Jp2DecoderService.decodeJp2ToPng(rawBytes);
          if (!mounted) return;
          setState(() {
            _photoBytes = pngBytes;
            _isDecoding = false;
          });
        } else {
          setState(() {
            _photoBytes = rawBytes;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isDecoding = false;
          });
        }
      }
    }
  }

  String _formatValue(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value.trim();
  }

  String _genderText(String? gender) {
    if (gender == null || gender.trim().isEmpty) return '-';
    final g = gender.trim().toUpperCase();
    if (g == 'M') return 'Male';
    if (g == 'F') return 'Female';
    return g;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decoded Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.qualityWarning != null && widget.qualityWarning!.isNotEmpty) ...[
              Card(
                color: Colors.amber.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.amber.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.qualityWarning!,
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Profile & Signature Verification Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Photo
                    if (_isDecoding)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_photoBytes != null)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _photoBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade100,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade400,
                          size: 60,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      _formatValue(widget.data.name),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // E-Sign Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.data.eSigned ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.data.eSigned ? Colors.green.shade200 : Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.data.eSigned ? Icons.verified_user : Icons.gpp_maybe,
                            color: widget.data.eSigned ? Colors.green.shade700 : Colors.red.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.data.eSigned ? 'e-Signed Verified' : 'e-Signed: No',
                            style: TextStyle(
                              color: widget.data.eSigned ? Colors.green.shade800 : Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Details List Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      icon: Icons.cake_outlined,
                      label: 'Date of Birth',
                      value: _formatValue(widget.data.dob),
                    ),
                    const Divider(indent: 56),
                    _buildDetailRow(
                      context,
                      icon: Icons.wc_outlined,
                      label: 'Gender',
                      value: _genderText(widget.data.gender),
                    ),
                    const Divider(indent: 56),
                    _buildDetailRow(
                      context,
                      icon: Icons.badge_outlined,
                      label: 'Aadhaar / ID Number',
                      value: _formatValue(widget.data.idNumber),
                    ),
                    const Divider(indent: 56),
                    _buildDetailRow(
                      context,
                      icon: Icons.tag_outlined,
                      label: 'Reference ID',
                      value: _formatValue(widget.data.referenceId),
                    ),
                    const Divider(indent: 56),
                    _buildDetailRow(
                      context,
                      icon: Icons.pin_drop_outlined,
                      label: 'PIN Code',
                      value: _formatValue(widget.data.pin),
                    ),
                    const Divider(indent: 56),
                    _buildDetailRow(
                      context,
                      icon: Icons.home_outlined,
                      label: 'Address',
                      value: _formatValue(widget.data.address),
                      isMultiline: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Scanner'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
