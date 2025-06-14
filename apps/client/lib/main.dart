import 'package:flutter/material.dart';
import 'package:client_price_comparer/controllers/app_controller.dart';
import 'services/app_initialization.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🚀 [MAIN] Démarrage de l\'application...');

    // ✅ L'initialisation va automatiquement déclencher la migration si nécessaire
    await AppInitializationService.initialize();

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ [MAIN] Erreur fatale: $e');
    debugPrint('Stack trace: $stackTrace');

    // ✅ Interface d'erreur gracieuse
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Comparer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
  late final AppController _appController;

  @override
  void initState() {
    super.initState();
    _appController = AppController();
  }

  void _onItemTapped(int index) {
    if (_appController.isValidNavigationIndex(index)) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _appController.navigationService.getPages();
    final navItems = _appController.navigationService.getNavigationItems();

    return Scaffold(
      body: Center(
        child: pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _appController.dispose();
    AppInitializationService.cleanup();
    super.dispose();
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Erreur d\'initialisation')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Erreur lors de l\'initialisation:',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => main(), // Réessayer
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
