// lib/core/permissions/permission_service.dart
//
// Servicio centralizado de permisos.
//
// Envuelve `permission_handler` para pedir permisos de cámara,
// micrófono, fotos y notificaciones, con mensajes claros.

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  // ==================================================================
  // Cámara
  // ==================================================================
  Future<bool> pedirCamara() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // ==================================================================
  // Micrófono
  // ==================================================================
  Future<bool> pedirMicrofono() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ==================================================================
  // Fotos / galería
  // ==================================================================
  /// En Android 13+ (API 33) se usa Permission.photos.
  /// En versiones anteriores se usa Permission.storage.
  Future<bool> pedirFotos() async {
    // Intenta primero photos (Android 13+, iOS 14+)
    final photos = await Permission.photos.request();
    if (photos.isGranted) return true;

    // Fallback a storage para Android < 13
    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  // ==================================================================
  // Notificaciones
  // ==================================================================
  Future<bool> pedirNotificaciones() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ==================================================================
  // Helpers
  // ==================================================================
  /// Abre la configuración de la app si un permiso fue denegado
  /// permanentemente.
  Future<void> abrirConfiguracion() async {
    await openAppSettings();
  }

  /// Verifica si un permiso está permanentemente denegado.
  Future<bool> estaDenegadoPermanentemente(Permission permiso) async {
    final status = await permiso.status;
    return status.isPermanentlyDenied;
  }
}