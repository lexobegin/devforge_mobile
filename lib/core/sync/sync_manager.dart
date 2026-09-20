// lib/core/sync/sync_manager.dart
//
// Gestor de sincronización.
//
// Toma los items pendientes de la cola, los envía al backend en un batch
// y procesa la respuesta:
// - SINCRONIZADO: marca el item como enviado.
// - CONFLICTO: marca el item como conflicto (para revisión).
// - Error de red: marca como fallido (se reintentará).

import 'package:dio/dio.dart';

import '../../features/sincronizacion/data/sincronizacion_remote_datasource.dart';
import '../../features/sincronizacion/domain/sincronizacion_entity.dart';
import '../network/api_client.dart';
import 'sync_queue.dart';
import 'tipos_sync.dart';

import 'dart:developer' as dev;
import 'id_mapper.dart';

class SyncManager {
  SyncManager({
    required SyncQueue queue,
    required SincronizacionRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _queue = queue,
        _remote = remote,
        _tokenStorage = tokenStorage;

  final SyncQueue _queue;
  final SincronizacionRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  bool _sincronizando = false;

  bool get estaSincronizando => _sincronizando;

  Map<String, int> _lastMapeoIds = {};

/// Mapeo del último batch procesado: {id_temporal: id_real}.
Map<String, int> get ultimoMapeo => _lastMapeoIds;

  // ==================================================================
  // Sincronización de un diagrama
  // ==================================================================
  Future<ResultadoSync> sincronizarDiagrama(int idDiagrama) async {
    if (_sincronizando) return ResultadoSync.vacio;


    


    final pendientes = await _queue.pendientesPorDiagrama(idDiagrama);
    if (pendientes.isEmpty) return ResultadoSync.vacio;

    _sincronizando = true;
    try {
      // Verificar que tenemos token
      final token = await _tokenStorage.getAccess();
      if (token == null || token.isEmpty) {
        return ResultadoSync.vacio;
      }

      // Armar el batch
      final cambios = pendientes.map((item) {
        return {
          'id_temporal_local': item.idTemporalLocal,
          'tipo_operacion': item.tipoOperacion.value,
          'payload': item.payload,
          'timestamp_local':
              DateTime.fromMillisecondsSinceEpoch(item.timestampLocal)
                  .toUtc()
                  .toIso8601String(),
        };
      }).toList();

      final response = await _remote.enviarBatch(
        idDispositivo: await _getDispositivoId(),
        idDiagrama: idDiagrama,
        cambios: cambios,
      );

      // Procesar resultados
      final porIdTemporal = {
        for (final r in response.resultados) r.idTemporalLocal: r,
      };

      int sincronizados = 0;
      int conflictos = 0;
      int fallidos = 0;

      // Mapeo id_temporal_local → id_real (para actualizar el estado local)
      final mapeoIds = <String, int>{};

      for (final item in pendientes) {
        if (item.localId == null) continue;
        final result = porIdTemporal[item.idTemporalLocal];

        if (result == null) {
          await _queue.marcarFallido(
            item.localId!,
            'Sin respuesta del backend',
          );
          fallidos++;
        } else if (result.estado == 'SINCRONIZADO') {
          await _queue.marcarEnviado(item.localId!);
          sincronizados++;
          if (result.idReal != null) {
      mapeoIds[item.idTemporalLocal] = result.idReal!;
    }
        } else if (result.estado == 'CONFLICTO') {
          await _queue.marcarConflicto(
            item.localId!,
            result.motivoConflicto ?? 'Conflicto detectado',
          );
          conflictos++;
        } else {
          await _queue.marcarFallido(item.localId!, 'Estado desconocido');
          fallidos++;
        }
      }

      // Limpiar enviados
      await _queue.limpiarEnviados();

      // Devolver el mapeo (el caller se encarga de aplicarlo al estado)
      _lastMapeoIds = mapeoIds;

      return ResultadoSync(
        total: pendientes.length,
        sincronizados: sincronizados,
        conflictos: conflictos,
        fallidos: fallidos,
      );
    } on DioException {
      // Error de red: marcar todos como fallidos para reintentar
      for (final item in pendientes) {
        if (item.localId == null) continue;
        await _queue.marcarFallido(item.localId!, 'Error de red');
      }
      rethrow;
    } finally {
      _sincronizando = false;
    }
  }

  // ==================================================================
  // Sincronizar todo lo pendiente (todos los diagramas)
  // ==================================================================
  Future<ResultadoSync> sincronizarTodo() async {
    final todos = await _queue.todosLosPendientes();
    if (todos.isEmpty) return ResultadoSync.vacio;

    // Agrupar por diagrama
    final porDiagrama = <int, List<ItemColaSync>>{};
    for (final item in todos) {
      porDiagrama.putIfAbsent(item.idDiagrama, () => []).add(item);
    }

    int total = 0;
    int sincronizados = 0;
    int conflictos = 0;
    int fallidos = 0;

    for (final idDiagrama in porDiagrama.keys) {
      try {
        final res = await sincronizarDiagrama(idDiagrama);
        total += res.total;
        sincronizados += res.sincronizados;
        conflictos += res.conflictos;
        fallidos += res.fallidos;
      } catch (_) {
        // Continuar con el siguiente diagrama
      }
    }

    return ResultadoSync(
      total: total,
      sincronizados: sincronizados,
      conflictos: conflictos,
      fallidos: fallidos,
    );
  }

  // ==================================================================
  // Helpers
  // ==================================================================
  String? _dispositivoIdCache;

  Future<String> _getDispositivoId() async {
    if (_dispositivoIdCache != null) return _dispositivoIdCache!;

    // ID simple basado en timestamp; se persiste en memoria mientras
    // la app está activa.
    _dispositivoIdCache =
        'mobile-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    return _dispositivoIdCache!;
  }
}