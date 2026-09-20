// lib/features/trazabilidad/data/trazabilidad_repository.dart
//
// Repositorio de trazabilidad.

//import '../../domain/trazabilidad_entity.dart';
import '../domain/trazabilidad_entity.dart';
import 'trazabilidad_remote_datasource.dart';

class TrazabilidadRepository {
  TrazabilidadRepository(this._remote);

  final TrazabilidadRemoteDataSource _remote;

  // Historial
  Future<List<HistorialCambio>> listarHistorial(
    int diagramaId, {
    DateTime? desde,
    DateTime? hasta,
    int skip = 0,
    int limit = 100,
  }) =>
      _remote.listarHistorial(
        diagramaId,
        desde: desde,
        hasta: hasta,
        skip: skip,
        limit: limit,
      );

  // Versiones
  Future<List<VersionDiagramaResumen>> listarVersiones(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listarVersiones(diagramaId, skip: skip, limit: limit);

  Future<VersionDiagrama> guardarVersion(
    int diagramaId, {
    required Map<String, dynamic> contenidoJson,
    String? comentario,
  }) =>
      _remote.guardarVersion(
        diagramaId,
        contenidoJson: contenidoJson,
        comentario: comentario,
      );

  Future<VersionDiagrama> obtenerVersion(int versionId) =>
      _remote.obtenerVersion(versionId);

  Future<VersionDiagrama?> obtenerUltimaVersion(int diagramaId) =>
      _remote.obtenerUltimaVersion(diagramaId);

  // Comentarios
  Future<List<ComentarioDiagrama>> listarComentarios(
    int diagramaId, {
    bool soloNoResueltos = false,
    int skip = 0,
    int limit = 100,
  }) =>
      _remote.listarComentarios(
        diagramaId,
        soloNoResueltos: soloNoResueltos,
        skip: skip,
        limit: limit,
      );

  Future<ComentarioDiagrama> crearComentario(
    int diagramaId, {
    required String texto,
    String? tipoEntidad,
    int? idEntidad,
  }) =>
      _remote.crearComentario(
        diagramaId,
        texto: texto,
        tipoEntidad: tipoEntidad,
        idEntidad: idEntidad,
      );

  Future<ComentarioDiagrama> actualizarComentario(
    int comentarioId, {
    String? texto,
    bool? resuelto,
  }) =>
      _remote.actualizarComentario(
        comentarioId,
        texto: texto,
        resuelto: resuelto,
      );

  Future<void> eliminarComentario(int comentarioId) =>
      _remote.eliminarComentario(comentarioId);
}