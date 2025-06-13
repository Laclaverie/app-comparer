import 'package:flutter/material.dart';
import 'package:client_price_comparer/camera/barcode_scanner_widget.dart';
import 'package:client_price_comparer/services/server_service.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String? _barcode;
  bool _isServerAvailable = false;
  bool _isCheckingServer = false;
  String _serverStatus = 'Non testé';
  final ClientServerService _serverService = ClientServerService();

  void _onBarcodeScanned(String barcode) {
    setState(() {
      _barcode = barcode;
    });
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      _isCheckingServer = true;
      _serverStatus = 'Test en cours...';
    });

    try {
      final isAvailable = await _serverService.checkServerHealth();
      setState(() {
        _isServerAvailable = isAvailable;
        _serverStatus = isAvailable ? 'Serveur disponible ✅' : 'Serveur indisponible ❌';
        _isCheckingServer = false;
      });
    } catch (e) {
      setState(() {
        _isServerAvailable = false;
        _serverStatus = 'Erreur de connexion ❌';
        _isCheckingServer = false;
      });
    }
  }

  Future<void> _testGetProducts() async {
    final products = await _serverService.getProducts();
    if (products != null) {
      // Afficher un snackbar avec le nombre de produits
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${products['count']} produits trouvés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de récupération des produits'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Page'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          // 🌐 Panneau de test serveur
          _buildServerTestPanel(),
          
          const Divider(thickness: 2),
          
          // 📷 Scanner de codes-barres existant
          Expanded(
            child: BarcodeScannerWidget(
              onBarcodeScanned: _onBarcodeScanned,
            ),
          ),
          
          if (_barcode != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Last scanned barcode: $_barcode',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServerTestPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌐 Test de connexion serveur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Status du serveur
          Row(
            children: [
              const Text('Status: '),
              Text(
                _serverStatus,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isServerAvailable ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Boutons de test
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton.icon(
                onPressed: _isCheckingServer ? null : _checkServerConnection,
                icon: _isCheckingServer 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.health_and_safety),
                label: const Text('Heartbeat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: _isServerAvailable ? _testGetProducts : null,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Test Produits'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Bouton pour tester avec un code-barres
              if (_barcode != null)
                ElevatedButton.icon(
                  onPressed: _isServerAvailable ? () => _testProductByBarcode(_barcode!) : null,
                  icon: const Icon(Icons.search),
                  label: const Text('Test Barcode'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testProductByBarcode(String barcode) async {
    try {
      final response = await _serverService.getProductByBarcode(int.parse(barcode));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response != null 
                ? 'Produit trouvé: ${response['name']}' 
                : 'Produit non trouvé'),
            backgroundColor: response != null ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}