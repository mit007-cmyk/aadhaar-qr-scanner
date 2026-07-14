# Aadhaar QR Scanner (On-Device Offline)

A Flutter application designed to scan and decode both **Legacy (XML)** and **Modern (Secure Binary)** Aadhaar QR codes entirely on-device offline. No Python server or network requests are required to read, parse, and verify the biometric data.

---

## 📱 Features

- **On-Device Live Scanning**: Uses **Google ML Kit Barcode API** (`mobile_scanner`) to capture raw binary payloads directly from live camera frames.
- **Decompression & Parsing**: Pure Dart implementation (`lib/aadhaar_qr/`) to handle raw bytes decompression (Zlib/GZip) and binary segment parsing.
- **Native JPEG 2000 Decryption & Transcoding**: Seamlessly decodes heavily compressed biometric photos (`image/jp2`) using a native Kotlin/C++ MethodChannel bridge.
- **Clean Details Presentation**: Displays card-based details with dedicated verification badges (e-Signature status), and auto-fallbacks (`-`) for missing or null fields.
- **Console Log Output**: Outputs formatted, pretty-printed JSON logs in the debug terminal with truncated base64 image data to avoid cluttering.

---

## ⚙️ Architecture & Technical Flow

```
[Live Camera Frame]
       │ (Google ML Kit Native Thread)
       ▼
[Raw Byte Stream (Compressed Aadhaar Data)]
       │ (Dart zlib/gzip Decompressor)
       ▼
[Parsed Aadhaar Data Model] 
       │ (MIME Check: image/jp2)
       ▼ (MethodChannel: /jp2_decoder)
[Native Android OpenJPEG Engine (Kotlin/C++)] ──► Converts JP2 to PNG
       │
       ▼ (PNG Bytes)
[Flutter UI Widget (Image.memory)]
```

---

## 🛠️ Implementation Details

### 1. Offline Biometric JPEG 2000 Transcoding (Native Platform Bridge)
Flutter does not support rendering `.jp2` (JPEG 2000) formats natively. To solve this, the app uses a native Android dependency and a MethodChannel bridge:
- **Native Dependency**: Added `dev.keiji.jp2:jp2-android` to compile OpenJPEG libraries locally.
- **Native Controller ([MainActivity.kt](file:///d:/Projects/india-p2p/aadhaar_qr_scanner/android/app/src/main/kotlin/com/indiap2p/aadhaar_qr_scanner/MainActivity.kt))**: Hooks into the engine's initialization to catch decoding requests, transcode the image buffer to standard PNG bytes, and feed it back to Flutter.
- **Stateful UI Renderer ([qr_details_screen.dart](file:///d:/Projects/india-p2p/aadhaar_qr_scanner/lib/screens/qr_details_screen.dart))**: Resolves JP2 decoding asynchronously inside `initState()`, showing a progressive loader until the native C++ engine returns the renderable PNG format.

### 2. Output Formatting & Null Fallbacks
- For missing fields inside the QR payload (e.g. `id_number` or partial addresses), the app falls back to rendering a dash (`-`) in place of null values.
- If the scanned data contains quality warnings, an amber alert banner is placed at the top of the card.

### 3. Smart Developer Console Logs
- The app pretty-prints raw decoded results in a structured format in the console.
- Large base64 strings (`photo_base64` and `photo_preview_base64`) are automatically truncated inside logging maps and split into chunk-safe streams to prevent Android Logcat from clipping the outputs.

---

## 🚀 How to Run

Because this app utilizes native dependencies and MethodChannel configurations, you must run a full native rebuild rather than a Hot Reload.

```bash
# 1. Clear caches
flutter clean

# 2. Resolve dependencies
flutter pub get

# 3. Compile and Run on physical device
flutter run
```

---

## 📂 Key Source Files

- **Live Scanner UI**: [decode_screen.dart](file:///d:/Projects/india-p2p/aadhaar_qr_scanner/lib/screens/decode_screen.dart)
- **Detailed Viewer Screen**: [qr_details_screen.dart](file:///d:/Projects/india-p2p/aadhaar_qr_scanner/lib/screens/qr_details_screen.dart)
- **Aadhaar QR Parser**: [aadhaar_qr_decoder.dart](file:///d:/Projects/india-p2p/aadhaar_qr_scanner/lib/aadhaar_qr/aadhaar_qr_decoder.dart)
- **Native Transcoder Bridge**: [MainActivity.kt](file:///d:/Projects/india-p2p/aadhaar_qr_scanner/android/app/src/main/kotlin/com/indiap2p/aadhaar_qr_scanner/MainActivity.kt)
- **MethodChannel Service**: [jp2_decoder_service.dart](file:///d:/Projects/india-p2p/aadhaar_qr_scanner/lib/services/jp2_decoder_service.dart)
