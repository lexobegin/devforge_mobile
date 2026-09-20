// lib/features/intercambio/presentation/providers/intercambio_provider.dart
//
// Provider de intercambio (export/import XMI/XML).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/intercambio_remote_datasource.dart';
import '../../data/intercambio_repository.dart';
import '../../domain/intercambio_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final intercambioRemoteDataSourceProvider =
    Provider<IntercambioRemoteDataSource>((ref) {
  return IntercambioRemoteDataSource(ref.watch(apiClientProvider));
});

final intercambioRepositoryProvider = Provider<IntercambioRepository>((ref) {
  return IntercambioRepository(
    ref.watch(intercambioRemoteDataSourceProvider),
  );
});

// ======================================================================
// Notifier de operación
// ======================================================================
@immutable
class IntercambioState {
  final bool isExporting;
  final bool isImporting;
  final ExportacionResultado? ultimaExportacion;
  final ImportacionResultado? ultimaImportacion;
  final String? error;

  const IntercambioState({
    this.isExporting = false,
    this.isImporting = false,
    this.ultimaExportacion,
    this.ultimaImportacion,
    this.error,
  });

  IntercambioState copyWith({
    bool? isExporting,
    bool? isImporting,
    ExportacionResultado? ultimaExportacion,
    ImportacionResultado? ultimaImportacion,
    String? error,
    bool clearError = false,
    bool clearResultados = false,
  }) {
    return IntercambioState(
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      ultimaExportacion: clearResultados
          ? null
          : (ultimaExportacion ?? this.ultimaExportacion),
      ultimaImportacion: clearResultados
          ? null
          : (ultimaImportacion ?? this.ultimaImportacion),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class IntercambioNotifier extends StateNotifier<IntercambioState> {
  IntercambioNotifier(this._repo) : super(const IntercambioState());

  final IntercambioRepository _repo;

  // ==================================================================
  // Exportar
  // ==================================================================
  Future<ExportacionResultado> exportar(
    int diagramaId, {
    FormatoIntercambio formato = FormatoIntercambio.xmi,
  }) async {
    state = state.copyWith(isExporting: true, clearError: true);
    try {
      final resultado = await _repo.exportar(
        diagramaId,
        formato: formato,
      );
      state = state.copyWith(
        isExporting: false,
        ultimaExportacion: resultado,
      );
      return resultado;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  // ==================================================================
  // Importar
  // ==================================================================
  Future<ImportacionResultado> importar(
    int diagramaId, {
    required File archivo,
    FormatoIntercambio formato = FormatoIntercambio.xmi,
  }) async {
    state = state.copyWith(isImporting: true, clearError: true);
    try {
      final resultado = await _repo.importar(
        diagramaId,
        archivo: archivo,
        formato: formato,
      );
      state = state.copyWith(
        isImporting: false,
        ultimaImportacion: resultado,
      );
      return resultado;
    } catch (e) {
      state = state.copyWith(
        isImporting: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void limpiar() {
    state = const IntercambioState();
  }
}

final intercambioProvider =
    StateNotifierProvider<IntercambioNotifier, IntercambioState>((ref) {
  return IntercambioNotifier(ref.watch(intercambioRepositoryProvider));
});