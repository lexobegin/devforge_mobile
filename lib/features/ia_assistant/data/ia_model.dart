// lib/features/ia_assistant/data/ia_model.dart
//
// Mappers JSON ↔ entidades de IA.

//import '../../domain/ia_entity.dart';
import '../domain/ia_entity.dart';

class IAModel {
  const IAModel._();

  // ==================================================================
  // Respuesta de IA
  // ==================================================================
  static RespuestaIA respuestaFromJson(Map<String, dynamic> json) {
    final accionesJson = (json['acciones_propuestas'] as List?) ?? [];

    return RespuestaIA(
      textoRespuesta: json['texto_respuesta'] as String? ?? '',
      accionesPropuestas: accionesJson
          .map((a) => accionFromJson((a as Map).cast<String, dynamic>()))
          .toList(),
      requiereConfirmacion: json['requiere_confirmacion'] as bool? ?? true,
    );
  }

  static AccionIAPropuesta accionFromJson(Map<String, dynamic> json) {
    return AccionIAPropuesta(
      tipo: json['tipo'] as String? ?? '',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      descripcion: json['descripcion'] as String?,
    );
  }

  // ==================================================================
  // Interacción
  // ==================================================================
  static InteraccionIA interaccionFromJson(Map<String, dynamic> json) {
    return InteraccionIA(
      id: (json['id'] as num).toInt(),
      idProyecto: (json['id_proyecto'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num?)?.toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      canal: CanalIA.values.firstWhere(
        (c) => c.value == (json['canal'] as String? ?? 'TEXTO'),
        orElse: () => CanalIA.texto,
      ),
      textoPrompt: json['texto_prompt'] as String? ?? '',
      respuestaIA:
          (json['respuesta_ia'] as Map?)?.cast<String, dynamic>(),
      accionAplicada: json['accion_aplicada'] as bool? ?? false,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  // ==================================================================
  // Requests
  // ==================================================================
  static Map<String, dynamic> toPromptJson({
    required String textoPrompt,
    String canal = 'TEXTO',
    int? idDiagrama,
    Map<String, dynamic>? contexto,
  }) {
    return {
      'texto_prompt': textoPrompt,
      'canal': canal,
      if (idDiagrama != null) 'id_diagrama': idDiagrama,
      if (contexto != null && contexto.isNotEmpty) 'contexto': contexto,
    };
  }

  // ==================================================================
  // Visión
  // ==================================================================
  static VisionReconocimiento visionFromJson(Map<String, dynamic> json) {
    final advertenciasJson = (json['advertencias'] as List?) ?? [];

    return VisionReconocimiento(
      exito: json['exito'] as bool? ?? false,
      confianza: (json['confianza'] as num?)?.toDouble(),
      diagramaReconstruido:
          (json['diagrama_reconstruido'] as Map?)?.cast<String, dynamic>() ??
              {},
      advertencias:
          advertenciasJson.map((a) => a.toString()).toList(),
      imagenProcesadaUrl: json['imagen_procesada_url'] as String?,
    );
  }
}

// ======================================================================
// Helpers
// ======================================================================
DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}