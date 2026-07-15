import 'package:flutter/material.dart';
import 'package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart';

void main() {
  runApp(const AadhaarQrScannerExampleApp());
}

class AadhaarQrScannerExampleApp extends StatelessWidget {
  const AadhaarQrScannerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aadhaar QR Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DecodeScreen(),
    );
  }
}
