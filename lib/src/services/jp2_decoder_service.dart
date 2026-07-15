import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Jp2DecoderService {
  static const _channel = MethodChannel('com.indiap2p.aadhaar_qr_scanner/jp2_decoder');

  /// Decodes JPEG 2000 (JP2) bytes to standard PNG bytes.
  static Future<Uint8List?> decodeJp2ToPng(Uint8List jp2Bytes) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('decodeJp2', {
        'bytes': jp2Bytes,
      });
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to decode JP2 image: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error decoding JP2: $e');
      return null;
    }
  }
}
