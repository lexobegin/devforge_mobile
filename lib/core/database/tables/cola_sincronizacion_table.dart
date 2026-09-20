// lib/core/database/tables/cola_sincronizacion_table.dart
//
// Tabla local de la cola de sincronización.
//
// Cada cambio hecho offline (o que falló por red) se apila aquí. Cuando
// la app recupera conexión, el `SyncManager` la procesa en orden FIFO
// contra el backend.

import 'package:drift/drift.dart';

@DataClassName('ColaSincronizacionLocal')
class ColaSincronizacion extends Table {
  /// ID autogenerado por drift.
  IntColumn get localId => integer().autoIncrement().named('local_id')();

  /// ID temporal local único por operación (para idempotencia).
  TextColumn get idTemporalLocal => text().named('id_temporal_local')();

  IntColumn get idDiagrama => integer().named('id_diagrama')();

  /// Tipo de operación:
  /// CREAR_CLASE, MODIFICAR_CLASE, ELIMINAR_CLASE, AGREGAR_ATRIBUTO, ...
  TextColumn get tipoOperacion => text().named('tipo_operacion')();

  /// Payload serializado como JSON.
  TextColumn get payload => text()();

  /// Timestamp local (ms epoch) — para resolución de conflictos
  /// "último en escribir gana".
  IntColumn get timestampLocal => integer().named('timestamp_local')();

  /// Estado: PENDIENTE, ENVIADO, CONFLICTO, FALLIDO.
  TextColumn get estado =>
      text().withDefault(const Constant('PENDIENTE'))();

  /// Cantidad de intentos.
  IntColumn get intentos => integer().withDefault(const Constant(0))();

  /// Último error registrado (si falló).
  TextColumn get ultimoError => text().named('ultimo_error').nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}