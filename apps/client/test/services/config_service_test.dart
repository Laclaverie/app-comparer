import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;
import 'package:client_price_comparer/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default values and baseUrl', () async {
      final cfg = ConfigService(defaultIp: '10.0.0.1', defaultPort: 1234);
      await cfg.init();
      expect(cfg.ip, '10.0.0.1');
      expect(cfg.port, 1234);
      expect(cfg.baseUrl, 'http://10.0.0.1:1234');
    });

    test('setIpPort persists and read back', () async {
      final cfg = ConfigService();
      await cfg.init();
      await cfg.setIpPort('8.8.8.8', 8088);
      expect(cfg.ip, '8.8.8.8');
      expect(cfg.port, 8088);
      expect(cfg.baseUrl, 'http://8.8.8.8:8088');

      // New instance should pick up persisted values after init
      final cfg2 = ConfigService();
      await cfg2.init();
      expect(cfg2.ip, '8.8.8.8');
      expect(cfg2.port, 8088);
    });

    test('clearOverride removes persisted values', () async {
      final cfg = ConfigService();
      await cfg.init();
      await cfg.setIpPort('1.2.3.4', 9000);
      await cfg.clearOverride();
      expect(cfg.ip, 'localhost'); // default now
      expect(cfg.port, 8080);
    });

    test('reads .env values when present', () async {
      // Provide envOverride to init
      const testIp = '10.10.10.10';
      const testPort = '9090';

      final cfg = ConfigService();
      await cfg.init(envOverride: {'SERVER_IP': testIp, 'SERVER_PORT': testPort});
      expect(cfg.ip, testIp);
      expect(cfg.port, int.parse(testPort));
    });
  });
}
