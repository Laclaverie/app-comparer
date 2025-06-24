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

  Future<void> seedTestStores() async {
    print('🏪 Génération des magasins de test...');

    final testStores = [
      SupermarketsCompanion(
        name: const Value('Carrefour'),
        address: const Value('123 Rue de la République'),
        city: const Value('Centre Commercial'),
      ),
      SupermarketsCompanion(
        name: const Value('Leclerc'),
        address: const Value('456 Avenue des Champs'),
        city: const Value('Zone Commerciale Nord'),
      ),
      SupermarketsCompanion(
        name: const Value('Monoprix'),
        address: const Value('789 Place du Marché'),
        city: const Value('Centre Ville'),
      ),
      SupermarketsCompanion(
        name: const Value('Super U'),
        address: const Value('321 Boulevard de la Gare'),
        city: const Value('Quartier Sud'),
      ),
      SupermarketsCompanion(
        name: const Value('IGA'),
        address: const Value('654 Rue des Entreprises'),
        city: const Value('Zone Industrielle'),
      ),
    ];

    for (final store in testStores) {
      try {
        await database.into(database.supermarkets).insert(store);
        print('✅ Magasin ajouté: ${store.name.value} - ${store.address.value}, ${store.city.value}');
      } catch (e) {
        print('⚠️  Magasin existe déjà: ${store.name.value}');
      }
    }
  }

  Future<void> seedTestPrices() async {
    print('💰 Génération des prix de test...');

    // Récupérer les produits et magasins existants
    final products = await database.select(database.products).get();
    final stores = await database.select(database.supermarkets).get();

    if (products.isEmpty || stores.isEmpty) {
      print('❌ Pas de produits ou magasins trouvés. Générez-les d\'abord.');
      return;
    }

    // Générer des prix pour les 3 premiers produits dans tous les magasins
    for (int i = 0; i < 3 && i < products.length; i++) {
      final product = products[i];
      final basePrice = 2.0 + (i * 0.5); // Prix de base variable

      for (final store in stores) {
        // Variation de prix par magasin (-20% à +30%)
        final variation = (store.id % 5 - 2) * 0.1; // -0.2 à +0.3
        final price = basePrice + (basePrice * variation);

        final priceEntry = PriceHistoryCompanion(
          productId: Value(product.id),
          supermarketId: Value(store.id),
          price: Value(price),
          date: Value(DateTime.now()),
        );

        try {
          await database.into(database.priceHistory).insert(priceEntry);
          print('✅ Prix ajouté: ${product.name} chez ${store.name} = €${price.toStringAsFixed(2)}');
        } catch (e) {
          print('⚠️  Prix existe déjà pour ${product.name} chez ${store.name}');
        }
      }
    }
  }

  Future<void> seedRealProductPrices() async {
    print('💰 Ajout de prix pour les produits scannés...');

    // ✅ D'abord lister tous les produits pour voir ce qu'on a
    print('🔍 Produits disponibles:');
    final allProducts = await database.select(database.products).get();
    for (final product in allProducts) {
      print('   - ${product.name} (barcode: ${product.barcode})');
    }

    // ✅ Chercher le produit par nom plutôt que par barcode
    final chipsProduct = await (database.select(database.products)
        ..where((p) => p.name.like('%chips%') | 
                      p.name.like('%Chips%') |
                      p.description.like('%chips%')))
        .getSingleOrNull();

    if (chipsProduct == null) {
      print('❌ Aucun produit chips trouvé. Ajoutez-le d\'abord depuis votre app !');
      return;
    }

    // Récupérer tous les magasins
    final stores = await database.select(database.supermarkets).get();
    
    if (stores.isEmpty) {
      print('❌ Aucun magasin trouvé. Générez les magasins d\'abord !');
      return;
    }

    print('🍟 Génération des prix pour: ${chipsProduct.name}');

    // Prix réalistes pour un paquet de chips (base: €2.50)
    final basePriceChips = 2.50;
    
    final storeVariations = {
      'Carrefour': -0.30,    // €2.20 - moins cher
      'Leclerc': -0.10,      // €2.40 - légèrement moins cher
      'Monoprix': 0.40,      // €2.90 - plus cher (centre ville)
      'Super U': -0.20,      // €2.30 - competitive
      'IGA': 0.15,           // €2.65 - légèrement plus cher
    };

    for (final store in stores) {
      final variation = storeVariations[store.name] ?? 0.0;
      final finalPrice = basePriceChips + variation;
      
      // Ajouter un peu de randomness pour simuler des promos
      final random = (DateTime.now().millisecond % 100) / 1000;
      final adjustedPrice = finalPrice + (random - 0.05);
      
      final priceEntry = PriceHistoryCompanion(
        productId: Value(chipsProduct.id),
        supermarketId: Value(store.id),
        price: Value(double.parse(adjustedPrice.toStringAsFixed(2))),
        date: Value(DateTime.now().subtract(  // ✅ dateRecorded pas date
          Duration(hours: store.id % 24)
        )),
      );

      try {
        await database.into(database.priceHistory).insert(priceEntry);
        print('✅ Prix ajouté: ${chipsProduct.name} chez ${store.name} = €${adjustedPrice.toStringAsFixed(2)}');
      } catch (e) {
        // Mettre à jour si existe déjà
        await (database.update(database.priceHistory)
          ..where((p) => p.productId.equals(chipsProduct.id) & 
                        p.supermarketId.equals(store.id)))
          .write(PriceHistoryCompanion(
            price: Value(adjustedPrice),
            date: Value(DateTime.now()),  // ✅ dateRecorded pas date
          ));
        print('🔄 Prix mis à jour: ${chipsProduct.name} chez ${store.name} = €${adjustedPrice.toStringAsFixed(2)}');
      }
    }
  }

  Future<void> seedPriceHistory() async {
    print('📈 Génération de l\'historique des prix...');

    // Récupérer tous les produits qui ont déjà des prix
    final productsWithPrices = await database
        .select(database.priceHistory)
        .join([innerJoin(database.products, 
            database.products.id.equalsExp(database.priceHistory.productId))])
        .get();

    if (productsWithPrices.isEmpty) {
      print('❌ Aucun prix existant. Générez d\'abord les prix actuels !');
      return;
    }

    // Grouper par produit
    final productIds = productsWithPrices
        .map((row) => row.readTable(database.priceHistory).productId)
        .toSet();

    for (final productId in productIds) {
      await _generatePriceHistoryForProduct(productId);
    }

    print('✅ Historique des prix généré pour ${productIds.length} produits');
  }

  Future<void> _generatePriceHistoryForProduct(int productId) async {
    // Récupérer les prix actuels pour ce produit
    final currentPrices = await (database.select(database.priceHistory)
        ..where((p) => p.productId.equals(productId))).get();

    // Récupérer le nom du produit pour les logs
    final product = await (database.select(database.products)
        ..where((p) => p.id.equals(productId))).getSingle();

    print('📊 Génération historique pour: ${product.name}');

    // ✅ Générer 1 prix par jour pour chaque magasin sur 30 jours
    for (int daysAgo = 30; daysAgo > 0; daysAgo--) {
      final date = DateTime.now().subtract(Duration(days: daysAgo));
      
      for (final currentPrice in currentPrices) {
        // ✅ Vérifier qu'on n'a pas déjà un prix pour ce jour
        final existingPrice = await (database.select(database.priceHistory)
            ..where((p) => p.productId.equals(productId) & 
                          p.supermarketId.equals(currentPrice.supermarketId) &
                          p.date.isBiggerOrEqualValue(DateTime(date.year, date.month, date.day)) &
                          p.date.isSmallerThanValue(DateTime(date.year, date.month, date.day + 1))))
            .getSingleOrNull();
        
        if (existingPrice != null) {
          continue; // Skip si on a déjà un prix pour ce jour
        }
        
        // Créer des variations réalistes
        final basePrice = currentPrice.price;
        
        // Tendance générale : légère augmentation sur 30 jours
        final trendFactor = 1.0 + (daysAgo * 0.001); // +0.1% par jour plus ancien
        
        // Variations aléatoires par magasin
        final random = (date.day + currentPrice.supermarketId) % 100;
        final randomFactor = 0.95 + (random / 100 * 0.1); // ±5%
        
        // Simuler des promotions occasionnelles
        final isPromotion = (date.day + currentPrice.supermarketId) % 7 == 0;
        final promoFactor = isPromotion ? 0.85 : 1.0; // -15% en promo
        
        final historicalPrice = basePrice * trendFactor * randomFactor * promoFactor;
        
        // ✅ Définir une heure fixe dans la journée (14h00)
        final exactDate = DateTime(date.year, date.month, date.day, 14, 0, 0);
        
        final historyEntry = PriceHistoryCompanion(
          productId: Value(productId),
          supermarketId: Value(currentPrice.supermarketId),
          price: Value(double.parse(historicalPrice.toStringAsFixed(2))),
          date: Value(exactDate), // ✅ Heure fixe dans la journée
          isPromotion: Value(isPromotion),
          promotionDescription: isPromotion ? 
              const Value('Promotion hebdomadaire') : 
              const Value.absent(),
        );

        try {
          await database.into(database.priceHistory).insert(historyEntry);
        } catch (e) {
          // Ignorer les doublons
        }
      }
    }
  }

  // Modifiez la méthode principale
  Future<void> seedAllData() async {
    await seedTestProducts(); // Produits existants
    await seedTestStores();         // Nouveaux magasins
    await seedTestPrices();         // Nouveaux prix
    
    print('🎉 Génération complète terminée !');
  }

  // Nouvelle méthode pour générer tout
  Future<void> seedAllTestDataWithRealProducts() async {
    await seedTestProducts();     // 10 produits de base
    await seedTestStores();       // 5 magasins
    await seedTestPrices();       // Prix pour les 3 premiers produits de base
    await seedRealProductPrices(); // Prix pour vos produits scannés
    
    print('🎉 Génération complète terminée !');
  }

  // Nouvelle méthode pour générer tout avec historique
  Future<void> seedAllTestDataWithHistory() async {
    await seedTestProducts();       // 10 produits de base
    await seedTestStores();         // 5 magasins
    await seedTestPrices();         // Prix actuels pour 3 produits
    await seedRealProductPrices();  // Prix pour produits scannés
    await seedPriceHistory();       // ← Nouveau : historique sur 30 jours
    
    print('🎉 Génération complète avec historique terminée !');
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
  } else if (args.contains('--history')) {
    await seeder.seedPriceHistory(); // Seulement l'historique
  } else if (args.contains('--real-prices')) {
    await seeder.seedRealProductPrices(); // Seulement les prix des produits scannés
  } else {
    await seeder.seedAllTestDataWithHistory(); // Tout avec historique
    await seeder.showStats();
  }

  await database.close();
  exit(0);
}