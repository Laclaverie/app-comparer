import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/services/navigation_service.dart';

class AppController {
  late final AppDatabase database;
  late final NavigationService navigationService;

  AppController() {
    _initialize();
  }

  void _initialize() {
    database = AppDatabase();
    navigationService = NavigationService(database);
  }

  /// Clean up resources when the app is disposed
  void dispose() {
    database.close();
  }

  /// Check if a navigation index is valid
  bool isValidNavigationIndex(int index) {
    return navigationService.isValidIndex(index);
  }

  /// Get the maximum navigation index
  int getMaxNavigationIndex() {
    return navigationService.getMaxIndex();
  }
}