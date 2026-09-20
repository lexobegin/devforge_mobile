// lib/features/notificaciones/data/notificacion_repository.dart
//
// Repositorio de notificaciones.

//import '../../domain/notificacion_entity.dart';
import '../domain/notificacion_entity.dart';
import 'notificacion_remote_datasource.dart';

class NotificacionRepository {
  NotificacionRepository(this._remote);

  final NotificacionRemoteDataSource _remote;

  Future<List<Notificacion>> listar({
    bool soloNoLeidas = false,
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listar(
        soloNoLeidas: soloNoLeidas,
        skip: skip,
        limit: limit,
      );

  Future<ContadorNoLeidas> contador() => _remote.contador();

  Future<Notificacion> obtener(int id) => _remote.obtener(id);

  Future<int> marcarVariasLeidas({List<int>? ids, bool todas = false}) =>
      _remote.marcarVariasLeidas(ids: ids, todas: todas);

  Future<Notificacion> marcarLeida(int id) => _remote.marcarLeida(id);

  Future<Notificacion> marcarNoLeida(int id) => _remote.marcarNoLeida(id);

  Future<void> eliminar(int id) => _remote.eliminar(id);

  Future<int> limpiarLeidas() => _remote.limpiarLeidas();
}