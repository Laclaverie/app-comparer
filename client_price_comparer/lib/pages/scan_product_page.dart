import 'package:flutter/material.dart';
import 'package:client_price_comparer/camera/barcode_scanner_widget.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/services/product_service.dart';

class ScanProductPage extends StatefulWidget {
  final AppDatabase db;
  
  const ScanProductPage({super.key, required this.db});

  @override
  State<ScanProductPage> createState() => _ScanProductPageState();
}

class _ScanProductPageState extends State<ScanProductPage> {
  late final ProductService _productService;
  String? _scannedBarcode;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _productService = ProductService(widget.db);
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
    // TODO: Navigate to product details page (Step 2)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Found!'),
        content: Text('Product: ${product.name}\nBarcode: ${product.barcode}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  Future<void> _handleRegisterProduct(String barcode) async {
    await _productService.startProductRegistration(barcode);
    // TODO: Navigate to registration form
    _showSuccessMessage('Starting product registration...');
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
              child: BarcodeScannerWidget(
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