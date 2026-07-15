import 'package:flutter/material.dart';
import 'package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart';

void main() {
  runApp(const AadhaarQrScannerExampleApp());
}

class AadhaarQrScannerExampleApp extends StatelessWidget {
  const AadhaarQrScannerExampleApp({super.key});

  static const _apiConfig = AadhaarQrApiConfig(
    baseUrl: 'https://aadhaar-qr-reader.indiap2p.com',
    apiKey: '22609608-0012-45e0-b624-16fc6882e210',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aadhaar QR Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DecodeScreen(apiConfig: _apiConfig),
    );
  }
}
