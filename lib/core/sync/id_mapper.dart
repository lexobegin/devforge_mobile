// lib/core/sync/id_mapper.dart
//
// Mapeo de IDs temporales (locales, negativos) a IDs reales del backend
// tras una sincronización exitosa.
//
// Cuando creamos una clase offline, se le asigna un id temporal negativo
// (`-timestamp`). Al sincronizar, el backend devuelve el id real. Este
// servicio aplica ese mapeo sobre el diagramaProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/diagrama_editor/presentation/providers/diagrama_provider.dart';

class IdMapper {
  IdMapper(this._ref);

  final Ref _ref;

  // ==================================================================
  // Aplicar el mapeo de ids tras un batch exitoso
  // ==================================================================
  // Recibe un mapa { id_temporal_local: id_real } y busca en el estado
  // del diagrama las clases con ids negativos que correspondan. Los
  // actualiza con el id real.
  //
  // Nota: como el id temporal local es un string (tmp-xxx), necesitamos
  // una forma de asociarlo con la clase local. Por ahora, usamos el
  // orden de creación: la primera clase con id negativo se mapea al
  // primer id real. Es una heurística suficiente para esta versión.
  Future<void> aplicarMapeo({
    required int idDiagrama,
    required Map<String, int> mapeo,
  }) async {
    if (mapeo.isEmpty) return;

    final notifier = _ref.read(diagramaProvider.notifier);
    await notifier.aplicarMapeoIds(mapeo);
  }
}

final idMapperProvider = Provider<IdMapper>((ref) {
  return IdMapper(ref);
});