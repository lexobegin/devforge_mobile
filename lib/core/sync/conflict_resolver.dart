// lib/core/sync/conflict_resolver.dart
//
// Resolución de conflictos de sincronización.
//
// Cuando el backend reporta un CONFLICTO, el PROPIETARIO del proyecto
// decide cómo resolverlo. Este servicio envía la decisión al backend.

import '../../features/sincronizacion/data/sincronizacion_remote_datasource.dart';
import '../../features/sincronizacion/domain/sincronizacion_entity.dart';
import 'tipos_sync.dart';

class ConflictResolver {
  ConflictResolver(this._remote);

  final SincronizacionRemoteDataSource _remote;

  // ==================================================================
  // Listar conflictos pendientes
  // ==================================================================
  Future<List<ConflictoSync>> listarConflictos(int idDiagrama) {
    return _remote.listarConflictos(idDiagrama);
  }

  // ==================================================================
  // Resolver un conflicto
  // ==================================================================
  Future<ConflictoSync> resolver({
    required int conflictoId,
    required EstrategiaConflicto estrategia,
    Map<String, dynamic>? payloadFusionado,
  }) {
    return _remote.resolverConflicto(
      conflictoId: conflictoId,
      estrategia: estrategia.value,
      payloadFusionado: payloadFusionado,
    );
  }
}