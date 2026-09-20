// lib/core/sync/sync_providers.dart
//
// Providers de sincronización.
//
// - Expone el SyncQueue, SyncManager y ConflictResolver.
// - Escucha los cambios de conectividad y dispara la sincronización.
// - Mantiene el estado del último resultado de sync.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sincronizacion/data/sincronizacion_remote_datasource.dart';
import '../network/api_client.dart';
import '../providers/core_providers.dart';
import 'conflict_resolver.dart';
import 'sync_manager.dart';
import 'sync_queue.dart';
import 'tipos_sync.dart';

// ======================================================================
// Providers base
// ======================================================================
final syncQueueProvider = Provider<SyncQueue>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncQueue(db);
});

final sincronizacionRemoteDataSourceProvider =
    Provider<SincronizacionRemoteDataSource>((ref) {
  return SincronizacionRemoteDataSource(ref.watch(apiClientProvider));
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(
    queue: ref.watch(syncQueueProvider),
    remote: ref.watch(sincronizacionRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  return ConflictResolver(
    ref.watch(sincronizacionRemoteDataSourceProvider),
  );
});

// ======================================================================
// Estado del sync
// ======================================================================
@immutable
class SyncState {
  final bool sincronizando;
  final int pendientes;
  final ResultadoSync? ultimoResultado;
  final String? error;

  const SyncState({
    this.sincronizando = false,
    this.pendientes = 0,
    this.ultimoResultado,
    this.error,
  });

  SyncState copyWith({
    bool? sincronizando,
    int? pendientes,
    ResultadoSync? ultimoResultado,
    String? error,
    bool clearError = false,
  }) {
    return SyncState(
      sincronizando: sincronizando ?? this.sincronizando,
      pendientes: pendientes ?? this.pendientes,
      ultimoResultado: ultimoResultado ?? this.ultimoResultado,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hayPendientes => pendientes > 0;
  bool get hayConflictos =>
      (ultimoResultado?.conflictos ?? 0) > 0;
}

// ======================================================================
// Notifier del sync
// ======================================================================
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref, this._manager, this._queue)
      : super(const SyncState()) {
    _iniciarContadorPeriodico();
    _escucharConectividad();
  }

  final Ref _ref;
  final SyncManager _manager;
  final SyncQueue _queue;

  Timer? _contadorTimer;
  StreamSubscription? _conectividadSub;

  // ==================================================================
  // Contador periódico de pendientes (cada 5s)
  // ==================================================================
  void _iniciarContadorPeriodico() {
    _contadorTimer?.cancel();
    _actualizarContador();
    _contadorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _actualizarContador(),
    );
  }

  Future<void> _actualizarContador() async {
    try {
      final n = await _queue.contarPendientes();
      if (mounted) {
        state = state.copyWith(pendientes: n);
      }
    } catch (_) {}
  }

  // ==================================================================
  // Auto-sync al recuperar conexión
  // ==================================================================
  void _escucharConectividad() {
    final connectivity = _ref.read(connectivityServiceProvider);

    _conectividadSub = connectivity.stream.listen((info) {
      if (info.isOnline) {
        // Esperar un poco para que la red se estabilice
        Future.delayed(const Duration(seconds: 2), () {
          sincronizarTodo();
        });
      }
    });
  }

  @override
  void dispose() {
    _contadorTimer?.cancel();
    _conectividadSub?.cancel();
    super.dispose();
  }

  // ==================================================================
  // Acciones
  // ==================================================================
  Future<ResultadoSync> sincronizarDiagrama(int idDiagrama) async {
    state = state.copyWith(sincronizando: true, clearError: true);
    try {
      final result = await _manager.sincronizarDiagrama(idDiagrama);
      state = state.copyWith(
        sincronizando: false,
        ultimoResultado: result,
      );
      await _actualizarContador();
      return result;
    } catch (e) {
      state = state.copyWith(
        sincronizando: false,
        error: e.toString(),
      );
      await _actualizarContador();
      rethrow;
    }
  }

  Future<ResultadoSync> sincronizarTodo() async {
    if (state.sincronizando) return ResultadoSync.vacio;

    state = state.copyWith(sincronizando: true, clearError: true);
    try {
      final result = await _manager.sincronizarTodo();
      state = state.copyWith(
        sincronizando: false,
        ultimoResultado: result,
      );
      await _actualizarContador();
      return result;
    } catch (e) {
      state = state.copyWith(
        sincronizando: false,
        error: e.toString(),
      );
      await _actualizarContador();
      rethrow;
    }
  }

  Future<void> refrescarContador() => _actualizarContador();
}

final syncProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(
    ref,
    ref.watch(syncManagerProvider),
    ref.watch(syncQueueProvider),
  );
});

// ======================================================================
// Selectores
// ======================================================================
final pendientesSyncProvider = Provider<int>((ref) {
  return ref.watch(syncProvider).pendientes;
});

final estaSincronizandoProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider).sincronizando;
});