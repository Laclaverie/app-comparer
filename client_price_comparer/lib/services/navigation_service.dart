import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:client_price_comparer/pages/home_page.dart';
import 'package:client_price_comparer/pages/debug/debug_page.dart';
import 'package:client_price_comparer/pages/debug/debug_database.dart';
import 'package:client_price_comparer/pages/scan_product_page.dart';
import 'package:client_price_comparer/database/app_database.dart';

class NavigationService {
  final AppDatabase _database;

  NavigationService(this._database);

  /// Get the list of pages based on the current build mode
  List<Widget> getPages() {
    return kReleaseMode ? _getReleasePages() : _getDebugPages();
  }

  /// Get the navigation bar items based on the current build mode
  List<BottomNavigationBarItem> getNavigationItems() {
    return kReleaseMode ? _getReleaseNavItems() : _getDebugNavItems();
  }

  /// Check if the given index is valid for the current mode
  bool isValidIndex(int index) {
    return index >= 0 && index < getPages().length;
  }

  /// Get the maximum index for the current mode
  int getMaxIndex() {
    return getPages().length - 1;
  }

  // Private helper methods
  List<Widget> _getReleasePages() {
    return [
      const MyHomePage(title: 'Flutter Demo Home Page'),
      ScanProductPage(db: _database),
    ];
  }

  List<Widget> _getDebugPages() {
    return [
      ..._getReleasePages(),
      const DebugPage(),
      DatabaseDebugPage(db: _database),
    ];
  }

  List<BottomNavigationBarItem> _getReleaseNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.qr_code_scanner),
        label: 'Scan',
      ),
    ];
  }

  List<BottomNavigationBarItem> _getDebugNavItems() {
    return [
      ..._getReleaseNavItems(),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bug_report),
        label: 'Debug',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.storage),
        label: 'Database Debug',
      ),
    ];
  }
}