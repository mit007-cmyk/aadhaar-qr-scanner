/// Parsed Aadhaar QR fields (mirrors Python qr_decode output shape).
class AadhaarQrData {
  const AadhaarQrData({
    this.name,
    this.dob,
    this.gender,
    this.address,
    this.idNumber,
    this.referenceId,
    this.pin,
    this.eSigned = false,
    this.photoPresent = false,
    this.photoBase64,
    this.photoMime,
    this.photoPreviewBase64,
    this.photoPreviewMime,
  });

  final String? name;
  final String? dob;
  final String? gender;
  final String? address;
  final String? idNumber;
  final String? referenceId;
  final String? pin;
  final bool eSigned;
  final bool photoPresent;
  final String? photoBase64;
  final String? photoMime;
  final String? photoPreviewBase64;
  final String? photoPreviewMime;

  factory AadhaarQrData.fromMap(Map<String, dynamic> map) {
    final photoB64 = map['photo_base64'] as String?;
    final previewB64 = map['photo_preview_base64'] as String?;
    return AadhaarQrData(
      name: map['name'] as String?,
      dob: map['dob'] as String?,
      gender: map['gender'] as String?,
      address: map['address'] as String?,
      idNumber: map['id_number'] as String?,
      referenceId: map['reference_id'] as String?,
      pin: map['pin'] as String?,
      eSigned: map['e_signed'] == true,
      photoPresent: (photoB64?.isNotEmpty ?? false) || (previewB64?.isNotEmpty ?? false),
      photoBase64: photoB64,
      photoMime: map['photo_mime'] as String?,
      photoPreviewBase64: previewB64,
      photoPreviewMime: map['photo_preview_mime'] as String?,
    );
  }
}

class DecodeException implements Exception {
  DecodeException(this.message);
  final String message;
  @override
  String toString() => message;
}
