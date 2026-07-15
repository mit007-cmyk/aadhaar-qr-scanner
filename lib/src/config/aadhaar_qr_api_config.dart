/// Backend API settings for Aadhaar QR image decoding.
class AadhaarQrApiConfig {
  const AadhaarQrApiConfig({
    required this.baseUrl,
    required this.apiKey,
  });

  /// API origin without a trailing slash, e.g. `https://aadhaar-qr-reader.indiap2p.com`.
  final String baseUrl;

  /// Value sent in the `x-api-key` request header.
  final String apiKey;
}
