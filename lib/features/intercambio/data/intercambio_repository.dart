// lib/features/intercambio/data/intercambio_repository.dart
//
// Repositorio de intercambio.

import 'dart:io';

//import '../../domain/intercambio_entity.dart';
import '../domain/intercambio_entity.dart';
import 'intercambio_remote_datasource.dart';

class IntercambioRepository {
  IntercambioRepository(this._remote);

  final IntercambioRemoteDataSource _remote;

  Future<ExportacionResultado> exportar(
    int diagramaId, {
    FormatoIntercambio formato = FormatoIntercambio.xmi,
  }) =>
      _remote.exportar(diagramaId, formato: formato);

  Future<List<ExportacionDiagrama>> listarExportaciones(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listarExportaciones(diagramaId, skip: skip, limit: limit);

  Future<ImportacionResultado> importar(
    int diagramaId, {
    required File archivo,
    FormatoIntercambio formato = FormatoIntercambio.xmi,
  }) =>
      _remote.importar(diagramaId, archivo: archivo, formato: formato);

  Future<List<ImportacionDiagrama>> listarImportaciones(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listarImportaciones(diagramaId, skip: skip, limit: limit);
}