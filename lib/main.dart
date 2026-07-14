import 'package:flutter/material.dart';

import 'screens/decode_screen.dart';

void main() {
  runApp(const AadhaarQrScannerApp());
}

class AadhaarQrScannerApp extends StatelessWidget {
  const AadhaarQrScannerApp({super.key});

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
