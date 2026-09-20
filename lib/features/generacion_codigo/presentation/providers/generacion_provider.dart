// lib/features/generacion_codigo/presentation/providers/generacion_provider.dart
//
// Provider de generación de código.
//
// - Dispara generaciones.
// - Hace polling del estado del trabajo hasta que finaliza.
// - Carga el detalle cuando termina exitosamente.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/generacion_remote_datasource.dart';
import '../../data/generacion_repository.dart';
import '../../domain/generacion_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final generacionRemoteDataSourceProvider =
    Provider<GeneracionRemoteDataSource>((ref) {
  return GeneracionRemoteDataSource(ref.watch(apiClientProvider));
});

final generacionRepositoryProvider = Provider<GeneracionRepository>((ref) {
  return GeneracionRepository(
    ref.watch(generacionRemoteDataSourceProvider),
  );
});

// ======================================================================
// Estado del trabajo activo (para polling)
// ======================================================================
@immutable
class TrabajoActivoState {
  final TrabajoGeneracionDetalle? detalle;
  final EstadoGeneracion? estado;
  final bool isLoading;
  final ApiError? error;

  const TrabajoActivoState({
    this.detalle,
    this.estado,
    this.isLoading = false,
    this.error,
  });

  TrabajoActivoState copyWith({
    TrabajoGeneracionDetalle? detalle,
    EstadoGeneracion? estado,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
  }) {
    return TrabajoActivoState(
      detalle: detalle ?? this.detalle,
      estado: estado ?? this.estado,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  TrabajoGeneracion? get trabajo => detalle?.trabajo ?? estado?.let((e) => null);
  EstadoTrabajoGeneracion? get estadoActual =>
      detalle?.trabajo.estado ?? estado?.estado;
  bool get finalizo =>
      estadoActual == EstadoTrabajoGeneracion.exitoso ||
      estadoActual == EstadoTrabajoGeneracion.fallido;
  bool get estaEnCurso =>
      estadoActual == EstadoTrabajoGeneracion.pendiente ||
      estadoActual == EstadoTrabajoGeneracion.enProceso;
}

/// Helper interno
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

// ======================================================================
// Notifier del trabajo activo (polling)
// ======================================================================
class TrabajoActivoNotifier extends StateNotifier<TrabajoActivoState> {
  TrabajoActivoNotifier(this._repo) : super(const TrabajoActivoState());

  final GeneracionRepository _repo;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ==================================================================
  // Disparar una generación
  // ==================================================================
  Future<TrabajoGeneracion> generar(
    int diagramaId, {
    bool incluirPostman = true,
    String? nombreProyecto,
    String? packageBase,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final trabajo = await _repo.generar(
        diagramaId,
        incluirPostman: incluirPostman,
        nombreProyecto: nombreProyecto,
        packageBase: packageBase,
      );
      // Iniciar polling
      seguirTrabajo(trabajo.id);
      return trabajo;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
      rethrow;
    }
  }

  // ==================================================================
  // Seguir un trabajo (polling)
  // ==================================================================
  void seguirTrabajo(int trabajoId) {
    _pollTimer?.cancel();
    state = const TrabajoActivoState(isLoading: true);

    _consultar(trabajoId);

    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _consultar(trabajoId),
    );
  }

  Future<void> _consultar(int trabajoId) async {
    try {
      final estado = await _repo.obtenerEstado(trabajoId);

      if (!mounted) return;

      // Actualizar estado
      state = state.copyWith(estado: estado, isLoading: false);

      // Si finalizó, cargar el detalle y detener el polling
      if (estado.finalizo) {
        _pollTimer?.cancel();
        _pollTimer = null;

        if (estado.estado == EstadoTrabajoGeneracion.exitoso) {
          final detalle = await _repo.obtener(trabajoId);
          if (mounted) {
            state = state.copyWith(detalle: detalle);
          }
        }
      }
    } catch (_) {
      // Silencioso: se reintentará en el próximo tick
    }
  }

  // ==================================================================
  // Detener el polling manualmente
  // ==================================================================
  void detenerPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ==================================================================
  // Limpiar
  // ==================================================================
  void limpiar() {
    detenerPolling();
    state = const TrabajoActivoState();
  }
}

final trabajoActivoProvider =
    StateNotifierProvider.autoDispose<TrabajoActivoNotifier,
        TrabajoActivoState>((ref) {
  return TrabajoActivoNotifier(
    ref.watch(generacionRepositoryProvider),
  );
});

// ======================================================================
// Historial de trabajos de un diagrama
// ======================================================================
final trabajosPorDiagramaProvider = FutureProvider.family<
    List<TrabajoGeneracion>, int>((ref, diagramaId) async {
  final repo = ref.watch(generacionRepositoryProvider);
  return repo.listarPorDiagrama(diagramaId);
});

// ======================================================================
// Descarga del ZIP
// ======================================================================
final descargaProyectoProvider =
    FutureProvider.family<DescargaProyecto, int>((ref, trabajoId) async {
  final repo = ref.watch(generacionRepositoryProvider);
  return repo.obtenerUrlDescarga(trabajoId);
});