// lib/features/notificaciones/presentation/providers/notificaciones_provider.dart
//
// Provider de notificaciones.
//
// Mantiene la lista de notificaciones del usuario y el contador de no
// leídas. Refresca el contador cada 30 s mediante un Timer.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/notificacion_remote_datasource.dart';
import '../../data/notificacion_repository.dart';
import '../../domain/notificacion_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final notificacionRemoteDataSourceProvider =
    Provider<NotificacionRemoteDataSource>((ref) {
  return NotificacionRemoteDataSource(ref.watch(apiClientProvider));
});

final notificacionRepositoryProvider =
    Provider<NotificacionRepository>((ref) {
  return NotificacionRepository(
    ref.watch(notificacionRemoteDataSourceProvider),
  );
});

// ======================================================================
// Estado
// ======================================================================
@immutable
class NotificacionesState {
  final List<Notificacion> notificaciones;
  final int noLeidas;
  final bool isLoading;
  final ApiError? error;

  const NotificacionesState({
    this.notificaciones = const [],
    this.noLeidas = 0,
    this.isLoading = false,
    this.error,
  });

  NotificacionesState copyWith({
    List<Notificacion>? notificaciones,
    int? noLeidas,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
  }) {
    return NotificacionesState(
      notificaciones: notificaciones ?? this.notificaciones,
      noLeidas: noLeidas ?? this.noLeidas,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get tieneNuevas => noLeidas > 0;
}

// ======================================================================
// Notifier
// ======================================================================
class NotificacionesNotifier extends StateNotifier<NotificacionesState> {
  NotificacionesNotifier(this._repo) : super(const NotificacionesState()) {
    _iniciarPolling();
  }

  final NotificacionRepository _repo;
  Timer? _pollTimer;

  // ==================================================================
  // Polling del contador cada 30s
  // ==================================================================
  void _iniciarPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refrescarContador(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refrescarContador() async {
    try {
      final contador = await _repo.contador();
      if (mounted) {
        state = state.copyWith(noLeidas: contador.total);
      }
    } catch (_) {
      // Silencioso
    }
  }

  // ==================================================================
  // Cargar lista completa
  // ==================================================================
  Future<void> cargar({bool soloNoLeidas = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.listar(soloNoLeidas: soloNoLeidas);
      final contador = await _repo.contador();
      state = NotificacionesState(
        notificaciones: items,
        noLeidas: contador.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError.unknown(e.toString()),
      );
    }
  }

  // ==================================================================
  // Refrescar solo el contador (para badge)
  // ==================================================================
  Future<void> refrescarContador() => _refrescarContador();

  // ==================================================================
  // Marcar una como leída
  // ==================================================================
  Future<void> marcarLeida(int id) async {
    try {
      final actualizada = await _repo.marcarLeida(id);
      state = state.copyWith(
        notificaciones: state.notificaciones
            .map((n) => n.id == id ? actualizada : n)
            .toList(),
        noLeidas: (state.noLeidas - 1).clamp(0, 999999),
      );
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException
            ? ApiError(status: e.status, code: e.code, detail: e.detail)
            : ApiError.unknown(e.toString()),
      );
    }
  }

  Future<void> marcarNoLeida(int id) async {
    try {
      final actualizada = await _repo.marcarNoLeida(id);
      state = state.copyWith(
        notificaciones: state.notificaciones
            .map((n) => n.id == id ? actualizada : n)
            .toList(),
        noLeidas: state.noLeidas + 1,
      );
    } catch (_) {}
  }

  // ==================================================================
  // Marcar todas
  // ==================================================================
  Future<void> marcarTodasLeidas() async {
    try {
      await _repo.marcarVariasLeidas(todas: true);
      state = state.copyWith(
        notificaciones:
            state.notificaciones.map((n) => n.copyWith(leida: true)).toList(),
        noLeidas: 0,
      );
    } catch (e) {
      state = state.copyWith(
        error: e is ApiException
            ? ApiError(status: e.status, code: e.code, detail: e.detail)
            : ApiError.unknown(e.toString()),
      );
    }
  }

  // ==================================================================
  // Eliminar
  // ==================================================================
  Future<void> eliminar(int id) async {
    final notif = state.notificaciones.firstWhere(
      (n) => n.id == id,
      orElse: () => throw StateError('Notificación no encontrada'),
    );

    try {
      await _repo.eliminar(id);
      state = state.copyWith(
        notificaciones:
            state.notificaciones.where((n) => n.id != id).toList(),
        noLeidas: notif.leida
            ? state.noLeidas
            : (state.noLeidas - 1).clamp(0, 999999),
      );
    } catch (_) {}
  }

  // ==================================================================
  // Limpiar leídas
  // ==================================================================
  Future<int> limpiarLeidas() async {
    try {
      final eliminadas = await _repo.limpiarLeidas();
      state = state.copyWith(
        notificaciones:
            state.notificaciones.where((n) => !n.leida).toList(),
      );
      return eliminadas;
    } catch (_) {
      return 0;
    }
  }
}

// ======================================================================
// Provider principal
// ======================================================================
final notificacionesProvider =
    StateNotifierProvider<NotificacionesNotifier, NotificacionesState>((ref) {
  return NotificacionesNotifier(
    ref.watch(notificacionRepositoryProvider),
  );
});

// ======================================================================
// Selector del badge (solo contador)
// ======================================================================
final noLeidasCountProvider = Provider<int>((ref) {
  return ref.watch(notificacionesProvider).noLeidas;
});