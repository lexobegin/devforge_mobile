// lib/features/ia_assistant/data/ia_repository.dart
//
// Repositorio de IA.

import 'dart:io';

//import '../../domain/ia_entity.dart';
import '../domain/ia_entity.dart';
import 'ia_remote_datasource.dart';

class IARepository {
  IARepository(this._remote);

  final IARemoteDataSource _remote;

  // ==================================================================
  // Prompts
  // ==================================================================
  Future<RespuestaIA> enviarPrompt(
    int proyectoId, {
    required String textoPrompt,
    CanalIA canal = CanalIA.texto,
    int? idDiagrama,
    Map<String, dynamic>? contexto,
  }) =>
      _remote.enviarPrompt(
        proyectoId,
        textoPrompt: textoPrompt,
        canal: canal,
        idDiagrama: idDiagrama,
        contexto: contexto,
      );

  Future<InteraccionIA> confirmarAcciones(
    int interaccionId, {
    List<int> accionesAplicar = const [],
  }) =>
      _remote.confirmarAcciones(
        interaccionId,
        accionesAplicar: accionesAplicar,
      );

  Future<InteraccionIA> obtenerInteraccion(int interaccionId) =>
      _remote.obtenerInteraccion(interaccionId);

  Future<List<InteraccionIA>> listarPorProyecto(
    int proyectoId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listarPorProyecto(proyectoId, skip: skip, limit: limit);

  Future<List<InteraccionIA>> listarPorDiagrama(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) =>
      _remote.listarPorDiagrama(diagramaId, skip: skip, limit: limit);

  // ==================================================================
  // IA de visión
  // ==================================================================
  Future<VisionReconocimiento> reconocerParaDiagrama(
    int diagramaId, {
    required File imagen,
    String idioma = 'es',
  }) =>
      _remote.reconocerParaDiagrama(
        diagramaId,
        imagen: imagen,
        idioma: idioma,
      );

  Future<VisionReconocimiento> reconocerSinPersistir({
    required File imagen,
    String idioma = 'es',
  }) =>
      _remote.reconocerSinPersistir(imagen: imagen, idioma: idioma);
}