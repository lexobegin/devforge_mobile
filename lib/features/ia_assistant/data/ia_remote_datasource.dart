// lib/features/ia_assistant/data/ia_remote_datasource.dart
//
// Datasource remoto del asistente de IA.
//
// Cubre:
// - Prompts de voz/texto (modo online).
// - Confirmación de acciones aplicadas.
// - Historial de interacciones.
// - Reconocimiento de bocetos (IA de visión).

import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
//import '../../domain/ia_entity.dart';
import '../domain/ia_entity.dart';
import 'ia_model.dart';

class IARemoteDataSource {
  IARemoteDataSource(this._client);

  final ApiClient _client;

  // ==================================================================
  // Prompts de voz/texto
  // ==================================================================
  Future<RespuestaIA> enviarPrompt(
    int proyectoId, {
    required String textoPrompt,
    CanalIA canal = CanalIA.texto,
    int? idDiagrama,
    Map<String, dynamic>? contexto,
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/ia/proyectos/$proyectoId/prompt',
      body: IAModel.toPromptJson(
        textoPrompt: textoPrompt,
        canal: canal.value,
        idDiagrama: idDiagrama,
        contexto: contexto,
      ),
    );
    return IAModel.respuestaFromJson(json);
  }

  Future<InteraccionIA> confirmarAcciones(
    int interaccionId, {
    List<int> accionesAplicar = const [],
  }) async {
    final json = await _client.post<Map<String, dynamic>>(
      '/ia/interacciones/$interaccionId/confirmar',
      body: {
        'id_interaccion': interaccionId,
        'acciones_a_aplicar': accionesAplicar,
      },
    );
    return IAModel.interaccionFromJson(json);
  }

  Future<InteraccionIA> obtenerInteraccion(int interaccionId) async {
    final json = await _client.get<Map<String, dynamic>>(
      '/ia/interacciones/$interaccionId',
    );
    return IAModel.interaccionFromJson(json);
  }

  Future<List<InteraccionIA>> listarPorProyecto(
    int proyectoId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/ia/proyectos/$proyectoId/interacciones',
      query: {'skip': skip, 'limit': limit},
    );
    return json
        .map((i) => IAModel.interaccionFromJson(
              (i as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  Future<List<InteraccionIA>> listarPorDiagrama(
    int diagramaId, {
    int skip = 0,
    int limit = 50,
  }) async {
    final json = await _client.get<List<dynamic>>(
      '/ia/diagramas/$diagramaId/interacciones',
      query: {'skip': skip, 'limit': limit},
    );
    return json
        .map((i) => IAModel.interaccionFromJson(
              (i as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  // ==================================================================
  // IA de visión
  // ==================================================================
  /// Reconoce una imagen de boceto y la asocia a un diagrama.
  /// El resultado NO se aplica automáticamente: el usuario debe
  /// confirmar y aplicar los elementos reconstruidos.
  Future<VisionReconocimiento> reconocerParaDiagrama(
    int diagramaId, {
    required File imagen,
    String idioma = 'es',
  }) async {
    final formData = FormData.fromMap({
      'imagen': await MultipartFile.fromFile(imagen.path),
      'idioma': idioma,
    });

    final json = await _client.dio
        .post<Map<String, dynamic>>(
          '/ai-vision/diagramas/$diagramaId/reconocer',
          data: formData,
        )
        .then((r) => r.data ?? <String, dynamic>{});

    return IAModel.visionFromJson(json);
  }

  /// Reconoce una imagen sin asociarla a un diagrama (preview).
  Future<VisionReconocimiento> reconocerSinPersistir({
    required File imagen,
    String idioma = 'es',
  }) async {
    final formData = FormData.fromMap({
      'imagen': await MultipartFile.fromFile(imagen.path),
      'idioma': idioma,
    });

    final json = await _client.dio
        .post<Map<String, dynamic>>(
          '/ai-vision/reconocer',
          data: formData,
        )
        .then((r) => r.data ?? <String, dynamic>{});

    return IAModel.visionFromJson(json);
  }
}