// lib/features/proyectos/presentation/providers/proyectos_provider.dart
//
// Provider del listado de proyectos.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/proyecto_remote_datasource.dart';
import '../../data/proyecto_repository.dart';
import '../../domain/proyecto_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final proyectoRemoteDataSourceProvider =
    Provider<ProyectoRemoteDataSource>((ref) {
  return ProyectoRemoteDataSource(ref.watch(apiClientProvider));
});

final proyectoRepositoryProvider = Provider<ProyectoRepository>((ref) {
  return ProyectoRepository(ref.watch(proyectoRemoteDataSourceProvider));
});

// ======================================================================
// Filtros
// ======================================================================
@immutable
class ProyectosFiltros {
  final bool incluirArchivados;

  const ProyectosFiltros({
    this.incluirArchivados = false,
  });

  ProyectosFiltros copyWith({bool? incluirArchivados}) {
    return ProyectosFiltros(
      incluirArchivados: incluirArchivados ?? this.incluirArchivados,
    );
  }
}

final proyectosFiltrosProvider =
    StateProvider<ProyectosFiltros>((ref) {
  return const ProyectosFiltros();
});

// ======================================================================
// Lista de proyectos
// ======================================================================
@immutable
class ProyectosState {
  final List<Proyecto> proyectos;
  final bool isLoading;
  final ApiError? error;

  const ProyectosState({
    this.proyectos = const [],
    this.isLoading = false,
    this.error,
  });

  ProyectosState copyWith({
    List<Proyecto>? proyectos,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
  }) {
    return ProyectosState(
      proyectos: proyectos ?? this.proyectos,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get total => proyectos.length;
}

class ProyectosNotifier extends StateNotifier<ProyectosState> {
  ProyectosNotifier(this._repo) : super(const ProyectosState());

  final ProyectoRepository _repo;

  // ==================================================================
  // Cargar
  // ==================================================================
  Future<void> cargar({bool incluirArchivados = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.listar(
        incluirArchivados: incluirArchivados,
      );
      state = ProyectosState(proyectos: items, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(
          status: e.status,
          code: e.code,
          detail: e.detail,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError.unknown(e.toString()),
      );
    }
  }

  // ==================================================================
  // Crear
  // ==================================================================
  Future<Proyecto> crear({
    required String nombre,
    String? descripcion,
  }) async {
    final proyecto = await _repo.crear(
      nombre: nombre,
      descripcion: descripcion,
    );
    state = state.copyWith(
      proyectos: [proyecto, ...state.proyectos],
    );
    return proyecto;
  }

  // ==================================================================
  // Actualizar (parcial)
  // ==================================================================
  Future<Proyecto> actualizar(
    int id, {
    String? nombre,
    String? descripcion,
    EstadoProyecto? estado,
  }) async {
    final actualizado = await _repo.actualizar(
      id,
      nombre: nombre,
      descripcion: descripcion,
      estado: estado,
    );
    state = state.copyWith(
      proyectos: state.proyectos
          .map((p) => p.id == id ? actualizado : p)
          .toList(),
    );
    return actualizado;
  }

  // ==================================================================
  // Archivar / reactivar
  // ==================================================================
  Future<void> archivar(int id) async {
    final actualizado = await _repo.archivar(id);
    state = state.copyWith(
      proyectos: state.proyectos
          .map((p) => p.id == id ? actualizado : p)
          .toList(),
    );
  }

  Future<void> reactivar(int id) async {
    final actualizado = await _repo.reactivar(id);
    state = state.copyWith(
      proyectos: state.proyectos
          .map((p) => p.id == id ? actualizado : p)
          .toList(),
    );
  }

  // ==================================================================
  // Eliminar
  // ==================================================================
  Future<void> eliminar(int id) async {
    await _repo.eliminar(id);
    state = state.copyWith(
      proyectos: state.proyectos.where((p) => p.id != id).toList(),
    );
  }

  // ==================================================================
  // Limpiar
  // ==================================================================
  void limpiarError() => state = state.copyWith(clearError: true);

  void limpiar() => state = const ProyectosState();
}

// ======================================================================
// Provider principal
// ======================================================================
final proyectosProvider =
    StateNotifierProvider<ProyectosNotifier, ProyectosState>((ref) {
  return ProyectosNotifier(ref.watch(proyectoRepositoryProvider));
});