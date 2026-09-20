// lib/features/trazabilidad/data/trazabilidad_remote_datasource.dart
//
// Datasource remoto de trazabilidad.

import '../../../core/network/api_client.dart';
//import '../../domain/trazabilidad_entity.dart';
import '../domain/trazabilidad_entity.dart';
import 'trazabilidad_model.dart';

class TrazabilidadRemoteDataSource {
  TrazabilidadRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Historial
  // ==================================================================
  Future<List<HistorialCambio>> listarHistorial(
    int diagramaId, {
    DateTime? desde,
    DateTime? hasta,
    int skip = 0,
    int limit = 100,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/historial',
      query: {
        if (desde != null) 'desde': desde.toIso8601String(),
        if (hasta != null) 'hasta': hasta.toIso8601String(),
        'skip': skip,
        'limit': limit,
      },
    );
    return json
        .map((h) => TrazabilidadModel.historialFromJson(
              (h as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  // ==================================================================
  // Versiones
  // ==================================================================
  Future<List<VersionDiagramaResumen>> listarVersiones(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/versiones',
      query: {'skip': skip, 'limit': limit},
    );
    return json
        .map((v) => TrazabilidadModel.versionResumenFromJson(
              (v as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  Future<VersionDiagrama> guardarVersion(
    int diagramaId, {
    required Map<String, dynamic> contenidoJson,
    String? comentario,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/versiones',
      body: TrazabilidadModel.toGuardarVersionJson(
        contenidoJson: contenidoJson,
        comentario: comentario,
      ),
    );
    return TrazabilidadModel.versionFromJson(json);
  }

  Future<VersionDiagrama> obtenerVersion(int versionId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/trazabilidad/versiones/$versionId',
    );
    return TrazabilidadModel.versionFromJson(json);
  }

  Future<VersionDiagrama?> obtenerUltimaVersion(int diagramaId) async {
    final json = await _client.get<Map<String, dynamic>?>(
      '/trazabilidad/diagramas/$diagramaId/versiones/ultima',
    );
    if (json == null) return null;
    return TrazabilidadModel.versionFromJson(json);
  }

  // ==================================================================
  // Comentarios
  // ==================================================================
  Future<List<ComentarioDiagrama>> listarComentarios(
    int diagramaId, {
    bool soloNoResueltos = false,
    int skip = 0,
    int limit = 100,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/comentarios',
      query: {
        'solo_no_resueltos': soloNoResueltos,
        'skip': skip,
        'limit': limit,
      },
    );
    return json
        .map((c) => TrazabilidadModel.comentarioFromJson(
              (c as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  Future<ComentarioDiagrama> crearComentario(
    int diagramaId, {
    required String texto,
    String? tipoEntidad,
    int? idEntidad,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/trazabilidad/diagramas/$diagramaId/comentarios',
      body: TrazabilidadModel.toCrearComentarioJson(
        texto: texto,
        tipoEntidad: tipoEntidad,
        idEntidad: idEntidad,
      ),
    );
    return TrazabilidadModel.comentarioFromJson(json);
  }

  Future<ComentarioDiagrama> actualizarComentario(
    int comentarioId, {
    String? texto,
    bool? resuelto,
  }) async {
    final json = await _client.put<Map<String, dynamic>>(
      '/trazabilidad/comentarios/$comentarioId',
      body: TrazabilidadModel.toActualizarComentarioJson(
        texto: texto,
        resuelto: resuelto,
      ),
    );
    return TrazabilidadModel.comentarioFromJson(json);
  }

  Future<void> eliminarComentario(int comentarioId) async {
    await _client.delete<void>('/trazabilidad/comentarios/$comentarioId');
  }
}