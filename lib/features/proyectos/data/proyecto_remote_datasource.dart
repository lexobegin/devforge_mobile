// lib/features/proyectos/data/proyecto_remote_datasource.dart
//
// Datasource remoto de proyectos.
//
// Habla con los endpoints de proyectos del backend.

import '../../../core/network/api_client.dart';
//import '../../domain/proyecto_entity.dart';
import '../domain/proyecto_entity.dart';
import 'proyecto_model.dart';

class ProyectoRemoteDataSource {
  ProyectoRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Proyectos
  // ==================================================================

  /// Lista los proyectos del usuario con paginación.
  Future<List<Proyecto>> listar({
    int skip = 0,
    int limit = 50,
    bool incluirArchivados = false,
    bool todos = false,
  }) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/proyectos',
      query: {
        'skip': skip,
        'limit': limit,
        'incluir_archivados': incluirArchivados,
        'todos': todos,
      },
    );

    final items = (json['items'] as List?) ?? [];
    return items
        .map((p) => ProyectoModel.fromJson((p as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Crea un proyecto.
  Future<Proyecto> crear({
    required String nombre,
    String? descripcion,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/proyectos',
      body: ProyectoModel.toCreateJson(
        nombre: nombre,
        descripcion: descripcion,
      ),
    );
    return ProyectoModel.fromJson(json);
  }

  /// Obtiene un proyecto con sus miembros.
  Future<ProyectoConMiembros> obtener(int id) async {
    final json = await _client.get<Map<String, dynamic>>('/proyectos/$id');
    return ProyectoConMiembrosModel.fromJson(json);
  }

  /// Actualiza un proyecto.
  Future<Proyecto> actualizar(
    int id, {
    String? nombre,
    String? descripcion,
    EstadoProyecto? estado,
  }) async {
    final json = await _client.put<Map<String, dynamic>>(
      '/proyectos/$id',
      body: ProyectoModel.toUpdateJson(
        nombre: nombre,
        descripcion: descripcion,
        estado: estado,
      ),
    );
    return ProyectoModel.fromJson(json);
  }

  /// Archiva un proyecto.
  Future<Proyecto> archivar(int id) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/proyectos/$id/archivar',
    );
    return ProyectoModel.fromJson(json);
  }

  /// Reactiva un proyecto archivado.
  Future<Proyecto> reactivar(int id) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/proyectos/$id/reactivar',
    );
    return ProyectoModel.fromJson(json);
  }

  /// Elimina un proyecto.
  Future<void> eliminar(int id) async {
    await _client.delete<void>('/proyectos/$id');
  }

  // ==================================================================
  // Miembros
  // ==================================================================

  Future<List<MiembroProyecto>> listarMiembros(int proyectoId) async {
    final json = await _client.get<List<dynamic>>(
      '/proyectos/$proyectoId/miembros',
    );
    return json
        .map((m) =>
            MiembroProyectoModel.fromJson((m as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<MiembroProyecto> agregarMiembro(
    int proyectoId, {
    required int idUsuario,
    RolEnProyecto rol = RolEnProyecto.editor,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/proyectos/$proyectoId/miembros',
      body: {
        'id_usuario': idUsuario,
        'rol_en_proyecto': rol.value,
      },
    );
    return MiembroProyectoModel.fromJson(json);
  }

  Future<MiembroProyecto> cambiarRolMiembro(
    int proyectoId,
    int miembroId, {
    required RolEnProyecto rol,
  }) async {
    final json = await _client.put<Map<String, dynamic>>(
      '/proyectos/$proyectoId/miembros/$miembroId',
      body: {'rol_en_proyecto': rol.value},
    );
    return MiembroProyectoModel.fromJson(json);
  }

  Future<void> quitarMiembro(int proyectoId, int miembroId) async {
    await _client.delete<void>(
      '/proyectos/$proyectoId/miembros/$miembroId',
    );
  }
}