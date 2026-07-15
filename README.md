# aadhaar_qr_scanner

[![Pub Version](https://img.shields.io/pub/v/aadhaar_qr_scanner.svg)](https://pub.dev/packages/aadhaar_qr_scanner)

A Flutter plugin for scanning and decoding **Legacy (XML)** and **Modern (Secure Binary)** Aadhaar QR codes entirely on-device. No backend API or Python server is required — QR detection uses Google ML Kit, payload parsing runs in pure Dart, and biometric photos are decoded natively on Android.

## Features

- Live Aadhaar QR scanning via Google ML Kit (`mobile_scanner`)
- On-device parsing of legacy XML and secure binary Aadhaar QR payloads
- Native JPEG 2000 (JP2) biometric photo decoding on Android
- Ready-made UI: `DecodeScreen`, `QrDetailsScreen`, and `QrScannerWidget`
- Centered scan-frame overlay with user guidance for accurate scanning

See the [example](example/README.md) app for a runnable demo.

## Platform Support

| Android | iOS | macOS | Web | Linux | Windows |
|---------|-----|-------|-----|-------|---------|
| ✔       | ✔*  | ✔*    | ✔*  | :x:   | :x:     |

\* Scanning and Dart-side QR parsing are available wherever `mobile_scanner` is supported. The native JP2 photo decoder plugin is **Android-only**.

### Features Supported

See the [example](example/) app for detailed implementation.

| Feature              | Android            | iOS                | macOS              | Web |
|----------------------|--------------------|--------------------|--------------------|-----|
| Live QR scanning     | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| XML QR parsing       | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| Secure binary parsing| :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| JP2 photo decoding   | :heavy_check_mark: | :x:                | :x:                | :x: |
| Built-in UI screens  | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |

## Installation

Add the dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  aadhaar_qr_scanner: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Configuration

### Android

Add the camera permission to your `AndroidManifest.xml` (located in `<project root>/android/app/src/main/AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

The JP2 decoder uses the bundled `jp2-android` native library and is registered automatically when you add this package as a dependency.

### iOS

Since the scanner needs camera access, add the following key to your `Info.plist` file (located in `<project root>/ios/Runner/Info.plist`):

`NSCameraUsageDescription` — describe why your app needs access to the camera. This is called **Privacy - Camera Usage Description** in the visual editor.

Example:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan Aadhaar QR codes</string>
```

### macOS

Ensure that you grant camera permission in Xcode → Signing & Capabilities.

## Usage

### Simple

Import the package with `package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart` and use the built-in scanner screen:

```dart
import 'package:flutter/material.dart';
import 'package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DecodeScreen(),
    );
  }
}
```

`DecodeScreen` opens the live camera scanner, decodes the Aadhaar QR on-device, and navigates to `QrDetailsScreen` with the parsed result.

### Advanced

#### Decode a raw QR payload

If you already have QR bytes from your own scanner, decode them directly:

```dart
import 'dart:typed_data';
import 'package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart';

final decoder = AadhaarQrLocalDecoder();

try {
  final data = decoder.decodePayload(rawBytes: Uint8List.fromList(qrBytes));
  print(data.name);
  print(data.dob);
  print(data.idNumber);
} on DecodeException catch (e) {
  print('Decode failed: $e');
}
```

#### Use the scanner widget in your own screen

For custom layouts, use `QrScannerWidget` with your own `MobileScannerController`:

```dart
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart';

final controller = MobileScannerController(
  detectionSpeed: DetectionSpeed.noDuplicates,
  formats: const [BarcodeFormat.qrCode],
);

QrScannerWidget(
  controller: controller,
  onDetect: (capture) {
    for (final barcode in capture.barcodes) {
      // Handle barcode.rawBytes / barcode.rawValue
    }
  },
);
```

#### Show decoded details

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => QrDetailsScreen(data: aadhaarData),
  ),
);
```

## Example

Run the bundled example app:

```bash
cd example
flutter pub get
flutter run
```

## Known Limitations

### JP2 biometric photos (Android only)

Aadhaar secure QR codes often store the holder's photo as **JPEG 2000 (`image/jp2`)**. Flutter cannot render JP2 natively, so this package provides an Android MethodChannel bridge (`Jp2DecoderService`) that transcodes JP2 to PNG.

On iOS, macOS, and Web, QR field parsing still works, but JP2 photos will not be displayed unless you provide your own decoding pipeline.

### `rawBytes` on iOS and macOS

Aadhaar secure QR payloads rely on raw binary data. On iOS and macOS, `mobile_scanner` may return `null` for `rawBytes` in certain encoding modes. This package also accepts `rawText` and attempts numeric-string fallback decoding when applicable.

For the most reliable results with secure binary Aadhaar QRs, use **Android**.

## Project Structure

```
aadhaar_qr_scanner/
├── lib/
│   ├── aadhaar_qr_scanner.dart    # Public API barrel export
│   └── src/                       # Private implementation
├── android/                       # Native JP2 decoder plugin
├── example/                       # Demo Flutter app
├── test/                          # Package unit tests
├── CHANGELOG.md
├── LICENSE
└── pubspec.yaml
```

## License

MIT — see [LICENSE](LICENSE).
