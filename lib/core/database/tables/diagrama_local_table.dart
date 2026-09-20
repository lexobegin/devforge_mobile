// lib/core/database/tables/diagrama_local_table.dart
//
// Tabla local de diagramas.
//
// Espeja la metadata del diagrama del backend. Guardamos solo lo esencial
// para que el editor pueda abrir el diagrama offline.

import 'package:drift/drift.dart';

@DataClassName('DiagramaLocal')
class DiagramasLocales extends Table {
  /// ID del backend.
  IntColumn get id => integer()();

  IntColumn get idProyecto => integer().named('id_proyecto')();

  TextColumn get nombre => text().withLength(min: 1, max: 150)();

  TextColumn get versionUml =>
      text().named('version_uml').withDefault(const Constant('2.5.1'))();

  IntColumn get numeroVersion =>
      integer().named('numero_version').withDefault(const Constant(1))();

  IntColumn get idCreador => integer().named('id_creador')();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  /// Timestamp local de última modificación (para detectar cambios sin
  /// sincronizar).
  DateTimeColumn get localUpdatedAt =>
      dateTime().named('local_updated_at').withDefault(currentDateAndTime)();

  /// Indica si el diagrama fue eliminado localmente pero todavía no se
  /// propagó al backend.
  BoolColumn get pendingDelete =>
      boolean().named('pending_delete').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}