// lib/features/auth/data/usuario_model.dart
//
// Mappers JSON ↔ entidades de dominio de Usuario y AuthTokens.
//
// Los modelos NO son entidades de dominio: son la representación "de
// transporte" que se convierte a/desde JSON. El dominio (Usuario,
// AuthTokens) queda puro, sin saber de JSON.

//import '../../domain/usuario_entity.dart';
import '../../auth/domain/usuario_entity.dart';


// ======================================================================
// UsuarioModel
// ======================================================================
class UsuarioModel {
  const UsuarioModel._();

  /// Convierte un JSON del backend a la entidad de dominio `Usuario`.
  static Usuario fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: (json['id'] as num).toInt(),
      nombreCompleto: json['nombre_completo'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: RolGlobal.fromValue(json['rol'] as String? ?? 'DESARROLLADOR'),
      activo: json['activo'] as bool? ?? true,
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  /// Convierte la entidad `Usuario` a JSON (para requests de creación/edición).
  static Map<String, dynamic> toJson(Usuario usuario) {
    return {
      'nombre_completo': usuario.nombreCompleto,
      'email': usuario.email,
      'rol': usuario.rol.value,
      'activo': usuario.activo,
    };
  }

  /// Variante para creación (incluye password).
  static Map<String, dynamic> toCreateJson({
    required String nombreCompleto,
    required String email,
    required String password,
    RolGlobal? rol,
  }) {
    return {
      'nombre_completo': nombreCompleto,
      'email': email,
      'password': password,
      if (rol != null) 'rol': rol.value,
    };
  }

  /// Variante para actualización parcial.
  static Map<String, dynamic> toUpdateJson({
    String? nombreCompleto,
    String? email,
    String? password,
    RolGlobal? rol,
    bool? activo,
  }) {
    return {
      if (nombreCompleto != null) 'nombre_completo': nombreCompleto,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (rol != null) 'rol': rol.value,
      if (activo != null) 'activo': activo,
    };
  }
}

// ======================================================================
// AuthTokensModel
// ======================================================================
class AuthTokensModel {
  const AuthTokensModel._();

  /// Convierte el JSON del backend (login / refresh) a `AuthTokens`.
  static AuthTokens fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
      usuario: UsuarioModel.fromJson(
        (json['usuario'] as Map).cast<String, dynamic>(),
      ),
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