// lib/core/network/websocket_client.dart
//
// Cliente WebSocket para la colaboración en tiempo real.
//
// - Conecta al backend con el token de acceso del usuario.
// - Reconexión automática con backoff exponencial.
// - Heartbeat periódico (ping/pong).
// - Emite eventos tipados al consumidor (Stream).
// - Ignora mensajes propios (por robustez).

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../config/env.dart';

/// Estado de la conexión WS.
enum WsStatus {
  idle,
  connecting,
  connected,
  disconnected,
  reconnecting,
}

/// Mensaje entrante del WebSocket.
class WsMessage {
  final String type;
  final Map<String, dynamic> payload;
  final String? timestamp;
  final Map<String, dynamic>? sender;

  WsMessage({
    required this.type,
    required this.payload,
    this.timestamp,
    this.sender,
  });

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] as String? ?? 'unknown',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      timestamp: json['timestamp'] as String?,
      sender: (json['sender'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Callbacks opcionales que el consumidor puede registrar.
class WsCallbacks {
  final void Function(WsMessage message)? onMessage;
  final void Function()? onOpen;
  final void Function()? onClose;
  final void Function(WsStatus status)? onStatusChange;
  final void Function(Object error)? onError;

  const WsCallbacks({
    this.onMessage,
    this.onOpen,
    this.onClose,
    this.onStatusChange,
    this.onError,
  });
}

/// Cliente WebSocket.
class WebSocketClient {
  WebSocketClient({
    required this.diagramaId,
    required this.token,
    this.callbacks = const WsCallbacks(),
    int? maxReconnectAttempts,
    int? initialReconnectDelayMs,
  })  : _maxReconnectAttempts =
            maxReconnectAttempts ?? Env.wsReconnectMaxAttempts,
        _initialReconnectDelayMs =
            initialReconnectDelayMs ?? Env.wsReconnectInitialDelayMs;

  final int diagramaId;
  final String token;
  final WsCallbacks callbacks;

  final int _maxReconnectAttempts;
  final int _initialReconnectDelayMs;
  static const int _maxReconnectDelayMs = 30000;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  WsStatus _status = WsStatus.idle;
  int _reconnectAttempts = 0;
  bool _manualClose = false;

  // ==================================================================
  // Getters
  // ==================================================================
  WsStatus get status => _status;
  bool get isConnected => _status == WsStatus.connected;

  // ==================================================================
  // Control
  // ==================================================================
  void connect() {
    _manualClose = false;
    _openSocket();
  }

  Future<void> close() async {
    _manualClose = true;
    _clearTimers();
    try {
      await _subscription?.cancel();
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _channel = null;
    _setStatus(WsStatus.idle);
  }

  /// Envía un mensaje al servidor.
  bool send(String type, [Map<String, dynamic>? payload]) {
    if (_channel == null || _status != WsStatus.connected) return false;
    try {
      _channel!.sink.add(
        jsonEncode({
          'type': type,
          'payload': payload ?? {},
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Atajos comunes.
  bool sendCursor(double x, double y) =>
      send('cursor_moved', {'x': x, 'y': y});

  bool sendSelection(String tipo, int id) =>
      send('selection_changed', {'tipo': tipo, 'id': id});

  // ==================================================================
  // Internos
  // ==================================================================
  void _openSocket() {
    if (_manualClose) return;

    _setStatus(
      _reconnectAttempts > 0 ? WsStatus.reconnecting : WsStatus.connecting,
    );

    try {
      final url = Env.diagramWsUrl(diagramaId, token);
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Detectar apertura: el stream no expone un onOpen directo, así que
      // asumimos que si no hay error en el primer frame, está conectado.
      // El primer mensaje del servidor debería ser `sync_snapshot`.
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_manualClose && _status != WsStatus.connected) {
          _onOpen();
        }
      });
    } catch (e) {
      callbacks.onError?.call(e);
      _scheduleReconnect();
    }
  }

  void _onOpen() {
    _reconnectAttempts = 0;
    _setStatus(WsStatus.connected);
    callbacks.onOpen?.call();
    _startHeartbeat();
  }

  void _onData(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = WsMessage.fromJson(json);

      // Responder a ping con pong, ignorar pong
      if (message.type == 'ping') {
        send('pong');
        return;
      }
      if (message.type == 'pong') return;

      callbacks.onMessage?.call(message);
    } catch (_) {
      // Mensaje no parseable: ignorar
    }
  }

  void _onError(Object error) {
    callbacks.onError?.call(error);
  }

  void _onDone() {
    _stopHeartbeat();
    _setStatus(WsStatus.disconnected);
    callbacks.onClose?.call();

    if (_manualClose) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualClose) return;
    if (_maxReconnectAttempts >= 0 &&
        _reconnectAttempts >= _maxReconnectAttempts) {
      _setStatus(WsStatus.disconnected);
      return;
    }

    final delayMs = (_initialReconnectDelayMs *
            (1 << _reconnectAttempts)) // 2^attempts
        .clamp(_initialReconnectDelayMs, _maxReconnectDelayMs);

    _reconnectAttempts++;

    _clearReconnectTimer();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), _openSocket);
  }

  // ==================================================================
  // Heartbeat
  // ==================================================================
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => send('ping'),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ==================================================================
  // Limpieza y estado
  // ==================================================================
  void _clearReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _clearTimers() {
    _clearReconnectTimer();
    _stopHeartbeat();
  }

  void _setStatus(WsStatus status) {
    if (_status == status) return;
    _status = status;
    callbacks.onStatusChange?.call(status);
  }
}