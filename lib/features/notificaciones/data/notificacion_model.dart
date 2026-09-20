// lib/features/notificaciones/data/notificacion_model.dart
//
// Mappers JSON ↔ entidades de Notificación.

//import '../../domain/notificacion_entity.dart';
import '../domain/notificacion_entity.dart';

class NotificacionModel {
  const NotificacionModel._();

  static Notificacion fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: (json['id'] as num).toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      tipo: TipoNotificacion.fromValue(json['tipo'] as String? ?? 'SISTEMA'),
      mensaje: json['mensaje'] as String? ?? '',
      idReferencia: (json['id_referencia'] as num?)?.toInt(),
      leida: json['leida'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static ContadorNoLeidas contadorFromJson(Map<String, dynamic> json) {
    return ContadorNoLeidas(
      total: (json['total_no_leidas'] as num?)?.toInt() ?? 0,
    );
  }
}

// ======================================================================
// Helpers
// ======================================================================
DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}