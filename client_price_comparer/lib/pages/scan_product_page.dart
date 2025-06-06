import 'package:client_price_comparer/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:client_price_comparer/camera/barcode_scanner_widget.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/services/product_service.dart';
import 'package:client_price_comparer/pages/product_details_page.dart';

class ScanProductPage extends StatefulWidget {
  final AppDatabase db;
  
  const ScanProductPage({super.key, required this.db});

  @override
  State<ScanProductPage> createState() => _ScanProductPageState();
}

class _ScanProductPageState extends State<ScanProductPage> with WidgetsBindingObserver {
  late final ProductService _productService;
  String? _scannedBarcode;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _productService = ProductService(widget.db);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose camera when leaving scan page completely
    CameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for camera
    if (state == AppLifecycleState.resumed && _isScanning) {
      // Reinitialize camera when app resumes
      _reinitializeCamera();
    } else if (state == AppLifecycleState.paused) {
      // Camera automatically pauses
    }
  }

  Future<void> _reinitializeCamera() async {
    // Force camera reinitialization
    await CameraService.dispose();
    setState(() {
      // Trigger camera widget rebuild
    });
  }

  void _onBarcodeScanned(String barcode) {
    setState(() {
      _scannedBarcode = barcode;
      _isScanning = false;
    });
    
    _handleBarcodeScanned(barcode);
  }

  Future<void> _handleBarcodeScanned(String barcode) async {
    final response = await _productService.searchProductByBarcode(barcode);
    
    switch (response.result) {
      case ProductSearchResult.found:
        _showProductFound(response.product!);
        break;
      case ProductSearchResult.notFound:
        _showProductNotFound(barcode);
        break;
      case ProductSearchResult.invalidBarcode:
        _showError(response.errorMessage!);
        break;
    }
  }

  void _showProductFound(Product product) {
    // Navigate to product details page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          product: product,
          database: widget.db,
          fromNotification: false,
        ),
      ),
    ).then((_) {
      // When user comes back from product details, reset scanner
      _resetScanner();
    });
  }

  void _showProductNotFound(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('Barcode: $barcode\n\nWould you like to register this new product?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSearchOnline(barcode);
            },
            child: const Text('No, search online'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleRegisterProduct(barcode);
            },
            child: const Text('Yes, register now'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearchOnline(String barcode) async {
    await _productService.addToPrioritySearchQueue(barcode);
    _showSuccessMessage('Added to search queue. You\'ll be notified when found!');
  }

  void _handleRegisterProduct(String barcode) async {
    final bool? registered = await _productService.navigateToProductRegistration(context, barcode);
    
    if (registered == true) {
      // Product was successfully registered
      _showSuccessMessage('Product registered successfully!');
      _resetScanner(); // This will reinitialize the camera
    } else {
      // User cancelled or registration failed
      _resetScanner(); // Still reset to get back to scanning
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _resetScanner();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _scannedBarcode = null;
      _isScanning = true;
    });
    // Reinitialize camera when resetting scanner
    _reinitializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product'),
        actions: [
          if (_scannedBarcode != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScanner,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isScanning)
            Expanded(
              // Use a key to force widget rebuild when camera needs reinitialization
              child: BarcodeScannerWidget(
                key: ValueKey(_scannedBarcode ?? 'scanning'), // Add this key
                onBarcodeScanned: _onBarcodeScanned,
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Scanned: $_scannedBarcode',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text('Searching in database...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}