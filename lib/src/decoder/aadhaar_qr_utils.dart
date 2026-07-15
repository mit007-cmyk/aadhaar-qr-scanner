import 'dart:convert';
import 'dart:typed_data';

Uint8List bigIntToBytesBE(BigInt value) {
  if (value == BigInt.zero) {
    return Uint8List(0);
  }
  final byteCount = (value.bitLength + 7) ~/ 8;
  final result = Uint8List(byteCount);
  var remaining = value;
  for (var i = byteCount - 1; i >= 0; i--) {
    result[i] = (remaining & BigInt.from(0xff)).toInt();
    remaining = remaining >> 8;
  }
  return result;
}

Uint8List? normalizeScannerOutput({
  Uint8List? rawBytes,
  String? rawText,
}) {
  if (rawBytes != null && rawBytes.isNotEmpty) {
    return rawBytes;
  }
  final text = rawText?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  if (RegExp(r'^\d+$').hasMatch(text)) {
    return bigIntToBytesBE(BigInt.parse(text));
  }
  return utf8.encode(text);
}

String bytesToBase64(Uint8List bytes) => base64Encode(bytes);

String? imageMimeFromBytes(Uint8List blob) {
  if (blob.length >= 8 && blob[0] == 0x89 && blob[1] == 0x50) {
    return 'image/png';
  }
  if (blob.length >= 3 && blob[0] == 0xff && blob[1] == 0xd8 && blob[2] == 0xff) {
    return 'image/jpeg';
  }
  if (blob.length >= 12 &&
      blob[0] == 0x52 &&
      blob[1] == 0x49 &&
      blob[2] == 0x46 &&
      blob[3] == 0x46) {
    final header = latin1.decode(blob.sublist(0, 16), allowInvalid: true);
    if (header.contains('WEBP')) return 'image/webp';
  }
  if (blob.length >= 2 && blob[0] == 0x42 && blob[1] == 0x4d) {
    return 'image/bmp';
  }
  // JPEG 2000 (jp2) signature
  if (blob.length >= 12 &&
      blob[0] == 0x00 &&
      blob[1] == 0x00 &&
      blob[2] == 0x00 &&
      blob[3] == 0x0c &&
      blob[4] == 0x6a &&
      blob[5] == 0x50 &&
      blob[6] == 0x20 &&
      blob[7] == 0x20) {
    return 'image/jp2';
  }
  // JPEG 2000 codestream signature
  if (blob.length >= 4 &&
      blob[0] == 0xff &&
      blob[1] == 0x4f &&
      blob[2] == 0xff &&
      blob[3] == 0x51) {
    return 'image/jp2';
  }
  return null;
}

(String?, String?) photoFromBlob(Uint8List blob) {
  if (blob.length < 64) return (null, null);
  final mime = imageMimeFromBytes(blob);
  if (mime == null) return (null, null);
  return (bytesToBase64(blob), mime);
}

(String?, String?, String?, String?) extractXmlPhoto(Map<String, String> attrs) {
  for (final key in ['i', 'image', 'photo', 'p']) {
    final value = (attrs[key] ?? '').trim();
    if (value.isEmpty) continue;
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    if (compact.length < 64 || compact.length % 4 != 0) continue;
    if (!RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(compact)) continue;
    try {
      final blob = base64Decode(compact);
      final (b64, mime) = photoFromBlob(blob);
      if (b64 != null && mime != null) {
        return (b64, mime, b64, mime);
      }
    } catch (_) {
      continue;
    }
  }
  return (null, null, null, null);
}

(String?, String?) extractSecureSplitPhoto(List<Uint8List> parts) {
  if (parts.length < 2) return (null, null);
  for (var idx = 0; idx < parts.length - 1; idx++) {
    final markerTail = parts[idx].isNotEmpty ? parts[idx][0] : null;
    if (markerTail != 0x4f && markerTail != 0xd8) continue;
    if (parts[idx + 1].isEmpty) continue;
    final chunks = <int>[];
    for (var i = idx; i < parts.length; i++) {
      chunks.add(0xff);
      chunks.addAll(parts[i]);
    }
    final (b64, mime) = photoFromBlob(Uint8List.fromList(chunks));
    if (b64 != null) return (b64, mime);
  }
  return (null, null);
}

(String?, String?, String?, String?) extractSecurePhoto(
  List<Uint8List> parts,
  int start,
) {
  String? photoB64;
  String? photoMime;
  final extraParts = parts.length > start + 16 ? parts.sublist(start + 16) : <Uint8List>[];

  for (final blob in extraParts) {
    final direct = photoFromBlob(blob);
    if (direct.$1 != null) {
      photoB64 = direct.$1;
      photoMime = direct.$2;
      break;
    }

    final text = latin1.decode(blob, allowInvalid: true).replaceAll(RegExp(r'\s+'), '');
    if (text.length < 128 || text.length % 4 != 0) continue;
    if (!RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(text)) continue;
    try {
      final decoded = base64Decode(text);
      final fromB64 = photoFromBlob(decoded);
      if (fromB64.$1 != null) {
        photoB64 = fromB64.$1;
        photoMime = fromB64.$2;
        break;
      }
    } catch (_) {
      continue;
    }
  }

  if (photoB64 == null) {
    final split = extractSecureSplitPhoto(extraParts);
    photoB64 = split.$1;
    photoMime = split.$2;
  }

  if (photoB64 == null || photoMime == null) {
    return (null, null, null, null);
  }
  return (photoB64, photoMime, photoB64, photoMime);
}
