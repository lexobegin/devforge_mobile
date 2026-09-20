// lib/features/generacion_codigo/data/generacion_remote_datasource.dart
//
// Datasource remoto de generación de código.

import '../../../core/network/api_client.dart';
//import '../../domain/generacion_entity.dart';
import '../domain/generacion_entity.dart';
import 'generacion_model.dart';

class GeneracionRemoteDataSource {
  GeneracionRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Disparar generación
  // ==================================================================
  Future<TrabajoGeneracion> generar(
    int diagramaId, {
    String? stackDestino,
    bool? incluirPostman,
    String? nombreProyecto,
    String? packageBase,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/generacion/diagramas/$diagramaId/generar',
      body: GeneracionModel.toGenerarJson(
        stackDestino: stackDestino,
        incluirPostman: incluirPostman,
        nombreProyecto: nombreProyecto,
        packageBase: packageBase,
      ),
    );
    return GeneracionModel.trabajoFromJson(json);
  }

  // ==================================================================
  // Consultas
  // ==================================================================
  Future<TrabajoGeneracionDetalle> obtener(int trabajoId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/generacion/trabajos/$trabajoId',
    );
    return GeneracionModel.detalleFromJson(json);
  }

  Future<EstadoGeneracion> obtenerEstado(int trabajoId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/generacion/trabajos/$trabajoId/estado',
    );
    return GeneracionModel.estadoFromJson(json);
  }

  Future<List<TrabajoGeneracion>> listarPorDiagrama(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/generacion/diagramas/$diagramaId/trabajos',
      query: {'skip': skip, 'limit': limit},
    );
    return json
        .map((t) => GeneracionModel.trabajoFromJson(
              (t as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  // ==================================================================
  // Descarga
  // ==================================================================
  Future<DescargaProyecto> obtenerUrlDescarga(int trabajoId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/generacion/trabajos/$trabajoId/descargar',
    );
    return GeneracionModel.descargaFromJson(json);
  }

  /// Descarga el ZIP a la ruta indicada.
  /// La URL absoluta viene de `obtenerUrlDescarga`.
  Future<void> descargarZip({
    required String downloadUrl,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) {
    return _client.download(
      downloadUrl,
      savePath: savePath,
      onProgress: onProgress,
    );
  }
}