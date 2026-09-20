// lib/features/sincronizacion/data/sincronizacion_repository.dart
//
// Repositorio de sincronización.

import '../domain/sincronizacion_entity.dart';
import 'sincronizacion_remote_datasource.dart';

class SincronizacionRepository {
  SincronizacionRepository(this._remote);

  final SincronizacionRemoteDataSource _remote;

  Future<BatchSincronizacionResponse> enviarBatch({
    required String idDispositivo,
    required int idDiagrama,
    required List<Map<String, dynamic>> cambios,
  }) {
    return _remote.enviarBatch(
      idDispositivo: idDispositivo,
      idDiagrama: idDiagrama,
      cambios: cambios,
    );
  }

  Future<List<ConflictoSync>> listarConflictos(int idDiagrama) {
    return _remote.listarConflictos(idDiagrama);
  }

  Future<ConflictoSync> resolverConflicto({
    required int conflictoId,
    required String estrategia,
    Map<String, dynamic>? payloadFusionado,
  }) {
    return _remote.resolverConflicto(
      conflictoId: conflictoId,
      estrategia: estrategia,
      payloadFusionado: payloadFusionado,
    );
  }
}