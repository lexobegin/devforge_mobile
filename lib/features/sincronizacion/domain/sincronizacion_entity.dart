// lib/features/sincronizacion/domain/sincronizacion_entity.dart
//
// Entidades del módulo de sincronización móvil/web offline.
//
// Reflejan los schemas `BatchSincronizacionRequest/Response`,
// `ResultadoCambioSync`, `ConflictoSync` y `ResolverConflictoRequest`
// del backend (`app/schemas/sincronizacion_schema.py`).

import 'package:flutter/foundation.dart';

// ======================================================================
// Enums
// ======================================================================
enum EstadoColaSync {
  pendiente('PENDIENTE', 'Pendiente'),
  sincronizado('SINCRONIZADO', 'Sincronizado'),
  conflicto('CONFLICTO', 'Conflicto');

  const EstadoColaSync(this.value, this.label);

  final String value;
  final String label;

  static EstadoColaSync fromValue(String value) {
    return EstadoColaSync.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoColaSync.pendiente,
    );
  }
}

// ======================================================================
// Item de cambio offline (para enviar al backend)
// ======================================================================
@immutable
class CambioOfflineItem {
  final String idTemporalLocal;
  final String tipoOperacion;
  final Map<String, dynamic> payload;
  final DateTime? timestampLocal;

  const CambioOfflineItem({
    required this.idTemporalLocal,
    required this.tipoOperacion,
    required this.payload,
    this.timestampLocal,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_temporal_local': idTemporalLocal,
      'tipo_operacion': tipoOperacion,
      'payload': payload,
      if (timestampLocal != null)
        'timestamp_local': timestampLocal!.toUtc().toIso8601String(),
    };
  }
}

// ======================================================================
// Batch request
// ======================================================================
@immutable
class BatchSincronizacionRequest {
  final String idDispositivo;
  final int idDiagrama;
  final List<CambioOfflineItem> cambios;

  const BatchSincronizacionRequest({
    required this.idDispositivo,
    required this.idDiagrama,
    required this.cambios,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_dispositivo': idDispositivo,
      'id_diagrama': idDiagrama,
      'cambios': cambios.map((c) => c.toJson()).toList(),
    };
  }
}

// ======================================================================
// Resultado individual
// ======================================================================
@immutable
class ResultadoCambioSync {
  final String idTemporalLocal;
  final EstadoColaSync estado;
  final int? idReal;
  final String? motivoConflicto;

  const ResultadoCambioSync({
    required this.idTemporalLocal,
    required this.estado,
    this.idReal,
    this.motivoConflicto,
  });

  bool get sincronizado => estado == EstadoColaSync.sincronizado;
  bool get enConflicto => estado == EstadoColaSync.conflicto;
}

// ======================================================================
// Batch response
// ======================================================================
@immutable
class BatchSincronizacionResponse {
  final String idDispositivo;
  final int idDiagrama;
  final int totalRecibidos;
  final int totalSincronizados;
  final int totalConflictos;
  final List<ResultadoCambioSync> resultados;

  const BatchSincronizacionResponse({
    required this.idDispositivo,
    required this.idDiagrama,
    required this.totalRecibidos,
    required this.totalSincronizados,
    required this.totalConflictos,
    required this.resultados,
  });

  bool get todoOk =>
      totalRecibidos > 0 &&
      totalSincronizados == totalRecibidos &&
      totalConflictos == 0;
}

// ======================================================================
// Conflicto pendiente de resolución
// ======================================================================
@immutable
class ConflictoSync {
  final int id;
  final String idDispositivo;
  final int idUsuario;
  final int? idDiagrama;
  final String tipoOperacion;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const ConflictoSync({
    required this.id,
    required this.idDispositivo,
    required this.idUsuario,
    this.idDiagrama,
    required this.tipoOperacion,
    required this.payload,
    required this.createdAt,
  });
}