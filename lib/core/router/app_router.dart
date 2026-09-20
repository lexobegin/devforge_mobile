// lib/core/router/app_router.dart
//
// Router principal de la app (go_router).
//
// Estructura:
//   /                          → Splash (redirige según sesión)
//   /login                     → Login
//   /register                  → Registro
//   /proyectos                 → Lista de proyectos (protegida)
//   /proyectos/:proyectoId     → Detalle (protegida)
//   /diagramas/:diagramaId     → Editor (protegida)
//   /generacion/:trabajoId     → Estado de generación (protegida)
//   /notificaciones            → Notificaciones (protegida)
//   /perfil                    → Perfil (protegida)
//
// La guarda de autenticación está implementada en el redirect, que
// reacciona a los cambios del authProvider.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';

import '../../features/diagrama_editor/presentation/pages/diagram_editor_page.dart';
import '../../features/generacion_codigo/presentation/pages/generacion_page.dart';
import '../../features/notificaciones/presentation/pages/notificaciones_page.dart';
import '../../features/perfil/presentation/pages/perfil_page.dart';
import '../../features/proyectos/presentation/pages/proyecto_detail_page.dart';
import '../../features/proyectos/presentation/pages/proyectos_list_page.dart';
import 'app_routes.dart';

// ======================================================================
// Provider del router (con guarda de auth reactiva)
// ======================================================================
/*final appRouterProvider = Provider<GoRouter>((ref) {
  // El router se crea UNA vez. Para que reaccione a los cambios del
  // authProvider, usamos un Notifier que escucha y dispara
  // `refreshListenable`.
  final authNotifier = _AuthListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    routes: _routes,
    redirect: (context, state) {
      // Leer el estado actual del auth en cada redirect
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;

      // Mientras hace bootstrap, no redirigir
      if (auth.isBootstrapping) return null;

      final isAuth = auth.isAuthenticated;
      final isPublicRoute =
          location == AppRoutes.login || location == AppRoutes.register;
      final isSplash = location == AppRoutes.splash;

      // No autenticado en ruta protegida → login
      if (!isAuth && !isPublicRoute && !isSplash) {
        return AppRoutes.login;
      }

      // Autenticado en login/register/splash → proyectos
      if (isAuth && (isPublicRoute || isSplash)) {
        return AppRoutes.proyectos;
      }

      return null;
    },
  );
});*/

// ======================================================================
// Provider del router (con guarda de auth reactiva)
// ======================================================================
/*final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: _routes,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;

      if (auth.isBootstrapping) return null;

      final isAuth = auth.isAuthenticated;
      final isPublicRoute =
          location == AppRoutes.login || location == AppRoutes.register;
      final isSplash = location == AppRoutes.splash;

      if (!isAuth && !isPublicRoute && !isSplash) return AppRoutes.login;
      if (isAuth && (isPublicRoute || isSplash)) return AppRoutes.proyectos;
      return null;
    },
  );

  // Cuando cambie el estado de auth, forzamos una re-navegación
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.isBootstrapping == true && next.isBootstrapping == false) {
      // El bootstrap acaba de terminar: navegar según el estado
      if (next.isAuthenticated) {
        router.go(AppRoutes.proyectos);
      } else {
        router.go(AppRoutes.login);
      }
    }
  });

  return router;
});*/

// ======================================================================
// Provider del router (con guarda de auth reactiva)
// ======================================================================
final appRouterProvider = Provider<GoRouter>((ref) {
  // ValueNotifier que dispara refreshListenable cada vez que cambia
  // cualquier parte importante del auth.
  final refreshNotifier = ValueNotifier<int>(0);

  // Escuchar cambios en isBootstrapping + isAuthenticated (combinados).
  ref.listen<(bool, bool)>(
    authProvider.select(
      (s) => (s.isBootstrapping, s.isAuthenticated),
    ),
    (previous, next) {
      // Solo notificar si efectivamente cambió
      if (previous == next) return;
      refreshNotifier.value++;
    },
  );

  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    routes: _routes,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;

      // Debug opcional
      // print('[REDIRECT] loc=$location auth=${auth.isAuthenticated} '
      //     'boot=${auth.isBootstrapping}');

      // 1. Mientras bootstrapea, no redirigir
      if (auth.isBootstrapping) return null;

      final isAuth = auth.isAuthenticated;
      final isPublicRoute =
          location == AppRoutes.login || location == AppRoutes.register;
      final isSplash = location == AppRoutes.splash;

      // 2. No autenticado en ruta protegida → login
      if (!isAuth && !isPublicRoute && !isSplash) {
        return AppRoutes.login;
      }

      // 3. Autenticado en login/register/splash → proyectos
      if (isAuth && (isPublicRoute || isSplash)) {
        return AppRoutes.proyectos;
      }

      // 4. No autenticado en splash → login (¡FALTABA ESTO!)
      if (!isAuth && isSplash) {
        return AppRoutes.login;
      }

      return null;
    },
  );
});

/// Listenable que emite cuando cambia `authProvider`. Le dice al router
/// que reevalúe el redirect.
/*class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}*/

// ======================================================================
// Rutas
// ======================================================================
final _routes = <RouteBase>[
  // ---------- Splash ----------
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const _SplashPlaceholder(),
  ),

  // ---------- Auth ----------
  GoRoute(
    path: AppRoutes.login,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    path: AppRoutes.register,
    builder: (context, state) => const RegisterPage(),
  ),

  // ---------- Protegidas ----------
  GoRoute(
    path: AppRoutes.proyectos,
    builder: (context, state) => const ProyectosListPage(),
  ),
  GoRoute(
    path: AppRoutes.proyectoDetallePattern,
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['proyectoId'] ?? '') ?? 0;
      return ProyectoDetailPage(proyectoId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.diagramaEditorPattern,
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['diagramaId'] ?? '') ?? 0;
      return DiagramEditorPage(diagramaId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.generacionStatusPattern,
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['trabajoId'] ?? '') ?? 0;
      return GeneracionPage(trabajoId: id);
    },
  ),
  GoRoute(
    path: AppRoutes.notificaciones,
    builder: (context, state) => const NotificacionesPage(),
  ),
  GoRoute(
    path: AppRoutes.perfil,
    builder: (context, state) => const PerfilPage(),
  ),
];

// ======================================================================
// Splash
// ======================================================================
class _SplashPlaceholder extends ConsumerWidget {
  const _SplashPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El redirect del router se encarga de llevarnos a login o proyectos
    // cuando el bootstrap del authProvider termine.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DevForgeLogo(size: 64),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando DevForge AI…'),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Logo reutilizable
// ======================================================================
class _DevForgeLogo extends StatelessWidget {
  final double size;

  const _DevForgeLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Center(
        child: Text(
          'DF',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
