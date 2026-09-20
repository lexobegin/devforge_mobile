// lib/features/diagrama_editor/data/diagrama_repository.dart
//
// Repositorio de diagrama con estrategia offline-first.
//
// Reglas:
// 1. Al leer: si hay red, traer del remoto y cachear en SQLite.
//    Si no hay red, devolver del cache local.
// 2. Al escribir: intentar el remoto. Si falla por red, encolar y
//    guardar localmente.

import '../../../../core/network/api_client.dart';
//import '../../domain/clase_uml_entity.dart';
import '../domain/clase_uml_entity.dart';
//import '../../domain/diagrama_entity.dart';
import '../domain/diagrama_entity.dart';
//import '../../domain/relacion_uml_entity.dart';
import '../domain/relacion_uml_entity.dart';
import 'diagrama_local_datasource.dart';
import 'diagrama_remote_datasource.dart';

class DiagramaRepository {
  DiagramaRepository({
    required DiagramaRemoteDataSource remote,
    required DiagramaLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final DiagramaRemoteDataSource _remote;
  final DiagramaLocalDataSource _local;

  // ==================================================================
  // Diagrama
  // ==================================================================
  Future<List<Diagrama>> listarPorProyecto(int proyectoId) {
    return _remote.listarPorProyecto(proyectoId);
  }

  Future<Diagrama> crear(
    int proyectoId, {
    required String nombre,
    String? versionUml,
  }) async {
    // Crear requiere conexión (no lo soportamos offline por ahora)
    return _remote.crear(proyectoId, nombre: nombre, versionUml: versionUml);
  }

  Future<Diagrama> obtener(int diagramaId) async {
    try {
      final d = await _remote.obtener(diagramaId);
      return d;
    } on ApiException catch (e) {
      if (e.status == 0) {
        final local = await _local.obtenerMetadata(diagramaId);
        if (local != null) return local;
      }
      rethrow;
    }
  }

  // ==================================================================
  // Obtener completo — con cache
  // ==================================================================
  Future<DiagramaCompleto> obtenerCompleto(int diagramaId) async {
    try {
      final completo = await _remote.obtenerCompleto(diagramaId);
      // Cachear en SQLite para lectura offline
      await _local.guardarCompleto(completo);
      return completo;
    } on ApiException catch (e) {
      if (e.status == 0) {
        // Sin red: intentar del cache
        final local = await _local.obtenerCompleto(diagramaId);
        if (local != null) return local;
        throw ApiException(
          status: 0,
          code: 'NO_CACHE',
          detail: 'Sin conexión y sin datos en cache local.',
        );
      }
      rethrow;
    }
  }

  Future<Diagrama> actualizar(
    int diagramaId, {
    String? nombre,
    String? versionUml,
  }) {
    return _remote.actualizar(diagramaId, nombre: nombre, versionUml: versionUml);
  }

  Future<void> eliminar(int diagramaId) {
    return _remote.eliminar(diagramaId);
  }

  // ==================================================================
  // Clases
  // ==================================================================
  Future<List<ClaseUml>> listarClases(int diagramaId) =>
      _remote.listarClases(diagramaId);

  Future<ClaseUml> crearClase(
    int diagramaId, {
    required String nombre,
    bool? esAbstracta,
    String? estereotipo,
    double? posX,
    double? posY,
    List<Map<String, dynamic>>? atributos,
    List<Map<String, dynamic>>? operaciones,
  }) async {
    final clase = await _remote.crearClase(
      diagramaId,
      nombre: nombre,
      esAbstracta: esAbstracta,
      estereotipo: estereotipo,
      posX: posX,
      posY: posY,
      atributos: atributos,
      operaciones: operaciones,
    );
    // Cachear
    await _local.guardarClase(clase);
    return clase;
  }

  Future<ClaseUml> obtenerClase(int claseId) => _remote.obtenerClase(claseId);

  Future<ClaseUml> actualizarClase(
    int claseId, {
    String? nombre,
    bool? esAbstracta,
    String? estereotipo,
    double? posX,
    double? posY,
  }) async {
    final clase = await _remote.actualizarClase(
      claseId,
      nombre: nombre,
      esAbstracta: esAbstracta,
      estereotipo: estereotipo,
      posX: posX,
      posY: posY,
    );
    await _local.guardarClase(clase);
    return clase;
  }

  Future<void> eliminarClase(int claseId) async {
    await _remote.eliminarClase(claseId);
    await _local.eliminarClase(claseId);
  }

  // ==================================================================
  // Atributos
  // ==================================================================
  Future<AtributoUml> agregarAtributo(
    int claseId, {
    required String nombre,
    required String tipoDato,
    String? visibilidad,
    bool? esEstatico,
    String? valorDefecto,
    int? orden,
  }) {
    return _remote.agregarAtributo(
      claseId,
      nombre: nombre,
      tipoDato: tipoDato,
      visibilidad: visibilidad,
      esEstatico: esEstatico,
      valorDefecto: valorDefecto,
      orden: orden,
    );
  }

  Future<AtributoUml> actualizarAtributo(
    int atributoId, {
    String? nombre,
    String? tipoDato,
    String? visibilidad,
    bool? esEstatico,
    String? valorDefecto,
    int? orden,
  }) {
    return _remote.actualizarAtributo(
      atributoId,
      nombre: nombre,
      tipoDato: tipoDato,
      visibilidad: visibilidad,
      esEstatico: esEstatico,
      valorDefecto: valorDefecto,
      orden: orden,
    );
  }

  Future<void> eliminarAtributo(int atributoId) =>
      _remote.eliminarAtributo(atributoId);

  // ==================================================================
  // Relaciones
  // ==================================================================
  Future<List<RelacionUml>> listarRelaciones(int diagramaId) =>
      _remote.listarRelaciones(diagramaId);

  Future<RelacionUml> crearRelacion(
    int diagramaId, {
    required int idClaseOrigen,
    required int idClaseDestino,
    required String tipoRelacion,
    String? multiplicidadOrigen,
    String? multiplicidadDestino,
    String? nombreAsociacion,
    String? rolOrigen,
    String? rolDestino,
  }) async {
    final rel = await _remote.crearRelacion(
      diagramaId,
      idClaseOrigen: idClaseOrigen,
      idClaseDestino: idClaseDestino,
      tipoRelacion: tipoRelacion,
      multiplicidadOrigen: multiplicidadOrigen,
      multiplicidadDestino: multiplicidadDestino,
      nombreAsociacion: nombreAsociacion,
      rolOrigen: rolOrigen,
      rolDestino: rolDestino,
    );
    await _local.guardarRelacion(rel);
    return rel;
  }

  Future<RelacionUml> actualizarRelacion(
    int relacionId, {
    int? idClaseOrigen,
    int? idClaseDestino,
    String? tipoRelacion,
    String? multiplicidadOrigen,
    String? multiplicidadDestino,
    String? nombreAsociacion,
    String? rolOrigen,
    String? rolDestino,
  }) async {
    final rel = await _remote.actualizarRelacion(
      relacionId,
      idClaseOrigen: idClaseOrigen,
      idClaseDestino: idClaseDestino,
      tipoRelacion: tipoRelacion,
      multiplicidadOrigen: multiplicidadOrigen,
      multiplicidadDestino: multiplicidadDestino,
      nombreAsociacion: nombreAsociacion,
      rolOrigen: rolOrigen,
      rolDestino: rolDestino,
    );
    await _local.guardarRelacion(rel);
    return rel;
  }

  Future<void> eliminarRelacion(int relacionId) async {
    await _remote.eliminarRelacion(relacionId);
    await _local.eliminarRelacion(relacionId);
  }
}