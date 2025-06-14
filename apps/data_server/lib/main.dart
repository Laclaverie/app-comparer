import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

import 'package:data_server/data_database.dart';
import 'package:data_server/services/product_service.dart';
import 'package:data_server/services/image_service.dart';
import 'package:data_server/handlers/product_handlers.dart';
import 'package:data_server/handlers/image_handlers.dart';
import 'package:data_server/helpers/routes.dart';  // ← Import du helper

void main() async {
  // Initialiser les services
  final database = DataDatabase.development();
  final imageService = ImageService();
  final productService = ProductService(database, imageService);
  
  // Initialiser les handlers
  final productHandlers = ProductHandlers(productService, imageService);
  final imageHandlers = ImageHandlers(imageService);

  // Créer le router avec logging automatique
  final routerWrapper = createRouterWithLogging(productHandlers, imageHandlers);

  // Middleware
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(routerWrapper.router);
      
  // Récupérer la vraie IP de la machine
  final interfaces = await NetworkInterface.list();
  final wifiInterface = interfaces
      .where((interface) => interface.name.contains('Wi-Fi') || interface.name.contains('wlan'))
      .expand((interface) => interface.addresses)
      .where((address) => address.type == InternetAddressType.IPv4)
      .firstOrNull;
      
  // Serveur
  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  
  // Affichage des informations du serveur
  print('🚀 Data Server running on:');
  print('   Local:    http://localhost:${server.port}');
  if (wifiInterface != null) {
    print('   Network:  http://${wifiInterface.address}:${server.port}');
  }
  print('   All IPs:  http://0.0.0.0:${server.port}');
  
  // Affichage automatique et groupé des routes
  printRoutes(routerWrapper.routes, wifiInterface?.address.toString() ?? '192.168.18.5', server.port);
}
