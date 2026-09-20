// lib/features/trazabilidad/domain/trazabilidad_entity.dart
//
// Entidades: HistorialCambio, VersionDiagrama, ComentarioDiagrama.

import 'package:flutter/foundation.dart';

// ======================================================================
// Enums
// ======================================================================
enum TipoCambio {
  crear('CREAR', 'Crear'),
  modificar('MODIFICAR', 'Modificar'),
  eliminar('ELIMINAR', 'Eliminar');

  const TipoCambio(this.value, this.label);

  final String value;
  final String label;

  static TipoCambio fromValue(String value) {
    return TipoCambio.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TipoCambio.modificar,
    );
  }
}

// ======================================================================
// Historial
// ======================================================================
@immutable
class HistorialCambio {
  final int id;
  final int idDiagrama;
  final int idUsuario;
  final TipoCambio tipoCambio;
  final String tipoEntidad;
  final int idEntidad;
  final Map<String, dynamic> datosCambio;
  final DateTime createdAt;

  const HistorialCambio({
    required this.id,
    required this.idDiagrama,
    required this.idUsuario,
    required this.tipoCambio,
    required this.tipoEntidad,
    required this.idEntidad,
    required this.datosCambio,
    required this.createdAt,
  });
}

// ======================================================================
// Versión
// ======================================================================
@immutable
class VersionDiagramaResumen {
  final int id;
  final int idDiagrama;
  final int numeroVersion;
  final int idUsuario;
  final String? comentario;
  final DateTime createdAt;

  const VersionDiagramaResumen({
    required this.id,
    required this.idDiagrama,
    required this.numeroVersion,
    required this.idUsuario,
    this.comentario,
    required this.createdAt,
  });
}

@immutable
class VersionDiagrama {
  final int id;
  final int idDiagrama;
  final int numeroVersion;
  final Map<String, dynamic> contenidoJson;
  final int idUsuario;
  final String? comentario;
  final DateTime createdAt;

  const VersionDiagrama({
    required this.id,
    required this.idDiagrama,
    required this.numeroVersion,
    required this.contenidoJson,
    required this.idUsuario,
    this.comentario,
    required this.createdAt,
  });
}

// ======================================================================
// Comentario
// ======================================================================
@immutable
class ComentarioDiagrama {
  final int id;
  final int idDiagrama;
  final int idUsuario;
  final String? tipoEntidad;
  final int? idEntidad;
  final String texto;
  final bool resuelto;
  final DateTime createdAt;

  const ComentarioDiagrama({
    required this.id,
    required this.idDiagrama,
    required this.idUsuario,
    this.tipoEntidad,
    this.idEntidad,
    required this.texto,
    this.resuelto = false,
    required this.createdAt,
  });

  bool get esGeneral => tipoEntidad == null && idEntidad == null;

  ComentarioDiagrama copyWith({
    int? id,
    int? idDiagrama,
    int? idUsuario,
    String? tipoEntidad,
    int? idEntidad,
    String? texto,
    bool? resuelto,
    DateTime? createdAt,
  }) {
    return ComentarioDiagrama(
      id: id ?? this.id,
      idDiagrama: idDiagrama ?? this.idDiagrama,
      idUsuario: idUsuario ?? this.idUsuario,
      tipoEntidad: tipoEntidad ?? this.tipoEntidad,
      idEntidad: idEntidad ?? this.idEntidad,
      texto: texto ?? this.texto,
      resuelto: resuelto ?? this.resuelto,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComentarioDiagrama &&
        other.id == id &&
        other.texto == texto &&
        other.resuelto == resuelto;
  }

  @override
  int get hashCode => Object.hash(id, texto, resuelto);
}