// lib/features/ia_assistant/presentation/providers/ia_provider.dart
//
// Provider del asistente de IA (chat + visión).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/ia_remote_datasource.dart';
import '../../data/ia_repository.dart';
import '../../domain/ia_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final iaRemoteDataSourceProvider = Provider<IARemoteDataSource>((ref) {
  return IARemoteDataSource(ref.watch(apiClientProvider));
});

final iaRepositoryProvider = Provider<IARepository>((ref) {
  return IARepository(ref.watch(iaRemoteDataSourceProvider));
});

// ======================================================================
// Mensaje del chat
// ======================================================================
@immutable
class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String texto;
  final List<AccionIAPropuesta> acciones;
  final int? interaccionId;
  final bool aplicada;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.texto,
    this.acciones = const [],
    this.interaccionId,
    this.aplicada = false,
  });

  bool get esUsuario => role == 'user';
  bool get tieneAcciones => acciones.isNotEmpty;

  ChatMessage copyWith({
    bool? aplicada,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      texto: texto,
      acciones: acciones,
      interaccionId: interaccionId,
      aplicada: aplicada ?? this.aplicada,
    );
  }
}

// ======================================================================
// Estado del chat
// ======================================================================
@immutable
class IAChatState {
  final List<ChatMessage> mensajes;
  final bool enviando;
  final String? error;

  const IAChatState({
    this.mensajes = const [],
    this.enviando = false,
    this.error,
  });

  IAChatState copyWith({
    List<ChatMessage>? mensajes,
    bool? enviando,
    String? error,
    bool clearError = false,
  }) {
    return IAChatState(
      mensajes: mensajes ?? this.mensajes,
      enviando: enviando ?? this.enviando,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ======================================================================
// Notifier del chat
// ======================================================================
class IAChatNotifier extends StateNotifier<IAChatState> {
  IAChatNotifier(this._repo) : super(const IAChatState());

  final IARepository _repo;

  // ==================================================================
  // Enviar prompt
  // ==================================================================
  Future<RespuestaIA> enviarPrompt({
    required int proyectoId,
    required String texto,
    CanalIA canal = CanalIA.texto,
    int? idDiagrama,
  }) async {
    // Agregar mensaje del usuario
    final userMsg = ChatMessage(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      texto: texto,
    );
    state = state.copyWith(
      mensajes: [...state.mensajes, userMsg],
      enviando: true,
      clearError: true,
    );

    try {
      final respuesta = await _repo.enviarPrompt(
        proyectoId,
        textoPrompt: texto,
        canal: canal,
        idDiagrama: idDiagrama,
      );

      final assistantMsg = ChatMessage(
        id: 'a-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        texto: respuesta.textoRespuesta,
        acciones: respuesta.accionesPropuestas,
      );

      state = state.copyWith(
        mensajes: [...state.mensajes, assistantMsg],
        enviando: false,
      );

      return respuesta;
    } catch (e) {
      state = state.copyWith(
        enviando: false,
        error: e.toString(),
        mensajes: [
          ...state.mensajes,
          ChatMessage(
            id: 'e-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            texto: 'No pude procesar tu solicitud. Intentá de nuevo.',
          ),
        ],
      );
      rethrow;
    }
  }

  // ==================================================================
  // Marcar acciones como aplicadas
  // ==================================================================
  void marcarAplicada(String mensajeId) {
    state = state.copyWith(
      mensajes: state.mensajes
          .map((m) => m.id == mensajeId ? m.copyWith(aplicada: true) : m)
          .toList(),
    );
  }

  // ==================================================================
  // Limpiar chat
  // ==================================================================
  void limpiarChat() {
    state = const IAChatState();
  }
}

final iaChatProvider =
    StateNotifierProvider<IAChatNotifier, IAChatState>((ref) {
  return IAChatNotifier(ref.watch(iaRepositoryProvider));
});

// ======================================================================
// Visión (reconocimiento de bocetos)
// ======================================================================
@immutable
class VisionState {
  final bool procesando;
  final VisionReconocimiento? resultado;
  final String? error;

  const VisionState({
    this.procesando = false,
    this.resultado,
    this.error,
  });

  VisionState copyWith({
    bool? procesando,
    VisionReconocimiento? resultado,
    String? error,
    bool clearError = false,
    bool clearResultado = false,
  }) {
    return VisionState(
      procesando: procesando ?? this.procesando,
      resultado: clearResultado ? null : (resultado ?? this.resultado),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class VisionNotifier extends StateNotifier<VisionState> {
  VisionNotifier(this._repo) : super(const VisionState());

  final IARepository _repo;

  Future<VisionReconocimiento> reconocerParaDiagrama({
    required int diagramaId,
    required File imagen,
  }) async {
    state = state.copyWith(
      procesando: true,
      clearError: true,
      clearResultado: true,
    );
    try {
      final resultado = await _repo.reconocerParaDiagrama(
        diagramaId,
        imagen: imagen,
      );
      state = state.copyWith(procesando: false, resultado: resultado);
      return resultado;
    } catch (e) {
      state = state.copyWith(procesando: false, error: e.toString());
      rethrow;
    }
  }

  Future<VisionReconocimiento> reconocerSinPersistir({
    required File imagen,
  }) async {
    state = state.copyWith(
      procesando: true,
      clearError: true,
      clearResultado: true,
    );
    try {
      final resultado = await _repo.reconocerSinPersistir(imagen: imagen);
      state = state.copyWith(procesando: false, resultado: resultado);
      return resultado;
    } catch (e) {
      state = state.copyWith(procesando: false, error: e.toString());
      rethrow;
    }
  }

  void limpiar() => state = const VisionState();
}

final visionProvider =
    StateNotifierProvider<VisionNotifier, VisionState>((ref) {
  return VisionNotifier(ref.watch(iaRepositoryProvider));
});