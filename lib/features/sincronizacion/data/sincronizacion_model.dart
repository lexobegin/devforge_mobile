// lib/features/sincronizacion/data/sincronizacion_model.dart
//
// Mappers JSON ↔ entidades de Sincronización.

import '../domain/sincronizacion_entity.dart';

class SincronizacionModel {
  const SincronizacionModel._();

  // ==================================================================
  // Resultado individual
  // ==================================================================
  static ResultadoCambioSync resultadoCambioFromJson(
    Map<String, dynamic> json,
  ) {
    return ResultadoCambioSync(
      idTemporalLocal: json['id_temporal_local'] as String? ?? '',
      estado: EstadoColaSync.fromValue(
        json['estado'] as String? ?? 'PENDIENTE',
      ),
      idReal: (json['id_real'] as num?)?.toInt(),
      motivoConflicto: json['motivo_conflicto'] as String?,
    );
  }

  // ==================================================================
  // Batch response
  // ==================================================================
  static BatchSincronizacionResponse batchResponseFromJson(
    Map<String, dynamic> json,
  ) {
    final resultadosJson = (json['resultados'] as List?) ?? [];

    return BatchSincronizacionResponse(
      idDispositivo: json['id_dispositivo'] as String? ?? '',
      idDiagrama: (json['id_diagrama'] as num?)?.toInt() ?? 0,
      totalRecibidos: (json['total_recibidos'] as num?)?.toInt() ?? 0,
      totalSincronizados:
          (json['total_sincronizados'] as num?)?.toInt() ?? 0,
      totalConflictos: (json['total_conflictos'] as num?)?.toInt() ?? 0,
      resultados: resultadosJson
          .map((r) => resultadoCambioFromJson(
                (r as Map).cast<String, dynamic>(),
              ))
          .toList(),
    );
  }

  // ==================================================================
  // Conflicto
  // ==================================================================
  static ConflictoSync conflictoFromJson(Map<String, dynamic> json) {
    return ConflictoSync(
      id: (json['id'] as num).toInt(),
      idDispositivo: json['id_dispositivo'] as String? ?? '',
      idUsuario: (json['id_usuario'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num?)?.toInt(),
      tipoOperacion: json['tipo_operacion'] as String? ?? '',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: _parseDateTime(json['created_at']),
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