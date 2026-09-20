// lib/features/intercambio/data/intercambio_remote_datasource.dart
//
// Datasource remoto de intercambio (export/import XMI/XML).

import 'dart:io';

import '../../../core/network/api_client.dart';
//import '../../domain/intercambio_entity.dart';
import '../domain/intercambio_entity.dart';
import 'intercambio_model.dart';

import 'package:dio/dio.dart';

class IntercambioRemoteDataSource {
  IntercambioRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Exportar
  // ==================================================================
  Future<ExportacionResultado> exportar(
    int diagramaId, {
    FormatoIntercambio formato = FormatoIntercambio.xmi,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/intercambio/diagramas/$diagramaId/exportar',
      query: {'formato': formato.value},
    );
    return IntercambioModel.exportacionResultadoFromJson(json);
  }

  Future<List<ExportacionDiagrama>> listarExportaciones(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/intercambio/diagramas/$diagramaId/exportaciones',
      query: {'skip': skip, 'limit': limit},
    );
    return json
        .map((e) => IntercambioModel.exportacionFromJson(
              (e as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  // ==================================================================
  // Importar
  // ==================================================================
  /// Sube un archivo XMI/XML al backend y lo aplica al diagrama.
  /// Usa `upload` de ApiClient, que arma el multipart con el campo
  /// "archivo" y los extraFields.
  Future<ImportacionResultado> importar(
    int diagramaId, {
    required File archivo,
    FormatoIntercambio formato = FormatoIntercambio.xmi,
  }) async {
    final formData = FormData.fromMap({
      'archivo': await MultipartFile.fromFile(archivo.path),
      'formato': formato.value,
    });

    final json = await _client.dio
        .post<Map<String, dynamic>>(
          '/intercambio/diagramas/$diagramaId/importar',
          data: formData,
        )
        .then((r) => r.data ?? <String, dynamic>{});

    return IntercambioModel.importacionResultadoFromJson(json);
  }

  Future<List<ImportacionDiagrama>> listarImportaciones(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/intercambio/diagramas/$diagramaId/importaciones',
      query: {'skip': skip, 'limit': limit},
    );
    return json
        .map((e) => IntercambioModel.importacionFromJson(
              (e as Map).cast<String, dynamic>(),
            ))
        .toList();
  }
}