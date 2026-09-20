// lib/core/database/tables/relacion_uml_local_table.dart
//
// Tabla local de relaciones UML.

import 'package:drift/drift.dart';

@DataClassName('RelacionUmlLocal')
class RelacionesUmlLocales extends Table {
  IntColumn get id => integer()();

  IntColumn get idDiagrama => integer().named('id_diagrama')();

  IntColumn get idClaseOrigen => integer().named('id_clase_origen')();

  IntColumn get idClaseDestino => integer().named('id_clase_destino')();

  TextColumn get tipoRelacion => text().named('tipo_relacion')();

  TextColumn get multiplicidadOrigen =>
      text().named('multiplicidad_origen').nullable()();

  TextColumn get multiplicidadDestino =>
      text().named('multiplicidad_destino').nullable()();

  TextColumn get nombreAsociacion =>
      text().named('nombre_asociacion').nullable()();

  TextColumn get rolOrigen => text().named('rol_origen').nullable()();

  TextColumn get rolDestino => text().named('rol_destino').nullable()();

  DateTimeColumn get localUpdatedAt =>
      dateTime().named('local_updated_at').withDefault(currentDateAndTime)();

  TextColumn get idTemporalLocal =>
      text().named('id_temporal_local').nullable()();

  BoolColumn get pendingDelete =>
      boolean().named('pending_delete').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}