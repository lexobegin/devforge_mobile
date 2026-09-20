// lib/core/providers/core_providers.dart
//
// Providers base de la app.
//
// Expone los singletons y las dependencias compartidas (ApiClient,
// repositorios, servicios). Los providers de cada feature los consumen.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';

// ======================================================================
// ApiClient + TokenStorage
// ======================================================================
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient.instance;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage.instance;
});

// ======================================================================
// Base de datos local
// ======================================================================
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ======================================================================
// Conectividad
// ======================================================================
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});

/// Stream de cambios de conectividad (para que la UI reaccione).
final connectivityStreamProvider = StreamProvider<ConnectivityInfo>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.stream;
});

/// Estado actual de conexión (online / offline).
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStreamProvider);
  return async.maybeWhen(
    data: (info) => info.isOnline,
    orElse: () => true, // Asumimos online hasta saber lo contrario
  );
});