import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_price_comparer/camera/barcode_scanner_widget.dart';

void main() {
  testWidgets('BarcodeScannerWidget calls onBarcodeScanned', (WidgetTester tester) async {
    String? scannedBarcode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BarcodeScannerWidget(
            onBarcodeScanned: (barcode) {
              scannedBarcode = barcode;
            },
          ),
        ),
      ),
    );

    // Simulate a scan by calling the callback directly
    (tester.firstWidget(find.byType(BarcodeScannerWidget)) as BarcodeScannerWidget)
        .onBarcodeScanned?.call('1234567890');
    expect(scannedBarcode, '1234567890');
  });
}

// You need to create a fake BarcodeCapture for testing
class FakeBarcodeCapture {
  final List<FakeBarcode> barcodes;
  FakeBarcodeCapture(String value) : barcodes = [FakeBarcode(value)];
}

class FakeBarcode {
  final String? rawValue;
  FakeBarcode(this.rawValue);
}