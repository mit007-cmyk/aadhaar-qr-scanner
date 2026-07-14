import 'package:xml/xml.dart';

import 'aadhaar_qr_utils.dart';
import 'secure_qr_parser.dart';

Map<String, dynamic>? parseXmlQrPayload(String text) {
  try {
    final doc = XmlDocument.parse(text);
    final root = doc.rootElement;
    final attrs = <String, String>{
      for (final attr in root.attributes) attr.name.local: attr.value,
    };

    final rootTag = root.name.local.toUpperCase();
    final singleLineAddress = cleanSecureQrText(attrs['address'] ?? attrs['a'] ?? '');
    var stateValue = attrs['state'];
    if ((stateValue == null || stateValue.isEmpty) && rootTag != 'QPDA') {
      stateValue = attrs['s'];
    }

    String? address;
    if (singleLineAddress.isNotEmpty && !secureQrIsBinaryGarbage(singleLineAddress)) {
      address = singleLineAddress;
    } else {
      final addrParts = [
        attrs['co'],
        attrs['house'] ?? attrs['h'],
        attrs['street'] ?? attrs['st'],
        attrs['lm'],
        attrs['loc'],
        attrs['vtc'],
        attrs['subdist'],
        attrs['po'],
        attrs['dist'],
        stateValue,
        attrs['pc'],
      ];
      address = addrParts.whereType<String>().where((p) => p.trim().isNotEmpty).join(', ');
    }
    if (secureQrIsBinaryGarbage(address)) address = null;

    var name = attrs['name'] ?? attrs['n'];
    if (secureQrIsBinaryGarbage(name ?? '')) name = null;

    var gender = attrs['gender'] ?? attrs['g'];
    if (gender != null && secureQrIsBinaryGarbage(gender)) gender = null;

    final photo = extractXmlPhoto(attrs);
    return {
      'name': name,
      'dob': attrs['dob'] ?? attrs['d'],
      'gender': gender,
      'address': address,
      'id_number': attrs['uid'] ?? attrs['v'] ?? attrs['u'],
      'sig_verified': true,
      'e_signed': false,
      'photo_base64': photo.$1,
      'photo_mime': photo.$2,
      'photo_preview_base64': photo.$3,
      'photo_preview_mime': photo.$4,
    };
  } catch (_) {
    return null;
  }
}
