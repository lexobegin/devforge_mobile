// lib/features/generacion_codigo/data/generacion_repository.dart
//
// Repositorio de generación de código.

//import '../../domain/generacion_entity.dart';
import '../domain/generacion_entity.dart';
import 'generacion_remote_datasource.dart';

class GeneracionRepository {
  GeneracionRepository(this._remote);

  final GeneracionRemoteDataSource _remote;

  Future<TrabajoGeneracion> generar(
    int diagramaId, {
    String? stackDestino,
    bool? incluirPostman,
    String? nombreProyecto,
    String? packageBase,
  }) =>
      _remote.generar(
        diagramaId,
        stackDestino: stackDestino,
        incluirPostman: incluirPostman,
        nombreProyecto: nombreProyecto,
        packageBase: packageBase,
      );

  Future<TrabajoGeneracionDetalle> obtener(int trabajoId) =>
      _remote.obtener(trabajoId);

  Future<EstadoGeneracion> obtenerEstado(int trabajoId) =>
      _remote.obtenerEstado(trabajoId);

  Future<List<TrabajoGeneracion>> listarPorDiagrama(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listarPorDiagrama(diagramaId, skip: skip, limit: limit);

  Future<DescargaProyecto> obtenerUrlDescarga(int trabajoId) =>
      _remote.obtenerUrlDescarga(trabajoId);

  Future<void> descargarZip({
    required String downloadUrl,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) =>
      _remote.descargarZip(
        downloadUrl: downloadUrl,
        savePath: savePath,
        onProgress: onProgress,
      );
}