import 'package:flutter_test/flutter_test.dart';

import 'package:aadhaar_qr_scanner/main.dart';

void main() {
  testWidgets('App loads decode screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AadhaarQrScannerApp());
    expect(find.text('Aadhaar QR Scanner'), findsOneWidget);
    expect(
      find.text('Please position the QR code in the center of the square for accurate scanning. sure to place the QR in the center of the square.'),
      findsOneWidget,
    );
  });
}
