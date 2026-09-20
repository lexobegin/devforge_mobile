// lib/features/diagrama_editor/presentation/providers/websocket_provider.dart
//
// Provider que conecta el WebSocket de colaboración al diagrama activo.

import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/websocket_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../colaboracion/presentation/providers/colaboracion_provider.dart';
import '../../domain/clase_uml_entity.dart';
import '../../domain/relacion_uml_entity.dart';
import 'diagrama_provider.dart';

// ======================================================================
// Argumentos
// ======================================================================
@immutable
class WebSocketArgs {
  final int diagramaId;

  const WebSocketArgs({required this.diagramaId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WebSocketArgs && other.diagramaId == diagramaId;
  }

  @override
  int get hashCode => diagramaId.hashCode;
}

// ======================================================================
// Controller
// ======================================================================
class WebSocketController {
  WebSocketController({
    required this.diagramaId,
    required this.client,
  });

  final int diagramaId;
  final WebSocketClient client;

  DateTime _lastCursorSent = DateTime.fromMillisecondsSinceEpoch(0);

  void conectar() => client.connect();

  Future<void> cerrar() => client.close();

  void emitirCursor(Offset posicion) {
    final now = DateTime.now();
    if (now.difference(_lastCursorSent).inMilliseconds < 50) return;
    _lastCursorSent = now;
    client.sendCursor(posicion.dx, posicion.dy);
  }

  void emitirSeleccion(String tipo, int id) {
    client.sendSelection(tipo, id);
  }

  void emitirEvento(String tipo, Map<String, dynamic> payload) {
    client.send(tipo, payload);
  }
}

// ======================================================================
// Provider del controller
// ======================================================================
final webSocketControllerProvider =
    Provider.family<WebSocketController, WebSocketArgs>((ref, args) {
  // Leer estado del auth
  final usuario = ref.read(authProvider).usuario;
  final tokenStorage = ref.read(tokenStorageProvider);

  // Referencias a notifiers (solo para usarlos más tarde, NO en el build)
  final diagramaNotifier = ref.read(diagramaProvider.notifier);
  final colaboracionNotifier = ref.read(colaboracionProvider.notifier);

  // Placeholder inicial: se reemplaza cuando el token esté listo
  final controller = _PlaceholderController(args.diagramaId);

  // Inicialización asíncrona DESPUÉS del build (evita modificar otros
  // providers durante la construcción).
  Future.microtask(() async {
    // Setear el id del usuario en el notifier (ahora sí, después del build)
    if (usuario != null) {
      colaboracionNotifier.setMiUsuarioId(usuario.id);
    }

    // Obtener token de forma asíncrona
    final token = await tokenStorage.getAccess();
    if (token == null || token.isEmpty) return;

    // Crear cliente WS
    final client = WebSocketClient(
      diagramaId: args.diagramaId,
      token: token,
      callbacks: WsCallbacks(
        onMessage: (msg) => _handleMessage(
          msg,
          diagramaNotifier: diagramaNotifier,
          colaboracionNotifier: colaboracionNotifier,
          miUsuarioId: usuario?.id,
        ),
        onStatusChange: (status) {
          colaboracionNotifier
              .setConectado(status == WsStatus.connected);
        },
      ),
    );

    // Reemplazar el controller placeholder por el real
    controller._attach(client);
    client.connect();
  });

  // Cleanup al desmontar
  ref.onDispose(() async {
    await controller.cerrar();
    colaboracionNotifier.limpiar();
  });

  return controller;
});

// ======================================================================
// Controller placeholder (se convierte en real tras init)
// ======================================================================
class _PlaceholderController extends WebSocketController {
  _PlaceholderController(int diagramaId)
      : super(
          diagramaId: diagramaId,
          client: WebSocketClient(
            diagramaId: diagramaId,
            token: '',
            callbacks: const WsCallbacks(),
          ),
        );

  WebSocketClient? _realClient;

  void _attach(WebSocketClient client) {
    _realClient = client;
  }

  WebSocketClient get _effective => _realClient ?? client;

  @override
  void conectar() => _effective.connect();

  @override
  Future<void> cerrar() => _effective.close();

  @override
  void emitirCursor(Offset posicion) {
    final now = DateTime.now();
    if (now.difference(_lastCursorSent).inMilliseconds < 50) return;
    _lastCursorSent = now;
    _effective.sendCursor(posicion.dx, posicion.dy);
  }

  @override
  void emitirSeleccion(String tipo, int id) {
    _effective.sendSelection(tipo, id);
  }

  @override
  void emitirEvento(String tipo, Map<String, dynamic> payload) {
    _effective.send(tipo, payload);
  }
}

// ======================================================================
// Manejo de mensajes entrantes
// ======================================================================
void _handleMessage(
  WsMessage msg, {
  required DiagramaNotifier diagramaNotifier,
  required ColaboracionNotifier colaboracionNotifier,
  required int? miUsuarioId,
}) {
  final payload = msg.payload;
  final sender = msg.sender;

  if (sender != null && sender['id'] == miUsuarioId) return;

  switch (msg.type) {
    case 'join':
      if (sender != null) {
        colaboracionNotifier.agregarColaborador(
          (sender['id'] as num).toInt(),
          sender['nombre'] as String? ?? '',
        );
      }
      break;

    case 'leave':
      if (sender != null) {
        colaboracionNotifier
            .quitarColaborador((sender['id'] as num).toInt());
      }
      break;

    case 'cursor_moved':
      if (sender != null &&
          payload['x'] is num &&
          payload['y'] is num) {
        colaboracionNotifier.actualizarCursor(
          (sender['id'] as num).toInt(),
          Offset(
            (payload['x'] as num).toDouble(),
            (payload['y'] as num).toDouble(),
          ),
        );
      }
      break;

    case 'selection_changed':
      if (sender != null &&
          payload['tipo'] is String &&
          payload['id'] is num) {
        colaboracionNotifier.actualizarSeleccion(
          (sender['id'] as num).toInt(),
          payload['tipo'] as String,
          (payload['id'] as num).toInt(),
        );
      }
      break;

    case 'sync_snapshot':
      final conectados = (payload['conectados'] as List?) ?? [];
      colaboracionNotifier.setConectados(
        conectados
            .map((c) => (c as Map).cast<String, dynamic>())
            .toList(),
      );
      break;

    case 'class_created':
    case 'class_updated':
      try {
        diagramaNotifier.aplicarClaseRemota(_claseDesdePayload(payload));
      } catch (_) {}
      break;

    case 'class_deleted':
      final id = (payload['id'] ?? payload['id_clase']) as num?;
      if (id != null) {
        diagramaNotifier.aplicarClaseEliminada(id.toInt());
      }
      break;

    case 'relation_created':
    case 'relation_updated':
      try {
        diagramaNotifier.aplicarRelacionRemota(
          _relacionDesdePayload(payload),
        );
      } catch (_) {}
      break;

    case 'relation_deleted':
      final id = (payload['id'] ?? payload['id_relacion']) as num?;
      if (id != null) {
        diagramaNotifier.aplicarRelacionEliminada(id.toInt());
      }
      break;
  }
}

// ======================================================================
// Conversión de payload a entidades
// ======================================================================
ClaseUml _claseDesdePayload(Map<String, dynamic> payload) {
  return ClaseUml(
    id: (payload['id'] as num).toInt(),
    idDiagrama: (payload['id_diagrama'] as num?)?.toInt() ?? 0,
    nombre: payload['nombre'] as String? ?? '',
    esAbstracta: payload['es_abstracta'] as bool? ?? false,
    estereotipo: payload['estereotipo'] as String?,
    posX: (payload['pos_x'] as num?)?.toDouble() ?? 0,
    posY: (payload['pos_y'] as num?)?.toDouble() ?? 0,
    idCreador: (payload['id_creador'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

RelacionUml _relacionDesdePayload(Map<String, dynamic> payload) {
  return RelacionUml(
    id: (payload['id'] as num).toInt(),
    idDiagrama: (payload['id_diagrama'] as num?)?.toInt() ?? 0,
    idClaseOrigen: (payload['id_clase_origen'] as num).toInt(),
    idClaseDestino: (payload['id_clase_destino'] as num).toInt(),
    tipoRelacion: TipoRelacion.fromValue(
      payload['tipo_relacion'] as String? ?? 'ASOCIACION',
    ),
    multiplicidadOrigen: payload['multiplicidad_origen'] as String?,
    multiplicidadDestino: payload['multiplicidad_destino'] as String?,
    nombreAsociacion: payload['nombre_asociacion'] as String?,
    rolOrigen: payload['rol_origen'] as String?,
    rolDestino: payload['rol_destino'] as String?,
  );
}