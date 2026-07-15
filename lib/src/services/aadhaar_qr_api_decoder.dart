import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/aadhaar_qr_api_config.dart';
import '../models/decode_result.dart';

/// Decodes Aadhaar QR data by uploading a captured image to the backend API.
class AadhaarQrApiDecoder {
  AadhaarQrApiDecoder(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  final AadhaarQrApiConfig config;
  final http.Client _client;

  static const _decodePath = '/ocr/aadhaar/qr/decode-image';

  /// Uploads [imageBytes] as multipart `file`, or sends [imageBase64] as `image_b64`.
  Future<AadhaarQrData> decodeImage({
    Uint8List? imageBytes,
    String? imageBase64,
  }) async {
    final hasBytes = imageBytes != null && imageBytes.isNotEmpty;
    final hasBase64 = imageBase64 != null && imageBase64.isNotEmpty;
    if (!hasBytes && !hasBase64) {
      throw DecodeException('No image data to decode.');
    }

    final uri = Uri.parse('${config.baseUrl}$_decodePath');
    final request = http.MultipartRequest('POST', uri)
      ..headers['x-api-key'] = config.apiKey;

    if (hasBytes) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'aadhaar-scan.jpg',
        ),
      );
    } else {
      request.fields['image_b64'] = imageBase64!;
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final body = _decodeJsonBody(response.body);

    if (response.statusCode != 200) {
      throw DecodeException(_errorMessage(body, response.statusCode));
    }

    return AadhaarQrData.fromMap(_extractPayload(body));
  }

  void close() => _client.close();

  Map<String, dynamic> _decodeJsonBody(String raw) {
    if (raw.trim().isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw DecodeException('Unexpected API response format.');
    } on FormatException {
      throw DecodeException('Invalid JSON response from decode API.');
    }
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> body) {
    for (final key in ['data', 'result', 'payload']) {
      final nested = body[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
    }
    return body;
  }

  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final detail = body['detail'];
    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        return first['msg'] as String;
      }
    }

    for (final key in ['message', 'error']) {
      final value = body[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    return 'Decode API failed with status $statusCode.';
  }
}
