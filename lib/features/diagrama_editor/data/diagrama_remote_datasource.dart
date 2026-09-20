// lib/features/diagrama_editor/data/diagrama_remote_datasource.dart
//
// Datasource remoto del módulo Diagrama editor.
//
// Cubre las operaciones más usadas del editor: cargar el diagrama completo,
// y el CRUD de clases y relaciones. Las operaciones sobre atributos y
// operaciones individuales se agregan cuando sean necesarias en la UI.

import '../../../core/network/api_client.dart';
//import '../../domain/clase_uml_entity.dart';
import '../domain/clase_uml_entity.dart';
//import '../../domain/diagrama_entity.dart';
import '../domain/diagrama_entity.dart';
//import '../../domain/relacion_uml_entity.dart';
import '../domain/relacion_uml_entity.dart';
import 'clase_uml_model.dart';
import 'diagrama_model.dart';
import 'relacion_uml_model.dart';

class DiagramaRemoteDataSource {
  DiagramaRemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Diagrama
  // ==================================================================

  /// Lista los diagramas de un proyecto.
  Future<List<Diagrama>> listarPorProyecto(int proyectoId) async {
    final json = await _client.get<List<dynamic>>(
      '/diagramas/proyecto/$proyectoId',
    );
    return json
        .map((d) => DiagramaModel.fromJson((d as Map).cast<String, dynamic>()))
        .toList();
  }

  /// Crea un diagrama dentro de un proyecto.
  Future<Diagrama> crear(
    int proyectoId, {
    required String nombre,
    String? versionUml,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/diagramas/proyecto/$proyectoId',
      body: DiagramaModel.toCreateJson(
        nombre: nombre,
        versionUml: versionUml,
      ),
    );
    return DiagramaModel.fromJson(json);
  }

  /// Obtiene la metadata de un diagrama.
  Future<Diagrama> obtener(int diagramaId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/diagramas/$diagramaId',
    );
    return DiagramaModel.fromJson(json);
  }

  /// Obtiene el diagrama completo (clases + relaciones + interfaces).
  /// Este es el payload que consume el editor.
  Future<DiagramaCompleto> obtenerCompleto(int diagramaId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/diagramas/$diagramaId/completo',
    );
    return DiagramaModel.completoFromJson(json);
  }

  /// Actualiza la metadata del diagrama.
  Future<Diagrama> actualizar(
    int diagramaId, {
    String? nombre,
    String? versionUml,
  }) async {
    final json = await _client.put<Map<String, dynamic>>(
      '/diagramas/$diagramaId',
      body: DiagramaModel.toUpdateJson(
        nombre: nombre,
        versionUml: versionUml,
      ),
    );
    return DiagramaModel.fromJson(json);
  }

  /// Elimina el diagrama (y todo su contenido en cascada).
  Future<void> eliminar(int diagramaId) async {
    await _client.delete<void>('/diagramas/$diagramaId');
  }

  // ==================================================================
  // Clases
  // ==================================================================

  Future<List<ClaseUml>> listarClases(int diagramaId) async {
    final json = await _client.get<List<dynamic>>(
      '/diagramas/$diagramaId/clases',
    );
    return json
        .map((c) => ClaseUmlModel.fromJson((c as Map).cast<String, dynamic>()))
        .toList();
  }

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
    final json = await _client.post<Map<String, dynamic>>(
      '/diagramas/$diagramaId/clases',
      body: ClaseUmlModel.toCreateJson(
        nombre: nombre,
        esAbstracta: esAbstracta,
        estereotipo: estereotipo,
        posX: posX,
        posY: posY,
        atributos: atributos,
        operaciones: operaciones,
      ),
    );
    return ClaseUmlModel.fromJson(json);
  }

  Future<ClaseUml> obtenerClase(int claseId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/diagramas/clases/$claseId',
    );
    return ClaseUmlModel.fromJson(json);
  }

  Future<ClaseUml> actualizarClase(
    int claseId, {
    String? nombre,
    bool? esAbstracta,
    String? estereotipo,
    double? posX,
    double? posY,
  }) async {
    final json = await _client.put<Map<String, dynamic>>(
      '/diagramas/clases/$claseId',
      body: ClaseUmlModel.toUpdateJson(
        nombre: nombre,
        esAbstracta: esAbstracta,
        estereotipo: estereotipo,
        posX: posX,
        posY: posY,
      ),
    );
    return ClaseUmlModel.fromJson(json);
  }

  Future<void> eliminarClase(int claseId) async {
    await _client.delete<void>('/diagramas/clases/$claseId');
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
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/diagramas/clases/$claseId/atributos',
      body: AtributoUmlModel.toCreateJson(
        nombre: nombre,
        tipoDato: tipoDato,
        visibilidad: visibilidad,
        esEstatico: esEstatico,
        valorDefecto: valorDefecto,
        orden: orden,
      ),
    );
    return AtributoUmlModel.fromJson(json);
  }

  Future<AtributoUml> actualizarAtributo(
    int atributoId, {
    String? nombre,
    String? tipoDato,
    String? visibilidad,
    bool? esEstatico,
    String? valorDefecto,
    int? orden,
  }) async {
    final json = await _client.put<Map<String, dynamic>>(
      '/diagramas/atributos/$atributoId',
      body: AtributoUmlModel.toUpdateJson(
        nombre: nombre,
        tipoDato: tipoDato,
        visibilidad: visibilidad,
        esEstatico: esEstatico,
        valorDefecto: valorDefecto,
        orden: orden,
      ),
    );
    return AtributoUmlModel.fromJson(json);
  }

  Future<void> eliminarAtributo(int atributoId) async {
    await _client.delete<void>('/diagramas/atributos/$atributoId');
  }

  // ==================================================================
  // Relaciones
  // ==================================================================

  Future<List<RelacionUml>> listarRelaciones(int diagramaId) async {
    final json = await _client.get<List<dynamic>>(
      '/diagramas/$diagramaId/relaciones',
    );
    return json
        .map((r) =>
            RelacionUmlModel.fromJson((r as Map).cast<String, dynamic>()))
        .toList();
  }

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
    final json = await _client.post<Map<String, dynamic>>(
      '/diagramas/$diagramaId/relaciones',
      body: RelacionUmlModel.toCreateJson(
        idClaseOrigen: idClaseOrigen,
        idClaseDestino: idClaseDestino,
        tipoRelacion: tipoRelacion,
        multiplicidadOrigen: multiplicidadOrigen,
        multiplicidadDestino: multiplicidadDestino,
        nombreAsociacion: nombreAsociacion,
        rolOrigen: rolOrigen,
        rolDestino: rolDestino,
      ),
    );
    return RelacionUmlModel.fromJson(json);
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
    final json = await _client.put<Map<String, dynamic>>(
      '/diagramas/relaciones/$relacionId',
      body: RelacionUmlModel.toUpdateJson(
        idClaseOrigen: idClaseOrigen,
        idClaseDestino: idClaseDestino,
        tipoRelacion: tipoRelacion,
        multiplicidadOrigen: multiplicidadOrigen,
        multiplicidadDestino: multiplicidadDestino,
        nombreAsociacion: nombreAsociacion,
        rolOrigen: rolOrigen,
        rolDestino: rolDestino,
      ),
    );
    return RelacionUmlModel.fromJson(json);
  }

  Future<void> eliminarRelacion(int relacionId) async {
    await _client.delete<void>('/diagramas/relaciones/$relacionId');
  }
}