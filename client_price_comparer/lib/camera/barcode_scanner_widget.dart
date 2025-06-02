import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final void Function(String barcode)? onBarcodeScanned;

  const BarcodeScannerWidget({super.key, this.onBarcodeScanned});

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  String? _scannedBarcodeValue;
  final MobileScannerController _scannerController = MobileScannerController(
    cameraResolution: const Size(1920, 1080),
  );
  bool _isScannerActive = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }


  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (!_isScannerActive || capture.barcodes.isEmpty) return;
    final Barcode barcode = capture.barcodes.first;
    if (barcode.rawValue != null && barcode.rawValue != _scannedBarcodeValue) {
      setState(() {
        _scannedBarcodeValue = barcode.rawValue;
        _isScannerActive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode detected: ${barcode.rawValue}'),
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onBarcodeScanned?.call(barcode.rawValue!);
    }
  }

  void _startScanAgain() async {
    await _scannerController.stop();
    setState(() {
      _scannedBarcodeValue = null;
      _isScannerActive = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    Widget scannerWidget = MobileScanner(
      controller: _scannerController,
      onDetect: _handleBarcodeDetection,
      errorBuilder: (context, error) {
        String errorMessage = error.errorCode.toString();
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Camera Error: $errorMessage\nPlease ensure camera permissions are granted.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        );
      },
    );

    return Column(
      children: [
        Expanded(
          flex: _isScannerActive ? 5 : 3,
          child: _isScannerActive
              ? scannerWidget
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Scan Complete!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      if (_scannedBarcodeValue != null && kDebugMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                          child: Text(
                            'Scanned Value: $_scannedBarcodeValue',
                            style: const TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                        onPressed: _startScanAgain,
                      ),
                    ],
                  ),
                ),
        ),
        if (_isScannerActive)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Point the camera at a barcode to scan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
      ],
    );
  }

  @visibleForTesting
  void handleBarcodeDetectionForTest(dynamic capture) 
  {
    _handleBarcodeDetection(capture as BarcodeCapture);
  }
}