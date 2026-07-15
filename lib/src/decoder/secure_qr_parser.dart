import 'dart:convert';
import 'dart:math' show max, min;
import 'dart:typed_data';

import 'aadhaar_qr_utils.dart';

final _secureDobRe = RegExp(r'^(?:\d{2}[/-]\d{2}[/-]\d{4}|\d{4}|\d{8})$');
final _secureRefRe = RegExp(r'^\d{12,24}$');
final _pinRe = RegExp(r'^([1-9]\d{5})$');
const _secureGenders = {'M', 'F', 'T', 'MALE', 'FEMALE', 'TRANSGENDER'};

String cleanSecureQrText(String value) {
  value = value.replaceAll('\x00', ' ').replaceAll('\ufeff', ' ');
  value = value.split('').where((ch) {
    final code = ch.codeUnitAt(0);
    return ch == '\n' || ch == '\t' || (code >= 32 && code <= 126) || code > 127;
  }).join();
  return value.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[ ,;:-]+$'), '').trim();
}

bool secureQrIsBinaryGarbage(String value) {
  if (value.isEmpty || value.length < 20) return false;
  if (!value.contains(' ') && value.length > 50 && value.contains(RegExp(r'[/+=]'))) {
    return true;
  }
  final nonAscii = value.runes.where((c) => c > 127).length;
  if (nonAscii / value.length > 0.15) return true;
  final control = value.runes.where((c) => c < 32 && c != 10 && c != 9 && c != 13).length;
  if (control / value.length > 0.05) return true;
  return false;
}

int? secureQrIndicator(String value) {
  value = value.trim();
  if (value.isEmpty) return null;
  if (value.length == 1) {
    final code = value.codeUnitAt(0);
    if ({0, 1, 2, 3}.contains(code)) return code;
  }
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (['0', '1', '2', '3'].contains(compact)) return int.parse(compact);
  return null;
}

bool secureQrLooksLikeName(String value) {
  value = cleanSecureQrText(value);
  if (value.length < 3 || secureQrIsBinaryGarbage(value)) return false;
  final alpha = value.runes.where((c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122)).length;
  final digits = value.runes.where((c) => c >= 48 && c <= 57).length;
  return alpha >= 3 && digits <= (value.length ~/ 5 > 2 ? value.length ~/ 5 : 2);
}

bool secureQrLooksLikeDob(String value) {
  return _secureDobRe.hasMatch(value.replaceAll(RegExp(r'\s+'), ''));
}

bool secureQrLooksLikeGender(String value) {
  final compact = value.replaceAll(RegExp(r'[^A-Za-z]'), '').toUpperCase();
  return _secureGenders.contains(compact);
}

bool secureQrLooksLikeState(String value) {
  value = cleanSecureQrText(value);
  if (value.isEmpty || secureQrIsBinaryGarbage(value)) return false;
  final alpha = value.runes.where((c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122)).length;
  final digits = value.runes.where((c) => c >= 48 && c <= 57).length;
  return alpha >= 4 && digits <= 1;
}

String? secureQrBuildAddress(Map<String, String> fields) {
  final loc = fields['location'] ?? '';
  final vtc = fields['vtc'] ?? '';
  final subDist = fields['sub_dist'] ?? '';
  final district = fields['district'] ?? '';

  String norm(String text) => text.replaceAll(RegExp(r'[\s()\-_.,]'), '').toLowerCase();
  final seenNorm = {norm(loc)}..remove('');

  String dedup(String value) {
    final n = norm(value);
    if (n.isEmpty || seenNorm.contains(n)) return '';
    seenNorm.add(n);
    return value;
  }

  final addrParts = [
    fields['care_of'] ?? '',
    fields['house'] ?? '',
    fields['street'] ?? '',
    loc,
    fields['landmark'] ?? '',
    dedup(vtc),
    dedup(subDist),
    fields['post_office'] ?? '',
    dedup(district),
    fields['state'] ?? '',
    fields['pin'] ?? '',
  ];
  final address = addrParts.where((p) => p.trim().isNotEmpty).join(', ');
  if (secureQrIsBinaryGarbage(address)) return null;
  return address.isEmpty ? null : address;
}

bool looksLikeSecureQrPayload(Uint8List data) {
  if (data.length < 20) return false;
  var idx = 0;
  while (idx < data.length && {0x20, 0x09, 0x0a, 0x0d}.contains(data[idx])) {
    idx++;
  }
  if (idx < data.length && data[idx] == 0x3c) return false;
  if (!data.contains(0xff)) return false;
  return data.where((b) => b == 0xff).length >= 11;
}

Map<String, dynamic>? parseSecureQrPayload(Uint8List data) {
  if (!looksLikeSecureQrPayload(data)) return null;

  final parts = <Uint8List>[];
  var startIdx = 0;
  for (var i = 0; i <= data.length; i++) {
    if (i == data.length || data[i] == 0xff) {
      parts.add(data.sublist(startIdx, i));
      startIdx = i + 1;
    }
  }

  String decodeField(Uint8List blob) => cleanSecureQrText(latin1.decode(blob, allowInvalid: true));
  final decoded = parts.take(24).map(decodeField).toList();

  Map<String, dynamic>? best;
  final maxStart = max(1, min(5, decoded.length - 15));

  for (var start = 0; start < maxStart; start++) {
    String g(int offset) {
      final idx = start + offset;
      return idx < decoded.length ? decoded[idx] : '';
    }

    final refId = g(1).replaceAll(RegExp(r'\D'), '');
    final pinDigits = g(10).replaceAll(RegExp(r'\D'), '');
    final fields = <String, String>{
      'name': g(2),
      'dob': g(3),
      'gender': g(4),
      'care_of': g(5),
      'district': g(6),
      'landmark': g(7),
      'house': g(8),
      'location': g(9),
      'pin': pinDigits.length > 6 ? pinDigits.substring(0, 6) : pinDigits,
      'post_office': g(11),
      'state': g(12),
      'street': g(13),
      'sub_dist': g(14),
      'vtc': g(15),
    };
    final address = secureQrBuildAddress(fields);

    var score = 0.0;
    if (secureQrIndicator(g(0)) != null) score += 2.0;
    if (_secureRefRe.hasMatch(refId)) score += 1.5;
    if (secureQrLooksLikeName(fields['name']!)) score += 3.0;
    if (secureQrLooksLikeDob(fields['dob']!)) score += 2.0;
    if (secureQrLooksLikeGender(fields['gender']!)) score += 1.0;
    if (_pinRe.hasMatch(fields['pin']!)) score += 3.0;
    if (secureQrLooksLikeState(fields['state']!)) score += 1.0;
    if (address != null) {
      score += 2.0;
      if (address.length >= 20) score += 1.0;
    }

    if (secureQrIsBinaryGarbage(fields['name']!)) score -= 5.0;
    for (final key in ['care_of', 'district', 'landmark', 'house', 'location', 'street', 'sub_dist', 'vtc']) {
      if (secureQrIsBinaryGarbage(fields[key]!)) score -= 2.0;
    }

    final candidate = {
      'score': score,
      'start': start,
      'ref_id': refId,
      'result': {
        'name': fields['name']!.isEmpty ? null : fields['name'],
        'dob': fields['dob']!.isEmpty ? null : fields['dob'],
        'gender': secureQrLooksLikeGender(fields['gender']!) ? fields['gender'] : null,
        'address': address,
        'id_number': null,
      },
      'pin': fields['pin'],
    };

    if (best == null || (candidate['score'] as double) > (best['score'] as double)) {
      best = candidate;
    }
  }

  if (best == null) return null;
  final result = Map<String, dynamic>.from(best['result'] as Map);
  final score = best['score'] as double;
  final pin = best['pin'] as String;
  final start = best['start'] as int;

  if (score < 6.0 || result['name'] == null || (result['address'] == null && pin.isEmpty)) {
    return null;
  }

  final out = Map<String, dynamic>.from(result);
  final refId = best['ref_id'] as String;
  out['reference_id'] = refId.isEmpty ? null : refId;
  out['id_number'] = maskAadhaarFromReferenceId(refId);
  final cleanPin = pin.replaceAll(RegExp(r'\D'), '');
  if (cleanPin.length == 6 && cleanPin[0] != '0') {
    out['pin'] = cleanPin;
    final addr = (out['address'] as String?)?.trim() ?? '';
    if (!addr.contains(cleanPin)) {
      out['address'] = addr.isEmpty ? cleanPin : '$addr, $cleanPin';
    }
  }

  final photo = extractSecurePhoto(parts, start);
  out['photo_base64'] = photo.$1;
  out['photo_mime'] = photo.$2;
  out['photo_preview_base64'] = photo.$3;
  out['photo_preview_mime'] = photo.$4;
  out['sig_verified'] = false;
  out['e_signed'] = false;
  return out;
}
