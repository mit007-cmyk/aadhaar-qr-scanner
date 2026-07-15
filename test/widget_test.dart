import 'package:aadhaar_qr_scanner/aadhaar_qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Decode screen loads with scanner guidance', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DecodeScreen(),
      ),
    );
    expect(find.text('Aadhaar QR Scanner'), findsOneWidget);
    expect(
      find.text('Please position the QR code in the center of the square for accurate scanning.'),
      findsOneWidget,
    );
  });
}
