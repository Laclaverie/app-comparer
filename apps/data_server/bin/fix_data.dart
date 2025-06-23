import '../lib/data_database.dart';

Future<void> main() async {
  print('🚀 Starting data fix...');
  
  final database = DataDatabase.development();
  
  try {
    await database.fixProductsData();
    print('✅ Data fix completed successfully!');
  } catch (e) {
    print('❌ Data fix failed: $e');
  } finally {
    await database.close();
  }
}