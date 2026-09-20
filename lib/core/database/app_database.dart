// lib/core/database/app_database.dart
//
// Base de datos local SQLite (drift).
//
// - Define todas las tablas y las expone con DAOs tipados.
// - Configura la ruta del archivo en el dispositivo.
// - Se abre en modo lazy: la primera consulta inicializa la BD.
//
// Al modificar la estructura de las tablas, hay que:
//   1) Incrementar `schemaVersion`.
//   2) Agregar la migración correspondiente en `migration`.
//   3) Correr `flutter pub run build_runner build --delete-conflicting-outputs`.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/clase_uml_local_table.dart';
import 'tables/cola_sincronizacion_table.dart';
import 'tables/diagrama_local_table.dart';
import 'tables/relacion_uml_local_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    DiagramasLocales,
    ClasesUmlLocales,
    RelacionesUmlLocales,
    ColaSincronizacion,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor para tests (base de datos en memoria).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Las migraciones futuras van aquí:
          //
          // if (from < 2) {
          //   await m.addColumn(diagramasLocales, diagramasLocales.nuevaColumna);
          // }
        },
        beforeOpen: (details) async {
          // Habilitar foreign keys (no lo usamos todavía porque no
          // declaramos FKs, pero es buena práctica).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ==================================================================
  // DAOs / Queries
  // ==================================================================
  // Diagramas
  // ------------------------------------------------------------------
  Future<List<DiagramaLocal>> listarDiagramas() {
    return (select(diagramasLocales)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<DiagramaLocal>> listarDiagramasPorProyecto(int idProyecto) {
    return (select(diagramasLocales)
          ..where((t) => t.idProyecto.equals(idProyecto))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<DiagramaLocal?> obtenerDiagrama(int id) {
    return (select(diagramasLocales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertDiagrama(DiagramasLocalesCompanion data) {
    return into(diagramasLocales).insertOnConflictUpdate(data);
  }

  Future<void> eliminarDiagrama(int id) {
    return (delete(diagramasLocales)..where((t) => t.id.equals(id))).go();
  }

  // ------------------------------------------------------------------
  // Clases
  // ------------------------------------------------------------------
  Future<List<ClaseUmlLocal>> listarClases(int idDiagrama) {
    return (select(clasesUmlLocales)
          ..where((t) => t.idDiagrama.equals(idDiagrama))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<ClaseUmlLocal?> obtenerClase(int id) {
    return (select(clasesUmlLocales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertClase(ClasesUmlLocalesCompanion data) {
    return into(clasesUmlLocales).insertOnConflictUpdate(data);
  }

  Future<void> upsertClases(List<ClasesUmlLocalesCompanion> data) {
    return batch((b) => b.insertAllOnConflictUpdate(clasesUmlLocales, data));
  }

  Future<void> eliminarClase(int id) {
    return (delete(clasesUmlLocales)..where((t) => t.id.equals(id))).go();
  }

  Future<void> eliminarClasesPorDiagrama(int idDiagrama) {
    return (delete(clasesUmlLocales)
          ..where((t) => t.idDiagrama.equals(idDiagrama)))
        .go();
  }

  // ------------------------------------------------------------------
  // Relaciones
  // ------------------------------------------------------------------
  Future<List<RelacionUmlLocal>> listarRelaciones(int idDiagrama) {
    return (select(relacionesUmlLocales)
          ..where((t) => t.idDiagrama.equals(idDiagrama)))
        .get();
  }

  Future<RelacionUmlLocal?> obtenerRelacion(int id) {
    return (select(relacionesUmlLocales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertRelacion(RelacionesUmlLocalesCompanion data) {
    return into(relacionesUmlLocales).insertOnConflictUpdate(data);
  }

  Future<void> upsertRelaciones(List<RelacionesUmlLocalesCompanion> data) {
    return batch(
      (b) => b.insertAllOnConflictUpdate(relacionesUmlLocales, data),
    );
  }

  Future<void> eliminarRelacion(int id) {
    return (delete(relacionesUmlLocales)..where((t) => t.id.equals(id))).go();
  }

  Future<void> eliminarRelacionesPorDiagrama(int idDiagrama) {
    return (delete(relacionesUmlLocales)
          ..where((t) => t.idDiagrama.equals(idDiagrama)))
        .go();
  }

  // ------------------------------------------------------------------
  // Cola de sincronización
  // ------------------------------------------------------------------
  Future<int> encolarCambio(ColaSincronizacionCompanion data) {
    return into(colaSincronizacion).insert(data);
  }

  Future<List<ColaSincronizacionLocal>> pendientesPorDiagrama(
    int idDiagrama,
  ) {
    return (select(colaSincronizacion)
          ..where((t) => t.idDiagrama.equals(idDiagrama))
          ..where(
            (t) =>
                t.estado.equals('PENDIENTE') | t.estado.equals('FALLIDO'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timestampLocal)]))
        .get();
  }

  Future<List<ColaSincronizacionLocal>> todosLosPendientes() {
    return (select(colaSincronizacion)
          ..where(
            (t) =>
                t.estado.equals('PENDIENTE') | t.estado.equals('FALLIDO'),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timestampLocal)]))
        .get();
  }

  Future<int> contarPendientes() async {
    final count = countAll();
    final query = (selectOnly(colaSincronizacion)..addColumns([count]))
      ..where(
        colaSincronizacion.estado.equals('PENDIENTE') |
            colaSincronizacion.estado.equals('FALLIDO'),
      );
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<void> marcarEnviado(int localId) {
    return (update(colaSincronizacion)
          ..where((t) => t.localId.equals(localId)))
        .write(
      const ColaSincronizacionCompanion(estado: Value('ENVIADO')),
    );
  }

  Future<void> marcarConflicto(int localId, String motivo) {
    return (update(colaSincronizacion)
          ..where((t) => t.localId.equals(localId)))
        .write(
      ColaSincronizacionCompanion(
        estado: const Value('CONFLICTO'),
        ultimoError: Value(motivo),
      ),
    );
  }

  Future<void> marcarFallido(int localId, String error) {
    return (update(colaSincronizacion)
          ..where((t) => t.localId.equals(localId)))
        .write(
      ColaSincronizacionCompanion(
        estado: const Value('FALLIDO'),
        ultimoError: Value(error),
        intentos: const Value.absent(),
      ),
    );
  }

  Future<void> limpiarEnviados() {
    return (delete(colaSincronizacion)
          ..where((t) => t.estado.equals('ENVIADO')))
        .go();
  }

  Future<void> limpiarPorDiagrama(int idDiagrama) {
    return (delete(colaSincronizacion)
          ..where((t) => t.idDiagrama.equals(idDiagrama)))
        .go();
  }

  // ------------------------------------------------------------------
  // Limpieza total (útil al hacer logout)
  // ------------------------------------------------------------------
  Future<void> limpiarTodo() async {
    await delete(colaSincronizacion).go();
    await delete(relacionesUmlLocales).go();
    await delete(clasesUmlLocales).go();
    await delete(diagramasLocales).go();
  }
}

// ======================================================================
// Conexión a la BD
// ======================================================================
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'devforge_offline.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}