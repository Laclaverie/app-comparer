import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:drift/drift.dart' show Value;

class DatabaseDebugPage extends StatefulWidget {
  final AppDatabase db;
  const DatabaseDebugPage({super.key, required this.db});

  @override
  State<DatabaseDebugPage> createState() => _DatabaseDebugPageState();
}

class _DatabaseDebugPageState extends State<DatabaseDebugPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _productsFuture = widget.db.select(widget.db.products).get();
    setState(() {});
  }

  Future<void> _deleteProduct(int id) async {
    await (widget.db.delete(widget.db.products)..where((tbl) => tbl.id.equals(id))).go();
    _refresh();
  }

  Future<void> _editProduct(Product product) async {
    final controller = TextEditingController(text: product.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product Name'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result != product.name) {
      await (widget.db.update(widget.db.products)..where((tbl) => tbl.id.equals(product.id)))
          .write(ProductsCompanion(name: Value(result)));
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Debug')),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!;
          if (products.isEmpty) return const Center(child: Text('No products found.'));
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, idx) {
              final product = products[idx];
              return ListTile(
                title: Text('${product.name} (ID: ${product.id})'),
                subtitle: Text('Barcode: ${product.barcode}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editProduct(product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteProduct(product.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}