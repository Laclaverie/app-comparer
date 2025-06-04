import 'package:flutter/material.dart';
import 'package:client_price_comparer/database/app_database.dart';
import 'package:client_price_comparer/services/navigation_service.dart';

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
        useMaterial3: true,
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedIndex = 0;
  late final NavigationService _navigationService;
  static final AppDatabase _database = AppDatabase();

  @override
  void initState() {
    super.initState();
    _navigationService = NavigationService(_database);
  }

  void _onItemTapped(int index) {
    if (_navigationService.isValidIndex(index)) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _navigationService.getPages();
    final navItems = _navigationService.getNavigationItems();

    return Scaffold(
      body: Center(
        child: pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}
