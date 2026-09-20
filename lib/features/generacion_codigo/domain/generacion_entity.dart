// lib/features/generacion_codigo/domain/generacion_entity.dart
//
// Entidades de dominio: TrabajoGeneracion, EntidadGenerada, ReglaMapeo.

import 'package:flutter/foundation.dart';

// ======================================================================
// Enums
// ======================================================================
enum EstadoTrabajoGeneracion {
  pendiente('PENDIENTE', 'En cola'),
  enProceso('EN_PROCESO', 'Generando'),
  exitoso('EXITOSO', 'Completado'),
  fallido('FALLIDO', 'Fallido');

  const EstadoTrabajoGeneracion(this.value, this.label);

  final String value;
  final String label;

  static EstadoTrabajoGeneracion fromValue(String value) {
    return EstadoTrabajoGeneracion.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoTrabajoGeneracion.pendiente,
    );
  }

  bool get estaEnCurso =>
      this == pendiente || this == enProceso;
  bool get finalizo =>
      this == exitoso || this == fallido;
}

// ======================================================================
// Trabajo de generación
// ======================================================================
@immutable
class TrabajoGeneracion {
  final int id;
  final int idDiagrama;
  final int idUsuario;
  final String stackDestino;
  final EstadoTrabajoGeneracion estado;
  final String? rutaSalida;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;

  const TrabajoGeneracion({
    required this.id,
    required this.idDiagrama,
    required this.idUsuario,
    this.stackDestino = 'SPRING_BOOT_JPA_POSTGRES',
    required this.estado,
    this.rutaSalida,
    this.startedAt,
    this.finishedAt,
    required this.createdAt,
  });

  TrabajoGeneracion copyWith({
    int? id,
    int? idDiagrama,
    int? idUsuario,
    String? stackDestino,
    EstadoTrabajoGeneracion? estado,
    String? rutaSalida,
    DateTime? startedAt,
    DateTime? finishedAt,
    DateTime? createdAt,
  }) {
    return TrabajoGeneracion(
      id: id ?? this.id,
      idDiagrama: idDiagrama ?? this.idDiagrama,
      idUsuario: idUsuario ?? this.idUsuario,
      stackDestino: stackDestino ?? this.stackDestino,
      estado: estado ?? this.estado,
      rutaSalida: rutaSalida ?? this.rutaSalida,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrabajoGeneracion &&
        other.id == id &&
        other.estado == estado;
  }

  @override
  int get hashCode => Object.hash(id, estado);

  @override
  String toString() =>
      'TrabajoGeneracion(id: $id, estado: ${estado.value})';
}

// ======================================================================
// Entidad generada
// ======================================================================
@immutable
class EntidadGenerada {
  final int id;
  final int idTrabajo;
  final int idClaseUml;
  final String nombreClaseJava;
  final String nombreTabla;
  final List<ReglaMapeo> reglasMapeo;

  const EntidadGenerada({
    required this.id,
    required this.idTrabajo,
    required this.idClaseUml,
    required this.nombreClaseJava,
    required this.nombreTabla,
    this.reglasMapeo = const [],
  });

  int get totalCampos => reglasMapeo.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EntidadGenerada &&
        other.id == id &&
        other.nombreClaseJava == nombreClaseJava;
  }

  @override
  int get hashCode => Object.hash(id, nombreClaseJava);
}

// ======================================================================
// Regla de mapeo
// ======================================================================
@immutable
class ReglaMapeo {
  final int id;
  final int idEntidadGenerada;
  final int idAtributoUml;
  final String nombreColumna;
  final String tipoSql;
  final bool esClavePrimaria;
  final bool esNulleable;

  const ReglaMapeo({
    required this.id,
    required this.idEntidadGenerada,
    required this.idAtributoUml,
    required this.nombreColumna,
    required this.tipoSql,
    this.esClavePrimaria = false,
    this.esNulleable = true,
  });
}

// ======================================================================
// Trabajo con detalle
// ======================================================================
@immutable
class TrabajoGeneracionDetalle {
  final TrabajoGeneracion trabajo;
  final List<EntidadGenerada> entidades;

  const TrabajoGeneracionDetalle({
    required this.trabajo,
    required this.entidades,
  });

  int get totalEntidades => entidades.length;
  int get totalCampos =>
      entidades.fold(0, (sum, e) => sum + e.totalCampos);
}

// ======================================================================
// Estado liviano (polling)
// ======================================================================
@immutable
class EstadoGeneracion {
  final int id;
  final EstadoTrabajoGeneracion estado;
  final int? progreso;
  final String? mensaje;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const EstadoGeneracion({
    required this.id,
    required this.estado,
    this.progreso,
    this.mensaje,
    this.startedAt,
    this.finishedAt,
  });

  bool get estaEnCurso => estado.estaEnCurso;
  bool get finalizo => estado.finalizo;
}

// ======================================================================
// Descarga
// ======================================================================
@immutable
class DescargaProyecto {
  final int idTrabajo;
  final String downloadUrl;
  final int? tamanioBytes;
  final bool incluyePostman;

  const DescargaProyecto({
    required this.idTrabajo,
    required this.downloadUrl,
    this.tamanioBytes,
    this.incluyePostman = true,
  });
}