import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración central de la API REST de AulaSync para la app móvil Flutter.
class ApiConfig {
  /// Determina la URL base óptima según la plataforma de ejecución.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      // En Flutter Web (Chrome / Edge / Firefox), XAMPP corre localmente en el host.
      return 'http://localhost/aulasync/api';
    }
    // En emulador Android estándar, el host de la máquina es 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/aulasync/api';
    }
    // Para Windows Desktop, macOS o Linux
    return 'http://localhost/aulasync/api';
  }

  static String _baseUrl = '';

  /// URL base actual de la API REST.
  static String get baseUrl {
    if (_baseUrl.isEmpty) {
      _baseUrl = defaultBaseUrl;
    }
    return _baseUrl;
  }

  static set baseUrl(String url) {
    setBaseUrl(url);
  }

  /// Permite actualizar la IP dinámicamente desde los ajustes de la app.
  static void setBaseUrl(String url) {
    final clean = url.trim();
    if (clean.endsWith('/')) {
      _baseUrl = clean.substring(0, clean.length - 1);
    } else {
      _baseUrl = clean;
    }
  }

  /// Actualiza y persiste la URL base en almacenamiento local (SharedPreferences).
  static Future<void> saveBaseUrl(String url) async {
    setBaseUrl(url);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aulasync_base_url', baseUrl);
    } catch (_) {}
  }
}
