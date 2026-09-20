// lib/features/trazabilidad/data/trazabilidad_model.dart
//
// Mappers JSON ↔ entidades de Trazabilidad.

//import '../../domain/trazabilidad_entity.dart';
import '../domain/trazabilidad_entity.dart';

class TrazabilidadModel {
  const TrazabilidadModel._();

  // ==================================================================
  // Historial
  // ==================================================================
  static HistorialCambio historialFromJson(Map<String, dynamic> json) {
    return HistorialCambio(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      tipoCambio: TipoCambio.fromValue(
        json['tipo_cambio'] as String? ?? 'MODIFICAR',
      ),
      tipoEntidad: json['tipo_entidad'] as String? ?? '',
      idEntidad: (json['id_entidad'] as num).toInt(),
      datosCambio:
          (json['datos_cambio'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  // ==================================================================
  // Versiones
  // ==================================================================
  static VersionDiagramaResumen versionResumenFromJson(
    Map<String, dynamic> json,
  ) {
    return VersionDiagramaResumen(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      numeroVersion: (json['numero_version'] as num).toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      comentario: json['comentario'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static VersionDiagrama versionFromJson(Map<String, dynamic> json) {
    return VersionDiagrama(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      numeroVersion: (json['numero_version'] as num).toInt(),
      contenidoJson:
          (json['contenido_json'] as Map?)?.cast<String, dynamic>() ?? {},
      idUsuario: (json['id_usuario'] as num).toInt(),
      comentario: json['comentario'] as String?,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static Map<String, dynamic> toGuardarVersionJson({
    required Map<String, dynamic> contenidoJson,
    String? comentario,
  }) {
    return {
      'contenido_json': contenidoJson,
      if (comentario != null && comentario.isNotEmpty)
        'comentario': comentario,
    };
  }

  // ==================================================================
  // Comentarios
  // ==================================================================
  static ComentarioDiagrama comentarioFromJson(Map<String, dynamic> json) {
    return ComentarioDiagrama(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      tipoEntidad: json['tipo_entidad'] as String?,
      idEntidad: (json['id_entidad'] as num?)?.toInt(),
      texto: json['texto'] as String? ?? '',
      resuelto: json['resuelto'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static Map<String, dynamic> toCrearComentarioJson({
    String? tipoEntidad,
    int? idEntidad,
    required String texto,
  }) {
    return {
      if (tipoEntidad != null) 'tipo_entidad': tipoEntidad,
      if (idEntidad != null) 'id_entidad': idEntidad,
      'texto': texto,
    };
  }

  static Map<String, dynamic> toActualizarComentarioJson({
    String? texto,
    bool? resuelto,
  }) {
    return {
      if (texto != null) 'texto': texto,
      if (resuelto != null) 'resuelto': resuelto,
    };
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