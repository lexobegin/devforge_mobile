// lib/features/proyectos/data/proyecto_repository.dart
//
// Repositorio de proyectos.
//
// Delega en el datasource remoto. En una próxima iteración, esta clase
// puede combinar el datasource remoto con el local (SQLite) para
// soportar offline-first. Por ahora, solo remoto.

//import '../../domain/proyecto_entity.dart';
import '../domain/proyecto_entity.dart';
import 'proyecto_remote_datasource.dart';

class ProyectoRepository {
  ProyectoRepository(this._remote);

  final ProyectoRemoteDataSource _remote;

  // ==================================================================
  // Proyectos
  // ==================================================================
  Future<List<Proyecto>> listar({
    int skip = 0,
    int limit = 50,
    bool incluirArchivados = false,
    bool todos = false,
  }) {
    return _remote.listar(
      skip: skip,
      limit: limit,
      incluirArchivados: incluirArchivados,
      todos: todos,
    );
  }

  Future<Proyecto> crear({
    required String nombre,
    String? descripcion,
  }) {
    return _remote.crear(nombre: nombre, descripcion: descripcion);
  }

  Future<ProyectoConMiembros> obtener(int id) {
    return _remote.obtener(id);
  }

  Future<Proyecto> actualizar(
    int id, {
    String? nombre,
    String? descripcion,
    EstadoProyecto? estado,
  }) {
    return _remote.actualizar(
      id,
      nombre: nombre,
      descripcion: descripcion,
      estado: estado,
    );
  }

  Future<Proyecto> archivar(int id) => _remote.archivar(id);

  Future<Proyecto> reactivar(int id) => _remote.reactivar(id);

  Future<void> eliminar(int id) => _remote.eliminar(id);

  // ==================================================================
  // Miembros
  // ==================================================================
  Future<List<MiembroProyecto>> listarMiembros(int proyectoId) {
    return _remote.listarMiembros(proyectoId);
  }

  Future<MiembroProyecto> agregarMiembro(
    int proyectoId, {
    required int idUsuario,
    RolEnProyecto rol = RolEnProyecto.editor,
  }) {
    return _remote.agregarMiembro(
      proyectoId,
      idUsuario: idUsuario,
      rol: rol,
    );
  }

  Future<MiembroProyecto> cambiarRolMiembro(
    int proyectoId,
    int miembroId, {
    required RolEnProyecto rol,
  }) {
    return _remote.cambiarRolMiembro(
      proyectoId,
      miembroId,
      rol: rol,
    );
  }

  Future<void> quitarMiembro(int proyectoId, int miembroId) {
    return _remote.quitarMiembro(proyectoId, miembroId);
  }
}