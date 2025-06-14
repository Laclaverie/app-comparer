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
  String _productsInfo = '';
  bool _showAdvancedMenu = false;  // ← Ajoutez cette ligne
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

  // ← Ajoutez cette méthode
  Future<void> _addScannedProductToTestDB() async {
    if (_barcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun code-barres scanné'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await _showAddProductDialog(_barcode!);
    
    if (result != null) {
      try {
        debugPrint('🚀 [DEBUG] Payload envoyé au serveur:');
        debugPrint('   - barcode: ${result['barcode']}');
        debugPrint('   - name: ${result['name']}');
        debugPrint('   - description: ${result['description']}');
        debugPrint('   - payload complet: $result');
        
        // ✅ Essayer d'abord d'ajouter
        bool success = await _serverService.addProductToTestDB(result);
        
        // ✅ Si échec à cause d'un doublon, proposer de mettre à jour
        if (!success) {
          final shouldUpdate = await _showUpdateConfirmDialog(result['name']);
          if (shouldUpdate == true) {
            success = await _serverService.updateProductInTestDB(result);
            
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Produit ${result['name']} mis à jour avec succès'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Produit ${result['name']} ajouté à la base de test'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erreur lors de l\'opération'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showAddProductDialog(String barcode) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête avec icône
              Row(
                children: [
                  const Icon(Icons.add_box, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ajouter produit', 
                          style: Theme.of(context).textTheme.titleLarge),
                        Text('Code: $barcode', 
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Champ nom avec validation visuelle
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  hintText: 'Ex: Coca-Cola 33cl',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
              ),
              const SizedBox(height: 16),
              
              // Champ description avec validation visuelle
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Ex: Boisson gazeuse rafraîchissante',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  helperText: '✨ Optionnel mais recommandé',
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 20),
              
              // Boutons avec icônes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final description = descriptionController.text.trim();
                      
                      if (name.isNotEmpty) {
                        final payload = {
                          'barcode': int.tryParse(barcode) ?? 0,
                          'name': name,
                          'description': description.isEmpty ? null : description,
                        };
                        
                        Navigator.of(context).pop(payload);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le nom du produit est obligatoire'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialogue de confirmation pour mise à jour
  Future<bool?> _showUpdateConfirmDialog(String productName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produit existant'),
        content: Text('Le produit "$productName" existe déjà. Voulez-vous le mettre à jour ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Page'),
        backgroundColor: Colors.orange,
        actions: [
          // ← Menu caché dans l'AppBar
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'advanced') {
                setState(() {
                  _showAdvancedMenu = !_showAdvancedMenu;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'advanced',
                child: Row(
                  children: [
                    Icon(Icons.settings_applications),
                    SizedBox(width: 8),
                    Text('Mode avancé'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de test serveur existant
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
                const SizedBox(height: 16),
                Text('Produits: $_productsInfo'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _testGetProducts,
                  child: const Text('Test GetProducts'),
                ),
              ],
            ),
          ),
          
          // ← Nouveau panel avancé (caché par défaut)
          if (_showAdvancedMenu) ...[
            const Divider(color: Colors.red, thickness: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade50,
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'MODE AVANCÉ - Base de test',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _barcode != null ? _addScannedProductToTestDB : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(_barcode != null 
                        ? 'Ajouter $_barcode à la DB test' 
                        : 'Scannez un produit d\'abord'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const Divider(),
          
          // Scanner existant
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