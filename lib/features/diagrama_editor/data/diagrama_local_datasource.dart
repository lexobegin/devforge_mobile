// lib/features/diagrama_editor/data/diagrama_local_datasource.dart
//
// Datasource local del diagrama (SQLite con drift).
//
// Guarda y lee el diagrama completo desde SQLite. Los atributos y
// operaciones se serializan como JSON dentro de la clase.
//
// Este datasource se usa para:
// 1. Cachear el diagrama tras cargarlo del backend (para leer offline).
// 2. Guardar cambios locales mientras estamos offline.

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../domain/clase_uml_entity.dart';
import '../domain/diagrama_entity.dart';
import '../domain/relacion_uml_entity.dart';

class DiagramaLocalDataSource {
  DiagramaLocalDataSource(this._db);

  final AppDatabase _db;

  // ==================================================================
  // Guardar diagrama completo
  // ==================================================================
  Future<void> guardarCompleto(DiagramaCompleto completo) async {
    await _db.transaction(() async {
      // Guardar metadata
      await _db.upsertDiagrama(
        DiagramasLocalesCompanion.insert(
          id: Value(completo.diagrama.id),
          idProyecto: completo.diagrama.idProyecto,
          nombre: completo.diagrama.nombre,
          versionUml: Value(completo.diagrama.versionUml),
          numeroVersion: Value(completo.diagrama.numeroVersion),
          idCreador: completo.diagrama.idCreador,
          createdAt: Value(completo.diagrama.createdAt),
          updatedAt: Value(completo.diagrama.updatedAt),
        ),
      );

      // Limpiar clases y relaciones anteriores
      await _db.eliminarClasesPorDiagrama(completo.diagrama.id);
      await _db.eliminarRelacionesPorDiagrama(completo.diagrama.id);

      // Guardar clases
      if (completo.clases.isNotEmpty) {
        final companions = completo.clases.map((c) {
          return ClasesUmlLocalesCompanion.insert(
            id: Value(c.id),
            idDiagrama: c.idDiagrama,
            nombre: c.nombre,
            esAbstracta: Value(c.esAbstracta),
            estereotipo: Value(c.estereotipo),
            posX: Value(c.posX),
            posY: Value(c.posY),
            idCreador: c.idCreador,
            atributosJson: Value(_encodeAtributos(c.atributos)),
            operacionesJson: Value(_encodeOperaciones(c.operaciones)),
            createdAt: Value(c.createdAt),
            updatedAt: Value(c.updatedAt),
          );
        }).toList();

        await _db.upsertClases(companions);
      }

      // Guardar relaciones
      if (completo.relaciones.isNotEmpty) {
        final companions = completo.relaciones.map((r) {
          return RelacionesUmlLocalesCompanion.insert(
            id: Value(r.id),
            idDiagrama: r.idDiagrama,
            idClaseOrigen: r.idClaseOrigen,
            idClaseDestino: r.idClaseDestino,
            tipoRelacion: r.tipoRelacion.value,
            multiplicidadOrigen: Value(r.multiplicidadOrigen),
            multiplicidadDestino: Value(r.multiplicidadDestino),
            nombreAsociacion: Value(r.nombreAsociacion),
            rolOrigen: Value(r.rolOrigen),
            rolDestino: Value(r.rolDestino),
          );
        }).toList();

        await _db.upsertRelaciones(companions);
      }
    });
  }

  // ==================================================================
  // Leer diagrama completo desde SQLite
  // ==================================================================
  Future<DiagramaCompleto?> obtenerCompleto(int diagramaId) async {
    final diagRow = await _db.obtenerDiagrama(diagramaId);
    if (diagRow == null) return null;

    final clasesRows = await _db.listarClases(diagramaId);
    final relacionesRows = await _db.listarRelaciones(diagramaId);

    return DiagramaCompleto(
      diagrama: Diagrama(
        id: diagRow.id,
        idProyecto: diagRow.idProyecto,
        nombre: diagRow.nombre,
        versionUml: diagRow.versionUml,
        numeroVersion: diagRow.numeroVersion,
        idCreador: diagRow.idCreador,
        createdAt: diagRow.createdAt,
        updatedAt: diagRow.updatedAt,
      ),
      clases: clasesRows.map(_rowToClase).toList(),
      relaciones: relacionesRows.map(_rowToRelacion).toList(),
      interfaces: const [],
    );
  }

  Future<Diagrama?> obtenerMetadata(int diagramaId) async {
    final row = await _db.obtenerDiagrama(diagramaId);
    if (row == null) return null;

    return Diagrama(
      id: row.id,
      idProyecto: row.idProyecto,
      nombre: row.nombre,
      versionUml: row.versionUml,
      numeroVersion: row.numeroVersion,
      idCreador: row.idCreador,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<bool> existe(int diagramaId) async {
    final row = await _db.obtenerDiagrama(diagramaId);
    return row != null;
  }

  // ==================================================================
  // Guardar cambios individuales (offline)
  // ==================================================================
  Future<void> guardarClase(ClaseUml clase) async {
    await _db.upsertClase(
      ClasesUmlLocalesCompanion.insert(
        id: Value(clase.id),
        idDiagrama: clase.idDiagrama,
        nombre: clase.nombre,
        esAbstracta: Value(clase.esAbstracta),
        estereotipo: Value(clase.estereotipo),
        posX: Value(clase.posX),
        posY: Value(clase.posY),
        idCreador: clase.idCreador,
        atributosJson: Value(_encodeAtributos(clase.atributos)),
        operacionesJson: Value(_encodeOperaciones(clase.operaciones)),
        createdAt: Value(clase.createdAt),
        updatedAt: Value(clase.updatedAt),
      ),
    );
  }

  Future<void> eliminarClase(int claseId) async {
    await _db.eliminarClase(claseId);
  }

  Future<void> guardarRelacion(RelacionUml relacion) async {
    await _db.upsertRelacion(
      RelacionesUmlLocalesCompanion.insert(
        id: Value(relacion.id),
        idDiagrama: relacion.idDiagrama,
        idClaseOrigen: relacion.idClaseOrigen,
        idClaseDestino: relacion.idClaseDestino,
        tipoRelacion: relacion.tipoRelacion.value,
        multiplicidadOrigen: Value(relacion.multiplicidadOrigen),
        multiplicidadDestino: Value(relacion.multiplicidadDestino),
        nombreAsociacion: Value(relacion.nombreAsociacion),
        rolOrigen: Value(relacion.rolOrigen),
        rolDestino: Value(relacion.rolDestino),
      ),
    );
  }

  Future<void> eliminarRelacion(int relacionId) async {
    await _db.eliminarRelacion(relacionId);
  }

  // ==================================================================
  // Helpers de serialización
  // ==================================================================
  String _encodeAtributos(List<AtributoUml> atributos) {
    final list = atributos.map((a) => {
          'id': a.id,
          'id_clase': a.idClase,
          'nombre': a.nombre,
          'tipo_dato': a.tipoDato,
          'visibilidad': a.visibilidad.value,
          'es_estatico': a.esEstatico,
          'valor_defecto': a.valorDefecto,
          'orden': a.orden,
        }).toList();
    return jsonEncode(list);
  }

  String _encodeOperaciones(List<OperacionUml> operaciones) {
    final list = operaciones.map((op) => {
          'id': op.id,
          'id_clase': op.idClase,
          'nombre': op.nombre,
          'tipo_retorno': op.tipoRetorno,
          'visibilidad': op.visibilidad.value,
          'es_estatico': op.esEstatico,
          'orden': op.orden,
          'parametros': op.parametros.map((p) => {
                'id': p.id,
                'id_operacion': p.idOperacion,
                'nombre': p.nombre,
                'tipo_dato': p.tipoDato,
                'orden': p.orden,
              }).toList(),
        }).toList();
    return jsonEncode(list);
  }

  // ==================================================================
  // Conversiones
  // ==================================================================
  ClaseUml _rowToClase(ClaseUmlLocal row) {
    final atributosJson = (jsonDecode(row.atributosJson) as List).cast<Map>();
    final operacionesJson =
        (jsonDecode(row.operacionesJson) as List).cast<Map>();

    return ClaseUml(
      id: row.id,
      idDiagrama: row.idDiagrama,
      nombre: row.nombre,
      esAbstracta: row.esAbstracta,
      estereotipo: row.estereotipo,
      posX: row.posX,
      posY: row.posY,
      idCreador: row.idCreador,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      atributos: atributosJson.map((a) {
        return AtributoUml(
          id: (a['id'] as num).toInt(),
          idClase: (a['id_clase'] as num).toInt(),
          nombre: a['nombre'] as String? ?? '',
          tipoDato: a['tipo_dato'] as String? ?? 'String',
          visibilidad:
              VisibilidadUml.fromValue(a['visibilidad'] as String? ?? '-'),
          esEstatico: a['es_estatico'] as bool? ?? false,
          valorDefecto: a['valor_defecto'] as String?,
          orden: (a['orden'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      operaciones: operacionesJson.map((op) {
        final params = (op['parametros'] as List?) ?? [];
        return OperacionUml(
          id: (op['id'] as num).toInt(),
          idClase: (op['id_clase'] as num).toInt(),
          nombre: op['nombre'] as String? ?? '',
          tipoRetorno: op['tipo_retorno'] as String? ?? 'void',
          visibilidad:
              VisibilidadUml.fromValue(op['visibilidad'] as String? ?? '+'),
          esEstatico: op['es_estatico'] as bool? ?? false,
          orden: (op['orden'] as num?)?.toInt() ?? 0,
          parametros: params.map((p) {
            final pm = p as Map;
            return ParametroOperacionUml(
              id: (pm['id'] as num).toInt(),
              idOperacion: (pm['id_operacion'] as num).toInt(),
              nombre: pm['nombre'] as String? ?? '',
              tipoDato: pm['tipo_dato'] as String? ?? 'String',
              orden: (pm['orden'] as num?)?.toInt() ?? 0,
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  RelacionUml _rowToRelacion(RelacionUmlLocal row) {
    return RelacionUml(
      id: row.id,
      idDiagrama: row.idDiagrama,
      idClaseOrigen: row.idClaseOrigen,
      idClaseDestino: row.idClaseDestino,
      tipoRelacion: TipoRelacion.fromValue(row.tipoRelacion),
      multiplicidadOrigen: row.multiplicidadOrigen,
      multiplicidadDestino: row.multiplicidadDestino,
      nombreAsociacion: row.nombreAsociacion,
      rolOrigen: row.rolOrigen,
      rolDestino: row.rolDestino,
    );
  }
}