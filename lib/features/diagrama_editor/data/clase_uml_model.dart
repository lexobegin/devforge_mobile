// lib/features/diagrama_editor/data/clase_uml_model.dart
//
// Mappers JSON ↔ entidades de Clase UML, Atributo, Operación y Parámetro.
//
// El backend devuelve la clase con sus atributos y operaciones embebidos.

//import '../../domain/clase_uml_entity.dart';
import '../domain/clase_uml_entity.dart';

class ClaseUmlModel {
  const ClaseUmlModel._();

  // ==================================================================
  // Clase
  // ==================================================================
  static ClaseUml fromJson(Map<String, dynamic> json) {
    final atributosJson = (json['atributos'] as List?) ?? [];
    final operacionesJson = (json['operaciones'] as List?) ?? [];

    return ClaseUml(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      esAbstracta: json['es_abstracta'] as bool? ?? false,
      estereotipo: json['estereotipo'] as String?,
      posX: _parseDouble(json['pos_x']),
      posY: _parseDouble(json['pos_y']),
      idCreador: (json['id_creador'] as num).toInt(),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      atributos: atributosJson
          .map((a) =>
              AtributoUmlModel.fromJson((a as Map).cast<String, dynamic>()))
          .toList(),
      operaciones: operacionesJson
          .map((o) =>
              OperacionUmlModel.fromJson((o as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nombre,
    bool? esAbstracta,
    String? estereotipo,
    double? posX,
    double? posY,
    List<Map<String, dynamic>>? atributos,
    List<Map<String, dynamic>>? operaciones,
  }) {
    return {
      'nombre': nombre,
      if (esAbstracta != null) 'es_abstracta': esAbstracta,
      if (estereotipo != null) 'estereotipo': estereotipo,
      if (posX != null) 'pos_x': posX,
      if (posY != null) 'pos_y': posY,
      if (atributos != null && atributos.isNotEmpty) 'atributos': atributos,
      if (operaciones != null && operaciones.isNotEmpty)
        'operaciones': operaciones,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? nombre,
    bool? esAbstracta,
    String? estereotipo,
    double? posX,
    double? posY,
  }) {
    return {
      if (nombre != null) 'nombre': nombre,
      if (esAbstracta != null) 'es_abstracta': esAbstracta,
      if (estereotipo != null) 'estereotipo': estereotipo,
      if (posX != null) 'pos_x': posX,
      if (posY != null) 'pos_y': posY,
    };
  }
}

// ======================================================================
// Atributo
// ======================================================================
class AtributoUmlModel {
  const AtributoUmlModel._();

  static AtributoUml fromJson(Map<String, dynamic> json) {
    return AtributoUml(
      id: (json['id'] as num).toInt(),
      idClase: (json['id_clase'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      tipoDato: json['tipo_dato'] as String? ?? 'String',
      visibilidad: VisibilidadUml.fromValue(
        json['visibilidad'] as String? ?? '-',
      ),
      esEstatico: json['es_estatico'] as bool? ?? false,
      valorDefecto: json['valor_defecto'] as String?,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nombre,
    required String tipoDato,
    String? visibilidad,
    bool? esEstatico,
    String? valorDefecto,
    int? orden,
  }) {
    return {
      'nombre': nombre,
      'tipo_dato': tipoDato,
      if (visibilidad != null) 'visibilidad': visibilidad,
      if (esEstatico != null) 'es_estatico': esEstatico,
      if (valorDefecto != null) 'valor_defecto': valorDefecto,
      if (orden != null) 'orden': orden,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? nombre,
    String? tipoDato,
    String? visibilidad,
    bool? esEstatico,
    String? valorDefecto,
    int? orden,
  }) {
    return {
      if (nombre != null) 'nombre': nombre,
      if (tipoDato != null) 'tipo_dato': tipoDato,
      if (visibilidad != null) 'visibilidad': visibilidad,
      if (esEstatico != null) 'es_estatico': esEstatico,
      if (valorDefecto != null) 'valor_defecto': valorDefecto,
      if (orden != null) 'orden': orden,
    };
  }
}

// ======================================================================
// Operación
// ======================================================================
class OperacionUmlModel {
  const OperacionUmlModel._();

  static OperacionUml fromJson(Map<String, dynamic> json) {
    final paramsJson = (json['parametros'] as List?) ?? [];

    return OperacionUml(
      id: (json['id'] as num).toInt(),
      idClase: (json['id_clase'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      tipoRetorno: json['tipo_retorno'] as String? ?? 'void',
      visibilidad: VisibilidadUml.fromValue(
        json['visibilidad'] as String? ?? '+',
      ),
      esEstatico: json['es_estatico'] as bool? ?? false,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      parametros: paramsJson
          .map((p) => ParametroOperacionUmlModel.fromJson(
                (p as Map).cast<String, dynamic>(),
              ))
          .toList(),
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nombre,
    String? tipoRetorno,
    String? visibilidad,
    bool? esEstatico,
    int? orden,
    List<Map<String, dynamic>>? parametros,
  }) {
    return {
      'nombre': nombre,
      if (tipoRetorno != null) 'tipo_retorno': tipoRetorno,
      if (visibilidad != null) 'visibilidad': visibilidad,
      if (esEstatico != null) 'es_estatico': esEstatico,
      if (orden != null) 'orden': orden,
      if (parametros != null && parametros.isNotEmpty)
        'parametros': parametros,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? nombre,
    String? tipoRetorno,
    String? visibilidad,
    bool? esEstatico,
    int? orden,
  }) {
    return {
      if (nombre != null) 'nombre': nombre,
      if (tipoRetorno != null) 'tipo_retorno': tipoRetorno,
      if (visibilidad != null) 'visibilidad': visibilidad,
      if (esEstatico != null) 'es_estatico': esEstatico,
      if (orden != null) 'orden': orden,
    };
  }
}

// ======================================================================
// Parámetro
// ======================================================================
class ParametroOperacionUmlModel {
  const ParametroOperacionUmlModel._();

  static ParametroOperacionUml fromJson(Map<String, dynamic> json) {
    return ParametroOperacionUml(
      id: (json['id'] as num).toInt(),
      idOperacion: (json['id_operacion'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      tipoDato: json['tipo_dato'] as String? ?? 'String',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nombre,
    required String tipoDato,
    int? orden,
  }) {
    return {
      'nombre': nombre,
      'tipo_dato': tipoDato,
      if (orden != null) 'orden': orden,
    };
  }
}

// ======================================================================
// Helpers
// ======================================================================
double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}