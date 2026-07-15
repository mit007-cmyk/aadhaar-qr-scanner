import 'dart:typed_data';

import '../decoder/aadhaar_qr_decoder.dart';
import '../decoder/aadhaar_qr_utils.dart';
import '../models/decode_result.dart';

/// Parses Aadhaar QR payloads detected by ML Kit on-device in Dart.
class AadhaarQrLocalDecoder {
  AadhaarQrData decodePayload({
    Uint8List? rawBytes,
    String? rawText,
  }) {
    final payload = normalizeScannerOutput(rawBytes: rawBytes, rawText: rawText);
    if (payload == null || payload.isEmpty) {
      throw DecodeException('Empty QR payload.');
    }
    final parsed = decodeAadhaarQrPayload(payload);
    if (parsed == null) {
      throw DecodeException('Unrecognized Aadhaar QR format.');
    }
    return parsed;
  }
}
