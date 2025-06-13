import 'package:flutter/material.dart';
import 'package:client_price_comparer/camera/barcode_scanner_widget.dart';
import 'package:client_price_comparer/services/client_server_service.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  String? _barcode;
  String _serverStatus = 'Non testé';
  String _productsInfo = '';  // ← Ajoutez cette ligne
  final ClientServerService _serverService = ClientServerService();

  void _onBarcodeScanned(String barcode) {
    setState(() {
      _barcode = barcode;
    });
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      _serverStatus = 'Test en cours...';
    });

    try {
      final isAvailable = await _serverService.checkServerHealth();
      setState(() {
        _serverStatus = isAvailable ? 'Serveur disponible ✅' : 'Serveur indisponible ❌';
      });
    } catch (e) {
      setState(() {
        _serverStatus = 'Erreur de connexion ❌';
      });
    }
  }

  // ← Ajoutez cette méthode
  Future<void> _testGetProducts() async {
    setState(() {
      _productsInfo = 'Chargement...';
    });

    try {
      final result = await _serverService.getProducts();
      if (result != null) {
        setState(() {
          _productsInfo = '✅ ${result.length} produits trouvés';
        });
      } else {
        setState(() {
          _productsInfo = '❌ Erreur de récupération';
        });
      }
    } catch (e) {
      setState(() {
        _productsInfo = '❌ Erreur: $e';
      });
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
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Status serveur: $_serverStatus'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _checkServerConnection,
                  child: const Text('Test Heartbeat'),
                ),
                
                const SizedBox(height: 16),  // ← Ajoutez ces lignes
                Text('Produits: $_productsInfo'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _testGetProducts,
                  child: const Text('Test GetProducts'),
                ),
              ],
            ),
          ),
          
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
}