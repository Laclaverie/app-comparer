import 'dart:io';
import 'package:drift/drift.dart';
import '../data_database.dart';

class TestDataSeeder {
  final DataDatabase database;

  TestDataSeeder(this.database);

  Future<void> seedTestProducts() async {
    print('🌱 Génération des produits de test...');

    final testProducts = [
      ProductsCompanion(
        barcode: const Value(1234567890),
        name: const Value('Coca-Cola 33cl'),
        description: const Value('Boisson gazeuse'),
        imageFileName: const Value('coca_cola.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(2345678901),
        name: const Value('Pain de mie Harrys'),
        description: const Value('Pain de mie complet 500g'),
        imageFileName: const Value('pain_harrys.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(3456789012),
        name: const Value('Lait Lactel 1L'),
        description: const Value('Lait demi-écrémé UHT'),
        imageFileName: const Value('lait_lactel.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(4567890123),
        name: const Value('Bananes Bio 1kg'),
        description: const Value('Bananes biologiques'),
        imageFileName: const Value('bananes_bio.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(5678901234),
        name: const Value('Yaourt Danone x8'),
        description: const Value('Yaourts nature sucrés'),
        imageFileName: const Value('yaourt_danone.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(6789012345),
        name: const Value('Pâtes Barilla 500g'),
        description: const Value('Pâtes penne rigate'),
        imageFileName: const Value('pates_barilla.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(7890123456),
        name: const Value('Huile d\'olive Puget'),
        description: const Value('Huile d\'olive vierge extra 50cl'),
        imageFileName: const Value('huile_puget.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(8901234567),
        name: const Value('Riz Uncle Ben\'s 1kg'),
        description: const Value('Riz long grain étuvé'),
        imageFileName: const Value('riz_uncle_bens.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(9012345678),
        name: const Value('Fromage Emmental 200g'),
        description: const Value('Emmental français AOP'),
        imageFileName: const Value('emmental.jpg'),
      ),
      ProductsCompanion(
        barcode: const Value(1122334455),
        name: const Value('Chocolat Milka Oreo'),
        description: const Value('Chocolat au lait avec biscuits Oreo'),
        imageFileName: const Value('milka_oreo.jpg'),
      ),
    ];

    for (final product in testProducts) {
      try {
        // Vérifier si le produit existe déjà
        final existing = await database.getProductByBarcode(product.barcode.value);
        if (existing == null) {
          await database.insertProduct(product);
          print('✅ Produit ajouté: ${product.name.value}');
        } else {
          print('⚠️  Produit existe déjà: ${product.name.value}');
        }
      } catch (e) {
        print('❌ Erreur pour ${product.name.value}: $e');
      }
    }

    print('🎉 Génération terminée !');
  }

  Future<void> clearTestData() async {
    print('🧹 Suppression des données de test...');
    
    // Supprimer tous les produits
    await (database.delete(database.products)).go();
    
    print('✅ Données supprimées !');
  }

  Future<void> showStats() async {
    final count = await database.select(database.products).get().then((rows) => rows.length);
    print('📊 Nombre de produits en base: $count');
  }
}

// Script principal
void main(List<String> args) async {
  final database = DataDatabase.development(); // ← Base de dev persistante
  final seeder = TestDataSeeder(database);

  if (args.contains('--clear')) {
    await seeder.clearTestData();
  } else if (args.contains('--stats')) {
    await seeder.showStats();
  } else {
    await seeder.seedTestProducts();
    await seeder.showStats();
  }

  await database.close();
  exit(0);
}