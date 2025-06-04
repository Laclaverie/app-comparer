import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:client_price_comparer/pages/home_page.dart'; // Import MyHomePage
import 'package:client_price_comparer/pages/debug/debug_page.dart'; // Import DebugPage
import 'package:client_price_comparer/pages/debug/debug_database.dart'; // Import DebugDatabasePage
// lib
import 'package:client_price_comparer/database/app_database.dart'; // Import AppDatabase

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // It's good practice to enable Material 3
      ),
      home: const RootPage(), // Set RootPage as the home
    );
  }
}

// RootPage Widget to handle BottomNavigationBar
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedIndex = 0;

  // Define the base list of pages for release mode
  static const List<Widget> _widgetOptionsBase = <Widget>[
    MyHomePage(title: 'Flutter Demo Home Page'), // Use imported MyHomePage
  ];

  // Define the list of pages for debug mode, including the DebugPage
  static final List<Widget> _widgetOptionsDebug = <Widget>[
    ..._widgetOptionsBase,
    const DebugPage(), // Use imported DebugPage
    DatabaseDebugPage(db: AppDatabase()), // Use imported DatabaseDebugPage
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which set of pages to use based on the build mode
    final List<Widget> pages = kReleaseMode ? _widgetOptionsBase : _widgetOptionsDebug;

    // Define the BottomNavigationBar items
    final List<BottomNavigationBarItem> navBarItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      if (!kReleaseMode) // Conditionally add the debug tab
        const BottomNavigationBarItem(
          icon: Icon(Icons.bug_report),
          label: 'Debug',
        ),
      if (!kReleaseMode) // Conditionally add the database debug tab
      const BottomNavigationBarItem(
        icon: Icon(Icons.storage),
        label: 'Database Debug',
      ),
    ];

    return Scaffold(
      body: Center(
        child: pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
