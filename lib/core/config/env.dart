// lib/core/config/env.dart
//
// Configuración de entorno de la app móvil.
//
// Lee las variables desde `--dart-define` en tiempo de compilación:
//
//   flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000/api/v1 \
//               --dart-define=WS_BASE_URL=ws://192.168.1.5:8000
//
// Los valores por defecto están pensados para el emulador de Android
// (10.0.2.2 es el host local desde el emulador).

import 'package:flutter/foundation.dart';

/// Configuración inmutable de la app.
class Env {
  const Env._();

  // ==================================================================
  // Backend
  // ==================================================================
  /// URL base de la API REST.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    //defaultValue: 'http://10.0.2.2:8000/api/v1',
    defaultValue: 'http://192.168.1.5:8000/api/v1',
  );

  /// URL base del WebSocket.
  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    //defaultValue: 'ws://10.0.2.2:8000',
    defaultValue: 'ws://192.168.1.5:8000',
  );

  // ==================================================================
  // Entorno
  // ==================================================================
  /// Entorno actual: 'development', 'production' o 'test'.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Versión de la app.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );

  // ==================================================================
  // Feature flags
  // ==================================================================
  /// Habilita el funcionamiento offline (persistencia local).
  static const bool enableOffline = bool.fromEnvironment(
    'ENABLE_OFFLINE',
    defaultValue: true,
  );

  /// Habilita el uso de IA local (modelos embebidos).
  /// Actualmente STUB: si es true, intenta usar IA local; si falla,
  /// cae al backend si `enableAiCloudFallback` es true.
  static const bool enableAiLocal = bool.fromEnvironment(
    'ENABLE_AI_LOCAL',
    defaultValue: true,
  );

  /// Permite caer al backend cuando la IA local no está disponible.
  static const bool enableAiCloudFallback = bool.fromEnvironment(
    'ENABLE_AI_CLOUD_FALLBACK',
    defaultValue: true,
  );

  // ==================================================================
  // Timeouts y reconexión
  // ==================================================================
  /// Timeout por defecto de las requests HTTP (ms).
  static const int apiTimeoutMs = int.fromEnvironment(
    'API_TIMEOUT_MS',
    defaultValue: 30000,
  );

  /// Máximos intentos de reconexión del WS.
  static const int wsReconnectMaxAttempts = int.fromEnvironment(
    'WS_RECONNECT_MAX_ATTEMPTS',
    defaultValue: 10,
  );

  /// Delay inicial entre reintentos del WS (ms).
  static const int wsReconnectInitialDelayMs = int.fromEnvironment(
    'WS_RECONNECT_INITIAL_DELAY_MS',
    defaultValue: 1000,
  );

  // ==================================================================
  // Helpers
  // ==================================================================
  static bool get isDev => appEnv == 'development';
  static bool get isProd => appEnv == 'production';

  /// URL del WebSocket para un diagrama, con el token de acceso.
  static String diagramWsUrl(int diagramaId, String token) {
    return '$wsBaseUrl/ws/diagramas/$diagramaId?token=${Uri.encodeComponent(token)}';
  }

  /// Claves de almacenamiento seguro.
  static const String storageKeyAccessToken = 'devforge_access_token';
  static const String storageKeyRefreshToken = 'devforge_refresh_token';
  static const String storageKeyUsuarioId = 'devforge_usuario_id';

  /// Log para debug (solo en modo desarrollo).
  static void log(String message) {
    if (isDev) {
      debugPrint('[DevForge] $message');
    }
  }
}