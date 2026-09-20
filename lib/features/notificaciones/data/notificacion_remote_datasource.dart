// lib/features/notificaciones/data/notificacion_remote_datasource.dart
//
// Datasource remoto de notificaciones.

import '../../../core/network/api_client.dart';
//import '../../domain/notificacion_entity.dart';
import '../domain/notificacion_entity.dart';
import 'notificacion_model.dart';

class NotificacionRemoteDataSource {
  NotificacionRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Consultas
  // ==================================================================
  Future<List<Notificacion>> listar({
    bool soloNoLeidas = false,
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/notificaciones',
      query: {
        'solo_no_leidas': soloNoLeidas,
        'skip': skip,
        'limit': limit,
      },
    );
    return json
        .map((n) =>
            NotificacionModel.fromJson((n as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<ContadorNoLeidas> contador() async {
    final json = await _client.get<Map<String, dynamic>>(
      '/notificaciones/contador',
    );
    return NotificacionModel.contadorFromJson(json);
  }

  Future<Notificacion> obtener(int id) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/notificaciones/$id',
    );
    return NotificacionModel.fromJson(json);
  }

  // ==================================================================
  // Acciones
  // ==================================================================
  Future<int> marcarVariasLeidas({
    List<int>? ids,
    bool todas = false,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/notificaciones/marcar-leidas',
      body: {
        if (ids != null && ids.isNotEmpty) 'ids': ids,
        'todas': todas,
      },
    );
    return (json['actualizadas'] as num?)?.toInt() ?? 0;
  }

  Future<Notificacion> marcarLeida(int id) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/notificaciones/$id/leer',
    );
    return NotificacionModel.fromJson(json);
  }

  Future<Notificacion> marcarNoLeida(int id) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/notificaciones/$id/no-leer',
    );
    return NotificacionModel.fromJson(json);
  }

  Future<void> eliminar(int id) async {
    await _client.delete<void>('/notificaciones/$id');
  }

  Future<int> limpiarLeidas() async {
    final json = await _client.delete<Map<String, dynamic>>(
      '/notificaciones/leidas',
    );
    return (json['eliminadas'] as num?)?.toInt() ?? 0;
  }
}