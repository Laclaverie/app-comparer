import 'dart:io' show File;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple injectable configuration service for server IP/port
class ConfigService {
  static const _ipKey = 'server_ip';
  static const _portKey = 'server_port';

  final String defaultIp; // constructor default fallback (if no .env)
  final int defaultPort;

  late final SharedPreferences _prefs;

  String? _ipOverride;
  int? _portOverride;

  // Effective defaults computed at init (may come from .env)
  late String _effectiveDefaultIp;
  late int _effectiveDefaultPort;

  ConfigService({this.defaultIp = 'localhost', this.defaultPort = 8080});

  Future<void> init({Map<String, String>? envOverride}) async {
    // 1) If tests or callers provide envOverride, use it (explicit precedence)
    String? envIp = envOverride != null ? envOverride['SERVER_IP'] : null;
    String? envPort = envOverride != null ? envOverride['SERVER_PORT'] : null;

    // 2) Otherwise try flutter_dotenv to load .env (preferred)
    final envFilePath = 'apps/client/.env';
    final envFile = File(envFilePath);

    if (envIp == null && envPort == null) {
      if (envFile.existsSync()) {
        try {
          await dotenv.load(fileName: envFilePath);
          envIp = dotenv.env['SERVER_IP'];
          envPort = dotenv.env['SERVER_PORT'];
        } catch (e) {
          // Clear and throw a clear error so the caller knows what happened
          final message = 'Failed to load .env at $envFilePath: $e';
          throw ConfigException(message);
        }
      }
    }

    // 3) If still missing, attempt manual parse (non-fatal)
    if ((envIp == null || envPort == null) && envFile.existsSync()) {
      try {
        final lines = envFile.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
          final parts = trimmed.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();
            if (key == 'SERVER_IP' && envIp == null) envIp = value;
            if (key == 'SERVER_PORT' && envPort == null) envPort = value;
          }
        }
      } catch (e) {
        // Clear and throw a clear error so the caller knows what happened
          final message = '3rd attempt : Failed to load .env at $envFilePath: $e';
          throw ConfigException(message);
      }
    }

    _effectiveDefaultIp = envIp ?? defaultIp;
    _effectiveDefaultPort = int.tryParse(envPort ?? '') ?? defaultPort;

    _prefs = await SharedPreferences.getInstance();
    _ipOverride = _prefs.getString(_ipKey);
    _portOverride = _prefs.getInt(_portKey);
  }

  /// Save an IP and port override (persists in SharedPreferences)
  Future<void> setIpPort(String ip, int port) async {
    _ipOverride = ip;
    _portOverride = port;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
    await prefs.setInt(_portKey, port);
  }

  /// Clear any saved overrides and revert to defaults
  Future<void> clearOverride() async {
    _ipOverride = null;
    _portOverride = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ipKey);
    await prefs.remove(_portKey);
  }

  String get ip => _ipOverride ?? _effectiveDefaultIp;
  int get port => _portOverride ?? _effectiveDefaultPort;

  String get baseUrl => 'http://$ip:$port';

}

class ConfigException implements Exception {
  final String message;
  ConfigException(this.message);

  @override
  String toString() => 'ConfigException: $message';
}
