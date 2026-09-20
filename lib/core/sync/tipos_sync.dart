// lib/core/sync/tipos_sync.dart
//
// Tipos y enums compartidos por el módulo de sincronización.

import 'package:flutter/foundation.dart';

// ======================================================================
// Operaciones soportadas en la cola
// ======================================================================
enum TipoOperacionSync {
  crearClase('CREAR_CLASE', 'Crear clase'),
  modificarClase('MODIFICAR_CLASE', 'Modificar clase'),
  eliminarClase('ELIMINAR_CLASE', 'Eliminar clase'),
  agregarAtributo('AGREGAR_ATRIBUTO', 'Agregar atributo'),
  modificarAtributo('MODIFICAR_ATRIBUTO', 'Modificar atributo'),
  eliminarAtributo('ELIMINAR_ATRIBUTO', 'Eliminar atributo'),
  crearRelacion('CREAR_RELACION', 'Crear relación'),
  modificarRelacion('MODIFICAR_RELACION', 'Modificar relación'),
  eliminarRelacion('ELIMINAR_RELACION', 'Eliminar relación');

  const TipoOperacionSync(this.value, this.label);

  final String value;
  final String label;

  static TipoOperacionSync? fromValue(String value) {
    for (final t in TipoOperacionSync.values) {
      if (t.value == value) return t;
    }
    return null;
  }
}

// ======================================================================
// Estado de un item de la cola
// ======================================================================
enum EstadoSync {
  pendiente('PENDIENTE', 'Pendiente'),
  enviado('ENVIADO', 'Enviado'),
  conflicto('CONFLICTO', 'Conflicto'),
  fallido('FALLIDO', 'Fallido');

  const EstadoSync(this.value, this.label);

  final String value;
  final String label;

  static EstadoSync fromValue(String value) {
    return EstadoSync.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoSync.pendiente,
    );
  }
}

// ======================================================================
// Item de la cola (modelo de dominio)
// ======================================================================
@immutable
class ItemColaSync {
  final int? localId;
  final String idTemporalLocal;
  final int idDiagrama;
  final TipoOperacionSync tipoOperacion;
  final Map<String, dynamic> payload;
  final int timestampLocal;
  final EstadoSync estado;
  final int intentos;
  final String? ultimoError;

  const ItemColaSync({
    this.localId,
    required this.idTemporalLocal,
    required this.idDiagrama,
    required this.tipoOperacion,
    required this.payload,
    required this.timestampLocal,
    this.estado = EstadoSync.pendiente,
    this.intentos = 0,
    this.ultimoError,
  });

  ItemColaSync copyWith({
    int? localId,
    String? idTemporalLocal,
    int? idDiagrama,
    TipoOperacionSync? tipoOperacion,
    Map<String, dynamic>? payload,
    int? timestampLocal,
    EstadoSync? estado,
    int? intentos,
    String? ultimoError,
  }) {
    return ItemColaSync(
      localId: localId ?? this.localId,
      idTemporalLocal: idTemporalLocal ?? this.idTemporalLocal,
      idDiagrama: idDiagrama ?? this.idDiagrama,
      tipoOperacion: tipoOperacion ?? this.tipoOperacion,
      payload: payload ?? this.payload,
      timestampLocal: timestampLocal ?? this.timestampLocal,
      estado: estado ?? this.estado,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }
}

// ======================================================================
// Resultado de sincronización
// ======================================================================
@immutable
class ResultadoSync {
  final int total;
  final int sincronizados;
  final int conflictos;
  final int fallidos;

  const ResultadoSync({
    this.total = 0,
    this.sincronizados = 0,
    this.conflictos = 0,
    this.fallidos = 0,
  });

  bool get hayCambios => total > 0;
  bool get todoOk => hayCambios && sincronizados == total;

  static const ResultadoSync vacio = ResultadoSync();
}

// ======================================================================
// Estrategia de resolución de conflictos
// ======================================================================
enum EstrategiaConflicto {
  offline('OFFLINE', 'Aplicar cambio offline'),
  servidor('SERVIDOR', 'Conservar versión del servidor'),
  fusionar('FUSIONAR', 'Fusionar manualmente');

  const EstrategiaConflicto(this.value, this.label);

  final String value;
  final String label;
}