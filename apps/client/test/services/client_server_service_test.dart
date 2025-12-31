import 'package:flutter_test/flutter_test.dart';
import 'package:client_price_comparer/services/client_server_service.dart';
import 'package:client_price_comparer/services/config_service.dart';

void main() {
  group('ClientServerService baseUrl resolution', () {
    test('uses injected ConfigService if provided', () {
      final cfg = ConfigService(defaultIp: '9.9.9.9', defaultPort: 9009);
      final svc = ClientServerService(configService: cfg);
      expect(svc.testableBaseUrl, 'http://9.9.9.9:9009');
    });

    test('falls back to default when no config provided', () {
      final svc = ClientServerService();
      expect(svc.testableBaseUrl.startsWith('http://'), true);
    });
  });
}
