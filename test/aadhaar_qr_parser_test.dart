import 'dart:convert';
import 'dart:typed_data';

import 'package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy XML payload includes gender', () {
    final raw = utf8.encode(
      '<PrintLetterBarcodeData uid="123412341234" name="Alice" gender="F" '
      'dob="01-01-1990" co="D/O Example" house="1" street="Main Road" '
      'vtc="Example City" dist="Example District" state="Example State" pc="110001" />',
    );

    final result = decodeAadhaarQrPayload(Uint8List.fromList(raw));

    expect(result, isNotNull);
    expect(result!.name, 'Alice');
    expect(result.gender, 'F');
    expect(result.idNumber, '123412341234');
  });

  test('secure QR payload parses from 0xFF-separated bytes', () {
    final signedData = Uint8List.fromList(<int>[
      ...'V5'.codeUnits,
      0xff,
      ...'3'.codeUnits,
      0xff,
      ...'123456789012345678901'.codeUnits,
      0xff,
      ...'Alice'.codeUnits,
      0xff,
      ...'01-01-1990'.codeUnits,
      0xff,
      ...'F'.codeUnits,
      0xff,
      ...'C/O Example'.codeUnits,
      0xff,
      ...'Example District'.codeUnits,
      0xff,
      ...'Example Landmark'.codeUnits,
      0xff,
      ...'1'.codeUnits,
      0xff,
      ...'Example Locality'.codeUnits,
      0xff,
      ...'110001'.codeUnits,
      0xff,
      ...'Example PO'.codeUnits,
      0xff,
      ...'Example State'.codeUnits,
      0xff,
      ...'Main Road'.codeUnits,
      0xff,
      ...'Example SubDist'.codeUnits,
      0xff,
      ...'Example VTC'.codeUnits,
      0xff,
    ]);

    final result = decodeAadhaarQrPayload(signedData);

    expect(result, isNotNull);
    expect(result!.name, 'Alice');
    expect(result.referenceId, '123456789012345678901');
    expect(result.pin, '110001');
  });
}
