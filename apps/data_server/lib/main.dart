import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main(List<String> args) async {
  final router = Router()
    ..get('/', _rootHandler)
    ..get('/health', _healthHandler)
    ..get('/api/products', _getProductsHandler)
    ..post('/api/products', _createProductHandler);

  final handler = Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router);

  final ip = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  
  print('🚀 Data Server running on port ${server.port}');
}

Response _rootHandler(Request req) {
  return Response.ok('Data Server API v1.0');
}

Response _healthHandler(Request req) {
  return Response.ok('OK');
}

Response _getProductsHandler(Request req) {
  return Response.ok('{"products": []}');
}

Response _createProductHandler(Request req) {
  return Response.ok('{"status": "created"}');
}