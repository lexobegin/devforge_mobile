// lib/features/proyectos/data/proyecto_model.dart
//
// Mappers JSON ↔ entidades de Proyecto y MiembroProyecto.

//import '../../domain/proyecto_entity.dart';
import '../domain/proyecto_entity.dart';

// ======================================================================
// ProyectoModel
// ======================================================================
class ProyectoModel {
  const ProyectoModel._();

  static Proyecto fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: (json['id'] as num).toInt(),
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      idPropietario: (json['id_propietario'] as num).toInt(),
      estado: EstadoProyecto.fromValue(json['estado'] as String? ?? 'ACTIVO'),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nombre,
    String? descripcion,
  }) {
    return {
      'nombre': nombre,
      if (descripcion != null && descripcion.isNotEmpty)
        'descripcion': descripcion,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    String? nombre,
    String? descripcion,
    EstadoProyecto? estado,
  }) {
    return {
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (estado != null) 'estado': estado.value,
    };
  }
}

// ======================================================================
// MiembroProyectoModel
// ======================================================================
class MiembroProyectoModel {
  const MiembroProyectoModel._();

  static MiembroProyecto fromJson(Map<String, dynamic> json) {
    // El backend puede incluir un `usuario` embebido con nombre/email.
    final usuario = (json['usuario'] as Map?)?.cast<String, dynamic>();

    return MiembroProyecto(
      id: (json['id'] as num).toInt(),
      idProyecto: (json['id_proyecto'] as num).toInt(),
      idUsuario: (json['id_usuario'] as num).toInt(),
      rol: RolEnProyecto.fromValue(
        json['rol_en_proyecto'] as String? ?? 'LECTOR',
      ),
      joinedAt: _parseDateTime(json['joined_at']),
      nombreUsuario: usuario?['nombre_completo'] as String?,
      emailUsuario: usuario?['email'] as String?,
    );
  }
}

// ======================================================================
// ProyectoConMiembrosModel
// ======================================================================
class ProyectoConMiembrosModel {
  const ProyectoConMiembrosModel._();

  static ProyectoConMiembros fromJson(Map<String, dynamic> json) {
    final proyecto = ProyectoModel.fromJson(json);
    final miembrosJson = (json['miembros'] as List?) ?? [];
    final miembros = miembrosJson
        .map((m) => MiembroProyectoModel.fromJson((m as Map).cast<String, dynamic>()))
        .toList();

    return ProyectoConMiembros(proyecto: proyecto, miembros: miembros);
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