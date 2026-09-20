// lib/features/generacion_codigo/data/generacion_model.dart
//
// Mappers JSON ↔ entidades de Generación de código.

//import '../../domain/generacion_entity.dart';
import '../domain/generacion_entity.dart';

class GeneracionModel {
  const GeneracionModel._();

  // ==================================================================
  // Trabajo
  // ==================================================================
  static TrabajoGeneracion trabajoFromJson(Map<String, dynamic> json) {
    return TrabajoGeneracion(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      stackDestino: json['stack_destino'] as String? ??
          'SPRING_BOOT_JPA_POSTGRES',
      estado: EstadoTrabajoGeneracion.fromValue(
        json['estado'] as String? ?? 'PENDIENTE',
      ),
      rutaSalida: json['ruta_salida'] as String?,
      startedAt: _parseDateTimeOrNull(json['started_at']),
      finishedAt: _parseDateTimeOrNull(json['finished_at']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static TrabajoGeneracionDetalle detalleFromJson(
    Map<String, dynamic> json,
  ) {
    final trabajo = trabajoFromJson(json);

    final entidadesJson = (json['entidades'] as List?) ?? [];
    final entidades = entidadesJson
        .map((e) => entidadFromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return TrabajoGeneracionDetalle(
      trabajo: trabajo,
      entidades: entidades,
    );
  }

  // ==================================================================
  // Entidad generada
  // ==================================================================
  static EntidadGenerada entidadFromJson(Map<String, dynamic> json) {
    final reglasJson = (json['reglas_mapeo'] as List?) ?? [];
    return EntidadGenerada(
      id: (json['id'] as num).toInt(),
      idTrabajo: (json['id_trabajo'] as num).toInt(),
      idClaseUml: (json['id_clase_uml'] as num).toInt(),
      nombreClaseJava: json['nombre_clase_java'] as String? ?? '',
      nombreTabla: json['nombre_tabla'] as String? ?? '',
      reglasMapeo: reglasJson
          .map((r) => reglaFromJson((r as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  // ==================================================================
  // Regla de mapeo
  // ==================================================================
  static ReglaMapeo reglaFromJson(Map<String, dynamic> json) {
    return ReglaMapeo(
      id: (json['id'] as num).toInt(),
      idEntidadGenerada: (json['id_entidad_generada'] as num).toInt(),
      idAtributoUml: (json['id_atributo_uml'] as num).toInt(),
      nombreColumna: json['nombre_columna'] as String? ?? '',
      tipoSql: json['tipo_sql'] as String? ?? '',
      esClavePrimaria: json['es_clave_primaria'] as bool? ?? false,
      esNulleable: json['es_nulleable'] as bool? ?? true,
    );
  }

  // ==================================================================
  // Estado liviano
  // ==================================================================
  static EstadoGeneracion estadoFromJson(Map<String, dynamic> json) {
    return EstadoGeneracion(
      id: (json['id'] as num).toInt(),
      estado: EstadoTrabajoGeneracion.fromValue(
        json['estado'] as String? ?? 'PENDIENTE',
      ),
      progreso: (json['progreso'] as num?)?.toInt(),
      mensaje: json['mensaje'] as String?,
      startedAt: _parseDateTimeOrNull(json['started_at']),
      finishedAt: _parseDateTimeOrNull(json['finished_at']),
    );
  }

  // ==================================================================
  // Descarga
  // ==================================================================
  static DescargaProyecto descargaFromJson(Map<String, dynamic> json) {
    return DescargaProyecto(
      idTrabajo: (json['id_trabajo'] as num).toInt(),
      downloadUrl: json['download_url'] as String? ?? '',
      tamanioBytes: (json['tamanio_bytes'] as num?)?.toInt(),
      incluyePostman: json['incluye_postman'] as bool? ?? true,
    );
  }

  // ==================================================================
  // Request
  // ==================================================================
  static Map<String, dynamic> toGenerarJson({
    String? stackDestino,
    bool? incluirPostman,
    String? nombreProyecto,
    String? packageBase,
  }) {
    return {
      if (stackDestino != null) 'stack_destino': stackDestino,
      if (incluirPostman != null) 'incluir_postman': incluirPostman,
      if (nombreProyecto != null && nombreProyecto.isNotEmpty)
        'nombre_proyecto': nombreProyecto,
      if (packageBase != null && packageBase.isNotEmpty)
        'package_base': packageBase,
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

DateTime? _parseDateTimeOrNull(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return null;
}