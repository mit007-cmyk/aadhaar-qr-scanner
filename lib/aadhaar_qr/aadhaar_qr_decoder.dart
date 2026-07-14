import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../models/decode_result.dart';
import 'aadhaar_qr_utils.dart';
import 'secure_qr_parser.dart';
import 'xml_qr_parser.dart';

Map<String, dynamic>? parseQrBytes(Uint8List raw) {
  if (raw.length < 20) return null;

  final candidates = <MapEntry<String, Uint8List>>[MapEntry('raw', raw)];
  final seen = {sha256.convert(raw).bytes};

  try {
    final textAttempt = ascii.decode(raw, allowInvalid: false).trim();
    if (RegExp(r'^\d+$').hasMatch(textAttempt)) {
      final numBytes = bigIntToBytesBE(BigInt.parse(textAttempt));
      if (numBytes.length >= 20) {
        final fp = sha256.convert(numBytes).bytes;
        if (!seen.contains(fp)) {
          seen.add(fp);
          candidates.insert(0, MapEntry('secure_bignum', numBytes));
        }
      }
    }
  } catch (_) {}

  final sourceEntries = List<MapEntry<String, Uint8List>>.from(candidates);
  for (final entry in sourceEntries) {
    for (final wbits in [-15, 15, 47]) {
      try {
        final dec = _decompress(entry.value, wbits);
        if (dec == null || dec.length < 20) continue;
        final fp = sha256.convert(dec).bytes;
        if (seen.contains(fp)) continue;
        seen.add(fp);
        candidates.add(MapEntry('${entry.key}_zlib$wbits', dec));
      } catch (_) {}
    }
  }

  for (final entry in candidates) {
    final data = entry.value;
    if (looksLikeSecureQrPayload(data)) {
      final secure = parseSecureQrPayload(data);
      if (secure != null) return secure;
    }

    final text = utf8.decode(data, allowMalformed: true);
    final xml = parseXmlQrPayload(text);
    if (xml != null) return xml;
  }

  return null;
}

Uint8List? _decompress(Uint8List source, int wbits) {
  if (wbits == -15) {
    return Uint8List.fromList(Inflate(source).getBytes());
  }
  if (wbits == 15) {
    return Uint8List.fromList(const ZLibDecoder().decodeBytes(source));
  }
  if (wbits == 47) {
    return Uint8List.fromList(const GZipDecoder().decodeBytes(source));
  }
  return null;
}

AadhaarQrData? decodeAadhaarQrPayload(Uint8List raw) {
  final map = parseQrBytes(raw);
  if (map == null) return null;
  map.putIfAbsent('e_signed', () => false);
  return AadhaarQrData.fromMap(map);
}
