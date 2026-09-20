// lib/features/sincronizacion/data/sincronizacion_remote_datasource.dart
//
// Datasource remoto de sincronización.
//
// Expone:
// - enviarBatch: envía la cola offline al backend.
// - listarConflictos: lista los conflictos pendientes de un diagrama.
// - resolverConflicto: aplica una estrategia de resolución.

import '../../../core/network/api_client.dart';
import '../domain/sincronizacion_entity.dart';
import 'sincronizacion_model.dart';

class SincronizacionRemoteDataSource {
  SincronizacionRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Enviar batch de cambios offline
  // ==================================================================
  Future<BatchSincronizacionResponse> enviarBatch({
    required String idDispositivo,
    required int idDiagrama,
    required List<Map<String, dynamic>> cambios,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/sincronizacion/batch',
      body: {
        'id_dispositivo': idDispositivo,
        'id_diagrama': idDiagrama,
        'cambios': cambios,
      },
    );
    return SincronizacionModel.batchResponseFromJson(json);
  }

  // ==================================================================
  // Listar conflictos pendientes
  // ==================================================================
  Future<List<ConflictoSync>> listarConflictos(int idDiagrama) async {
    final json = await _client.get<List<dynamic>>(
      '/sincronizacion/diagramas/$idDiagrama/conflictos',
    );
    return json
        .map((c) => SincronizacionModel.conflictoFromJson(
              (c as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  // ==================================================================
  // Resolver conflicto
  // ==================================================================
  Future<ConflictoSync> resolverConflicto({
    required int conflictoId,
    required String estrategia, // 'OFFLINE' | 'SERVIDOR' | 'FUSIONAR'
    Map<String, dynamic>? payloadFusionado,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/sincronizacion/conflictos/$conflictoId/resolver',
      body: {
        'estrategia': estrategia,
        if (payloadFusionado != null)
          'payload_fusionado': payloadFusionado,
      },
    );
    return SincronizacionModel.conflictoFromJson(json);
  }
}