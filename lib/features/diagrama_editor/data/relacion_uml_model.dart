// lib/features/diagrama_editor/data/relacion_uml_model.dart
//
// Mappers JSON ↔ entidades de Relación e Interfaz UML.

//import '../../domain/relacion_uml_entity.dart';
import '../domain/relacion_uml_entity.dart';

// ======================================================================
// Relación
// ======================================================================
class RelacionUmlModel {
  const RelacionUmlModel._();

  static RelacionUml fromJson(Map<String, dynamic> json) {
    return RelacionUml(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      idClaseOrigen: (json['id_clase_origen'] as num).toInt(),
      idClaseDestino: (json['id_clase_destino'] as num).toInt(),
      tipoRelacion: TipoRelacion.fromValue(
        json['tipo_relacion'] as String? ?? 'ASOCIACION',
      ),
      multiplicidadOrigen: json['multiplicidad_origen'] as String?,
      multiplicidadDestino: json['multiplicidad_destino'] as String?,
      nombreAsociacion: json['nombre_asociacion'] as String?,
      rolOrigen: json['rol_origen'] as String?,
      rolDestino: json['rol_destino'] as String?,
    );
  }

  static Map<String, dynamic> toCreateJson({
    required int idClaseOrigen,
    required int idClaseDestino,
    required String tipoRelacion,
    String? multiplicidadOrigen,
    String? multiplicidadDestino,
    String? nombreAsociacion,
    String? rolOrigen,
    String? rolDestino,
  }) {
    return {
      'id_clase_origen': idClaseOrigen,
      'id_clase_destino': idClaseDestino,
      'tipo_relacion': tipoRelacion,
      if (multiplicidadOrigen != null)
        'multiplicidad_origen': multiplicidadOrigen,
      if (multiplicidadDestino != null)
        'multiplicidad_destino': multiplicidadDestino,
      if (nombreAsociacion != null) 'nombre_asociacion': nombreAsociacion,
      if (rolOrigen != null) 'rol_origen': rolOrigen,
      if (rolDestino != null) 'rol_destino': rolDestino,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    int? idClaseOrigen,
    int? idClaseDestino,
    String? tipoRelacion,
    String? multiplicidadOrigen,
    String? multiplicidadDestino,
    String? nombreAsociacion,
    String? rolOrigen,
    String? rolDestino,
  }) {
    return {
      if (idClaseOrigen != null) 'id_clase_origen': idClaseOrigen,
      if (idClaseDestino != null) 'id_clase_destino': idClaseDestino,
      if (tipoRelacion != null) 'tipo_relacion': tipoRelacion,
      if (multiplicidadOrigen != null)
        'multiplicidad_origen': multiplicidadOrigen,
      if (multiplicidadDestino != null)
        'multiplicidad_destino': multiplicidadDestino,
      if (nombreAsociacion != null) 'nombre_asociacion': nombreAsociacion,
      if (rolOrigen != null) 'rol_origen': rolOrigen,
      if (rolDestino != null) 'rol_destino': rolDestino,
    };
  }
}

// ======================================================================
// Interfaz
// ======================================================================
class InterfazUmlModel {
  const InterfazUmlModel._();

  static InterfazUml fromJson(Map<String, dynamic> json) {
    final opsJson = (json['operaciones'] as List?) ?? [];

    return InterfazUml(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      posX: _parseDouble(json['pos_x']),
      posY: _parseDouble(json['pos_y']),
      operaciones: opsJson
          .map((o) => OperacionInterfazUmlModel.fromJson(
                (o as Map).cast<String, dynamic>(),
              ))
          .toList(),
    );
  }
}

class OperacionInterfazUmlModel {
  const OperacionInterfazUmlModel._();

  static OperacionInterfazUml fromJson(Map<String, dynamic> json) {
    return OperacionInterfazUml(
      id: (json['id'] as num).toInt(),
      idInterfaz: (json['id_interfaz'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      tipoRetorno: json['tipo_retorno'] as String? ?? 'void',
    );
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