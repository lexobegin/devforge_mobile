// lib/core/sync/sync_queue.dart
//
// Cola de sincronización offline.
//
// Envuelve la tabla `cola_sincronizacion` de drift con una API cómoda
// para encolar, listar y marcar items.

import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'tipos_sync.dart';

class SyncQueue {
  SyncQueue(this._db);

  final AppDatabase _db;

  // ==================================================================
  // Encolar
  // ==================================================================
  Future<String> encolar({
    required int idDiagrama,
    required TipoOperacionSync tipoOperacion,
    required Map<String, dynamic> payload,
  }) async {
    final idTemporal = _generarIdTemporal();

    await _db.encolarCambio(
      ColaSincronizacionCompanion.insert(
        idTemporalLocal: idTemporal,
        idDiagrama: idDiagrama,
        tipoOperacion: tipoOperacion.value,
        payload: jsonEncode(payload),
        timestampLocal: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    return idTemporal;
  }

  // ==================================================================
  // Consultas
  // ==================================================================
  Future<List<ItemColaSync>> pendientesPorDiagrama(int idDiagrama) async {
    final rows = await _db.pendientesPorDiagrama(idDiagrama);
    return rows.map(_toItem).toList();
  }

  Future<List<ItemColaSync>> todosLosPendientes() async {
    final rows = await _db.todosLosPendientes();
    return rows.map(_toItem).toList();
  }

  Future<int> contarPendientes() => _db.contarPendientes();

  Future<int> contarPendientesPorDiagrama(int idDiagrama) async {
    final items = await pendientesPorDiagrama(idDiagrama);
    return items.length;
  }

  // ==================================================================
  // Estados
  // ==================================================================
  Future<void> marcarEnviado(int localId) => _db.marcarEnviado(localId);

  Future<void> marcarConflicto(int localId, String motivo) =>
      _db.marcarConflicto(localId, motivo);

  Future<void> marcarFallido(int localId, String error) =>
      _db.marcarFallido(localId, error);

  // ==================================================================
  // Limpieza
  // ==================================================================
  Future<void> limpiarEnviados() => _db.limpiarEnviados();

  Future<void> limpiarPorDiagrama(int idDiagrama) =>
      _db.limpiarPorDiagrama(idDiagrama);

  // ==================================================================
  // Helpers
  // ==================================================================
  ItemColaSync _toItem(ColaSincronizacionLocal row) {
    return ItemColaSync(
      localId: row.localId,
      idTemporalLocal: row.idTemporalLocal,
      idDiagrama: row.idDiagrama,
      tipoOperacion: TipoOperacionSync.fromValue(row.tipoOperacion) ??
          TipoOperacionSync.crearClase,
      payload: (jsonDecode(row.payload) as Map).cast<String, dynamic>(),
      timestampLocal: row.timestampLocal,
      estado: EstadoSync.fromValue(row.estado),
      intentos: row.intentos,
      ultimoError: row.ultimoError,
    );
  }

  String _generarIdTemporal() {
    final rand = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'tmp-$rand';
  }
}