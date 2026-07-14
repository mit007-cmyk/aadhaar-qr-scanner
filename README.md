# Aadhaar QR Scanner (on-device)

Flutter app that decodes Aadhaar QR **on the phone** — no Python API required.

## QR scanning

Uses **Google ML Kit** via `mobile_scanner` (not `flutter_zxing`) to read QR bytes from camera/gallery.
The Aadhaar field parsing logic is ported to Dart under `lib/aadhaar_qr/`.

## Can I put Python (`qr_decode.py`) inside Flutter?

**No — not in a simple way.** Flutter runs Dart; Android/iOS do not ship a Python interpreter.

| Approach | Works on phone? | Notes |
|----------|-----------------|-------|
| Drop `qr_decode.py` in Flutter project | ❌ | Dart cannot execute `.py` files |
| Chaquopy (embed Python on Android) | ⚠️ Android only | Large APK, complex, still no iOS |
| Call Python API over network | ✅ | What the HTML demo does |
| Port parser to Dart (this app) | ✅ | Already done in `lib/aadhaar_qr/` |
| ML Kit for QR + Dart parser | ✅ | **Current approach** |

The Python **payload parser** (~500 lines) is already in Dart. Only the heavy OpenCV/YOLO **image pipeline** from `qr_decode.py` was replaced by ML Kit.

| Python (server) | Dart (Flutter) | Notes |
|-----------------|----------------|-------|
| `decode_aadhaar_qr_payload()` | `lib/aadhaar_qr/aadhaar_qr_decoder.dart` | Main entry |
| `_parse_qr_bytes()` | same file | zlib/gzip + format dispatch |
| `_parse_secure_qr_payload()` | `secure_qr_parser.dart` | Secure binary Aadhaar QR |
| XML attribute parsing | `xml_qr_parser.dart` | Legacy XML QR |
| Photo extraction helpers | `aadhaar_qr_utils.dart` | Base64 photo fields |
| `decode_aadhaar_qr()` image pipeline | **Not ported** | Uses `flutter_zxing` + `mobile_scanner` instead |
| MongoDB auth | **Removed** | Not needed offline |
| UIDAI RSA `e_signed` verify | **Not ported yet** | Fields decode; `e_signed` stays false |

**~500 lines of Dart** replace the payload parsing portion of `qr_decode.py`. The heavy OpenCV/YOLO image pipeline stays replaced by native QR scanners.

## Run

```bash
cd aadhaar_qr_scanner
flutter pub get
flutter run
```

## Usage

1. **Scan Live** — point camera at Aadhaar QR
2. **Gallery** — pick a cropped QR image, then **Decode Selected Image**

No API URL or API key needed.

## Tests

```bash
flutter test
```

## Limitations vs Python API

- Blurry/damaged QR images may fail where the Python server’s exhaustive OpenCV pipeline succeeds
- `e_signed` cryptographic verification is not implemented on-device yet
- Secure QR returns `reference_id`, not full Aadhaar number (same as Python)
