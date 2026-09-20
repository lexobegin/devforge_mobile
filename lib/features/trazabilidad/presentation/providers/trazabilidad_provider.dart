// lib/features/trazabilidad/presentation/providers/trazabilidad_provider.dart
//
// Providers de trazabilidad: historial, versiones y comentarios.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/trazabilidad_remote_datasource.dart';
import '../../data/trazabilidad_repository.dart';
import '../../domain/trazabilidad_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final trazabilidadRemoteDataSourceProvider =
    Provider<TrazabilidadRemoteDataSource>((ref) {
  return TrazabilidadRemoteDataSource(ref.watch(apiClientProvider));
});

final trazabilidadRepositoryProvider =
    Provider<TrazabilidadRepository>((ref) {
  return TrazabilidadRepository(
    ref.watch(trazabilidadRemoteDataSourceProvider),
  );
});

// ======================================================================
// Versiones
// ======================================================================
final versionesProvider = FutureProvider.family<
    List<VersionDiagramaResumen>, int>((ref, diagramaId) async {
  final repo = ref.watch(trazabilidadRepositoryProvider);
  return repo.listarVersiones(diagramaId);
});

final versionDetalleProvider =
    FutureProvider.family<VersionDiagrama, int>((ref, versionId) async {
  final repo = ref.watch(trazabilidadRepositoryProvider);
  return repo.obtenerVersion(versionId);
});

// ======================================================================
// Comentarios
// ======================================================================
@immutable
class ComentariosFiltros {
  final bool soloNoResueltos;

  const ComentariosFiltros({this.soloNoResueltos = false});

  ComentariosFiltros copyWith({bool? soloNoResueltos}) {
    return ComentariosFiltros(
      soloNoResueltos: soloNoResueltos ?? this.soloNoResueltos,
    );
  }
}

final comentariosFiltrosProvider =
    StateProvider<ComentariosFiltros>((ref) {
  return const ComentariosFiltros();
});

@immutable
class ComentariosState {
  final List<ComentarioDiagrama> comentarios;
  final bool isLoading;
  final ApiError? error;

  const ComentariosState({
    this.comentarios = const [],
    this.isLoading = false,
    this.error,
  });

  ComentariosState copyWith({
    List<ComentarioDiagrama>? comentarios,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
  }) {
    return ComentariosState(
      comentarios: comentarios ?? this.comentarios,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ComentariosNotifier extends StateNotifier<ComentariosState> {
  ComentariosNotifier(this._repo, this._diagramaId)
      : super(const ComentariosState());

  final TrazabilidadRepository _repo;
  final int _diagramaId;

  Future<void> cargar({bool soloNoResueltos = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.listarComentarios(
        _diagramaId,
        soloNoResueltos: soloNoResueltos,
      );
      state = ComentariosState(comentarios: items);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
    }
  }

  Future<void> crear({
    required String texto,
    String? tipoEntidad,
    int? idEntidad,
  }) async {
    final comentario = await _repo.crearComentario(
      _diagramaId,
      texto: texto,
      tipoEntidad: tipoEntidad,
      idEntidad: idEntidad,
    );
    state = state.copyWith(
      comentarios: [comentario, ...state.comentarios],
    );
  }

  Future<void> toggleResuelto(ComentarioDiagrama comentario) async {
    final actualizado = await _repo.actualizarComentario(
      comentario.id,
      resuelto: !comentario.resuelto,
    );
    state = state.copyWith(
      comentarios: state.comentarios
          .map((c) => c.id == comentario.id ? actualizado : c)
          .toList(),
    );
  }

  Future<void> eliminar(int id) async {
    await _repo.eliminarComentario(id);
    state = state.copyWith(
      comentarios: state.comentarios.where((c) => c.id != id).toList(),
    );
  }
}

final comentariosProvider = StateNotifierProvider.family<ComentariosNotifier,
    ComentariosState, int>((ref, diagramaId) {
  return ComentariosNotifier(
    ref.watch(trazabilidadRepositoryProvider),
    diagramaId,
  );
});