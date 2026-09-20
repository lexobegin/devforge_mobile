// lib/features/diagrama_editor/data/diagrama_model.dart
//
// Mappers JSON ↔ entidades de Diagrama.
//
// El diagrama completo (con clases, relaciones e interfaces) se mapea
// aquí delegando a los models de clase y relación.

import '../domain/clase_uml_entity.dart';
import '../domain/diagrama_entity.dart';
import '../domain/relacion_uml_entity.dart';
import 'clase_uml_model.dart';
import 'relacion_uml_model.dart';

class DiagramaModel {
  const DiagramaModel._();

  // ==================================================================
  // Metadata
  // ==================================================================
  static Diagrama fromJson(Map<String, dynamic> json) {
    return Diagrama(
      id: (json['id'] as num).toInt(),
      idProyecto: (json['id_proyecto'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      versionUml: json['version_uml'] as String? ?? '2.5.1',
      numeroVersion: (json['numero_version'] as num?)?.toInt() ?? 1,
      idCreador: (json['id_creador'] as num).toInt(),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nombre,
    String? versionUml,
  }) {
    return {
      'nombre': nombre,
      if (versionUml != null) 'version_uml': versionUml,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? nombre,
    String? versionUml,
  }) {
    return {
      if (nombre != null) 'nombre': nombre,
      if (versionUml != null) 'version_uml': versionUml,
    };
  }

  // ==================================================================
  // Diagrama completo
  // ==================================================================
  /// Mapea el JSON de `/diagramas/{id}/completo` a un DiagramaCompleto
  /// con sus clases, relaciones e interfaces ya tipadas.
  static DiagramaCompleto completoFromJson(Map<String, dynamic> json) {
    final diagrama = fromJson(json);

    final clasesJson = (json['clases'] as List?) ?? [];
    final clases = clasesJson
        .map((c) => ClaseUmlModel.fromJson((c as Map).cast<String, dynamic>()))
        .toList();

    final relacionesJson = (json['relaciones'] as List?) ?? [];
    final relaciones = relacionesJson
        .map((r) => RelacionUmlModel.fromJson((r as Map).cast<String, dynamic>()))
        .toList();

    final interfacesJson = (json['interfaces'] as List?) ?? [];
    final interfaces = interfacesJson
        .map((i) => InterfazUmlModel.fromJson((i as Map).cast<String, dynamic>()))
        .toList();

    return DiagramaCompleto(
      diagrama: diagrama,
      clases: clases,
      interfaces: interfaces,
      relaciones: relaciones,
    );
  }
}

// ======================================================================
// Helper
// ======================================================================
DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}