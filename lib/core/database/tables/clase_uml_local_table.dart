// lib/core/database/tables/clase_uml_local_table.dart
//
// Tabla local de clases UML.
//
// Los atributos y operaciones NO tienen tabla propia: se guardan como
// JSON embebido dentro de la clase (columna `atributos_json`,
// `operaciones_json`). Es una decisión deliberada: el editor siempre lee
// la clase completa, y esto simplifica muchísimo las queries offline.

import 'package:drift/drift.dart';

@DataClassName('ClaseUmlLocal')
class ClasesUmlLocales extends Table {
  /// ID del backend.
  IntColumn get id => integer()();

  IntColumn get idDiagrama => integer().named('id_diagrama')();

  TextColumn get nombre => text().withLength(min: 1, max: 150)();

  BoolColumn get esAbstracta =>
      boolean().named('es_abstracta').withDefault(const Constant(false))();

  TextColumn get estereotipo =>
      text().nullable().withLength(min: 1, max: 50)();

  RealColumn get posX => real().named('pos_x').withDefault(const Constant(0))();

  RealColumn get posY => real().named('pos_y').withDefault(const Constant(0))();

  IntColumn get idCreador => integer().named('id_creador')();

  /// Atributos serializados como JSON.
  TextColumn get atributosJson =>
      text().named('atributos_json').withDefault(const Constant('[]'))();

  /// Operaciones serializadas como JSON.
  TextColumn get operacionesJson =>
      text().named('operaciones_json').withDefault(const Constant('[]'))();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();

  DateTimeColumn get localUpdatedAt =>
      dateTime().named('local_updated_at').withDefault(currentDateAndTime)();

  /// ID temporal local (para clases creadas offline que todavía no
  /// tienen un ID real del backend).
  TextColumn get idTemporalLocal =>
      text().named('id_temporal_local').nullable()();

  BoolColumn get pendingDelete =>
      boolean().named('pending_delete').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}