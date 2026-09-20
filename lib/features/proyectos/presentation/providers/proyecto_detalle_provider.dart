// lib/features/proyectos/presentation/providers/proyecto_detalle_provider.dart
//
// Provider del proyecto activo (detalle) y sus miembros.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../data/proyecto_repository.dart';
import '../../domain/proyecto_entity.dart';
import 'proyectos_provider.dart';

// ======================================================================
// Estado del detalle
// ======================================================================
@immutable
class ProyectoDetalleState {
  final ProyectoConMiembros? proyecto;
  final bool isLoading;
  final ApiError? error;

  const ProyectoDetalleState({
    this.proyecto,
    this.isLoading = false,
    this.error,
  });

  ProyectoDetalleState copyWith({
    ProyectoConMiembros? proyecto,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
    bool clearProyecto = false,
  }) {
    return ProyectoDetalleState(
      proyecto: clearProyecto ? null : (proyecto ?? this.proyecto),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ======================================================================
// Notifier
// ======================================================================
class ProyectoDetalleNotifier extends StateNotifier<ProyectoDetalleState> {
  ProyectoDetalleNotifier(this._repo)
      : super(const ProyectoDetalleState());

  final ProyectoRepository _repo;

  // ==================================================================
  // Cargar
  // ==================================================================
  Future<void> cargar(int proyectoId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final proyecto = await _repo.obtener(proyectoId);
      state = ProyectoDetalleState(proyecto: proyecto);
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
  // Miembros
  // ==================================================================
  Future<MiembroProyecto> agregarMiembro({
    required int idUsuario,
    RolEnProyecto rol = RolEnProyecto.editor,
  }) async {
    final proyecto = state.proyecto;
    if (proyecto == null) {
      throw StateError('No hay proyecto activo');
    }
    final miembro = await _repo.agregarMiembro(
      proyecto.proyecto.id,
      idUsuario: idUsuario,
      rol: rol,
    );
    state = state.copyWith(
      proyecto: ProyectoConMiembros(
        proyecto: proyecto.proyecto,
        miembros: [...proyecto.miembros, miembro],
      ),
    );
    return miembro;
  }

  Future<void> cambiarRolMiembro(
    int miembroId, {
    required RolEnProyecto rol,
  }) async {
    final proyecto = state.proyecto;
    if (proyecto == null) return;

    final actualizado = await _repo.cambiarRolMiembro(
      proyecto.proyecto.id,
      miembroId,
      rol: rol,
    );
    state = state.copyWith(
      proyecto: ProyectoConMiembros(
        proyecto: proyecto.proyecto,
        miembros: proyecto.miembros
            .map((m) => m.id == miembroId ? actualizado : m)
            .toList(),
      ),
    );
  }

  Future<void> quitarMiembro(int miembroId) async {
    final proyecto = state.proyecto;
    if (proyecto == null) return;

    await _repo.quitarMiembro(proyecto.proyecto.id, miembroId);
    state = state.copyWith(
      proyecto: ProyectoConMiembros(
        proyecto: proyecto.proyecto,
        miembros:
            proyecto.miembros.where((m) => m.id != miembroId).toList(),
      ),
    );
  }

  // ==================================================================
  // Limpiar
  // ==================================================================
  void limpiar() => state = const ProyectoDetalleState();
  void limpiarError() => state = state.copyWith(clearError: true);
}

// ======================================================================
// Provider principal
// ======================================================================
final proyectoDetalleProvider = StateNotifierProvider<
    ProyectoDetalleNotifier, ProyectoDetalleState>((ref) {
  return ProyectoDetalleNotifier(
    ref.watch(proyectoRepositoryProvider),
  );
});