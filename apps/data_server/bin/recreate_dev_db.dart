import 'dart:io';
import '../lib/data_database.dart';

Future<void> main() async {
  print('🚀 Recreating development database...');
  
  // Supprimer l'ancienne base
  final dbFile = File('dev_database.db');
  if (await dbFile.exists()) {
    await dbFile.delete();
    print('🗑️ Deleted old dev_database.db');
  }
  
  // Créer la nouvelle base avec le bon schéma
  final database = DataDatabase.development();
  
  try {
    // Tester la connexion - ça va créer toutes les tables
    final count = await database.customSelect('SELECT COUNT(*) as count FROM products').getSingle();
    print('✅ New database created with ${count.data['count']} products');
    
    print('🔍 New table schema:');
    final schema = await database.customSelect('PRAGMA table_info(products)').get();
    for (final row in schema) {
      print('  - ${row.data['name']} (${row.data['type']})');
    }
    
  } finally {
    await database.close();
  }
  
  print('✅ Development database recreated successfully!');
}