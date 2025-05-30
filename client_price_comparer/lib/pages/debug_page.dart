import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String? _scannedBarcodeValue;
  final MobileScannerController _scannerController = MobileScannerController();
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
      // Do NOT call _scannerController.stop() here!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode detected: ${barcode.rawValue}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startScanAgain() async {
    await _scannerController.stop(); // Ensure the scanner is stopped
    setState(() {
      _scannedBarcodeValue = null;
      _isScannerActive = true;
    });
    // Add a short delay to allow the camera to reset
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Page - Barcode Scanner'),
        backgroundColor: Colors.orange,
        actions: [
          // No camera switch button
        ],
      ),
      body: Column(
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
                        if (_scannedBarcodeValue != null)
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
          if (!_isScannerActive && _scannedBarcodeValue != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'Using Code: $_scannedBarcodeValue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, _scannedBarcodeValue);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code: $_scannedBarcodeValue (No page to pop to)')),
                        );
                      }
                    },
                    child: const Text('Use This Code'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}