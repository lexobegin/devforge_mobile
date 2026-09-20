// lib/features/ia_assistant/domain/ia_entity.dart
//
// Entidades de dominio del asistente de IA:
// prompts de voz/texto, acciones propuestas, reconocimiento de bocetos.

import 'package:flutter/foundation.dart';

// ======================================================================
// Enums
// ======================================================================
enum CanalIA {
  voz('VOZ', 'Voz'),
  texto('TEXTO', 'Texto');

  const CanalIA(this.value, this.label);

  final String value;
  final String label;
}

// ======================================================================
// Acción propuesta por la IA
// ======================================================================
@immutable
class AccionIAPropuesta {
  final String tipo;
  final Map<String, dynamic> payload;
  final String? descripcion;

  const AccionIAPropuesta({
    required this.tipo,
    this.payload = const {},
    this.descripcion,
  });

  String get etiqueta =>
      descripcion?.isNotEmpty == true ? descripcion! : tipo;
}

// ======================================================================
// Respuesta de la IA
// ======================================================================
@immutable
class RespuestaIA {
  final String textoRespuesta;
  final List<AccionIAPropuesta> accionesPropuestas;
  final bool requiereConfirmacion;

  const RespuestaIA({
    required this.textoRespuesta,
    this.accionesPropuestas = const [],
    this.requiereConfirmacion = true,
  });

  bool get tieneAcciones => accionesPropuestas.isNotEmpty;
}

// ======================================================================
// Interacción con la IA (persistida)
// ======================================================================
@immutable
class InteraccionIA {
  final int id;
  final int idProyecto;
  final int? idDiagrama;
  final int idUsuario;
  final CanalIA canal;
  final String textoPrompt;
  final Map<String, dynamic>? respuestaIA;
  final bool accionAplicada;
  final DateTime createdAt;

  const InteraccionIA({
    required this.id,
    required this.idProyecto,
    this.idDiagrama,
    required this.idUsuario,
    required this.canal,
    required this.textoPrompt,
    this.respuestaIA,
    this.accionAplicada = false,
    required this.createdAt,
  });
}

// ======================================================================
// Resultado del reconocimiento de boceto
// ======================================================================
@immutable
class VisionReconocimiento {
  final bool exito;
  final double? confianza;

  /// Estructura reconstruida — mismo formato que DiagramaCompleto:
  /// contiene listas de clases y relaciones.
  final Map<String, dynamic> diagramaReconstruido;

  final List<String> advertencias;
  final String? imagenProcesadaUrl;

  const VisionReconocimiento({
    required this.exito,
    this.confianza,
    this.diagramaReconstruido = const {},
    this.advertencias = const [],
    this.imagenProcesadaUrl,
  });

  int get totalClases {
    final clases = (diagramaReconstruido['clases'] as List?) ?? [];
    return clases.length;
  }

  int get totalRelaciones {
    final relaciones = (diagramaReconstruido['relaciones'] as List?) ?? [];
    return relaciones.length;
  }

  bool get tieneAdvertencias => advertencias.isNotEmpty;
}