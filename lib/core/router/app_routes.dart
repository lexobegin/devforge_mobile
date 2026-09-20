// lib/core/router/app_routes.dart
//
// Constantes de rutas de la app.
//
// Centraliza todos los paths para evitar strings repetidos y facilitar
// refactors.

class AppRoutes {
  const AppRoutes._();

  // ==================================================================
  // Públicas
  // ==================================================================
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // ==================================================================
  // Protegidas
  // ==================================================================
  static const String proyectos = '/proyectos';
  static const String notificaciones = '/notificaciones';
  static const String perfil = '/perfil';

  // ==================================================================
  // Con parámetros — usar los helpers para construirlas
  // ==================================================================
  static const String proyectoDetallePattern = '/proyectos/:proyectoId';
  static const String diagramaEditorPattern = '/diagramas/:diagramaId';
  static const String generacionStatusPattern = '/generacion/:trabajoId';

  static String proyectoDetalle(int proyectoId) => '/proyectos/$proyectoId';
  static String diagramaEditor(int diagramaId) => '/diagramas/$diagramaId';
  static String generacionStatus(int trabajoId) => '/generacion/$trabajoId';
}