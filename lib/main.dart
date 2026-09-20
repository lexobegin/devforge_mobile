// lib/main.dart
//
// Punto de entrada de la app móvil DevForge AI.
//
// - Inicializa los bindings de Flutter.
// - Configura el ProviderScope de Riverpod (estado global).
// - Configura la orientación (solo vertical por defecto).
// - Monta el widget raíz `DevForgeApp`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:flutter_secure_storage/flutter_secure_storage.dart';


import 'app.dart';

Future<void> main() async {
  // Asegura que los plugins nativos estén inicializados antes de usar
  // cualquier API de plataforma (SQLite, secure storage, etc).
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquear la orientación a vertical (para simplificar el diseño).
  // Si más adelante querés permitir horizontal, quitá estas líneas.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barra de estado en modo oscuro para integrarse con el tema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  //final storage = const FlutterSecureStorage();
  //await storage.deleteAll();
  //print('[INIT] storage limpiado');

  runApp(
    const ProviderScope(
      child: DevForgeApp(),
    ),
  );
}