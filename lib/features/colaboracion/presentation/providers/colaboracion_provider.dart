// lib/features/colaboracion/presentation/providers/colaboracion_provider.dart
//
// Provider de colaboración en tiempo real.
//
// Mantiene la lista de colaboradores conectados al diagrama actual y sus
// cursores/selecciones. Se alimenta exclusivamente desde los eventos del
// WebSocket (websocket_provider).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:ui' show Color, Offset;
//import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors.dart';


// ======================================================================
// Colaborador
// ======================================================================
@immutable
class Colaborador {
  final int id;
  final String nombre;
  final Offset cursor;
  final bool tieneCursor;
  final String? seleccionTipo;
  final int? seleccionId;

  const Colaborador({
    required this.id,
    required this.nombre,
    this.cursor = Offset.zero,
    this.tieneCursor = false,
    this.seleccionTipo,
    this.seleccionId,
  });

  Color get color => AppColors.colorPorId(id);

  Colaborador copyWith({
    int? id,
    String? nombre,
    Offset? cursor,
    bool? tieneCursor,
    String? seleccionTipo,
    int? seleccionId,
    bool clearSeleccion = false,
  }) {
    return Colaborador(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cursor: cursor ?? this.cursor,
      tieneCursor: tieneCursor ?? this.tieneCursor,
      seleccionTipo: clearSeleccion ? null : (seleccionTipo ?? this.seleccionTipo),
      seleccionId: clearSeleccion ? null : (seleccionId ?? this.seleccionId),
    );
  }
}

// ======================================================================
// Estado
// ======================================================================
@immutable
class ColaboracionState {
  final List<Colaborador> colaboradores;
  final bool conectado;
  final int? miUsuarioId;

  const ColaboracionState({
    this.colaboradores = const [],
    this.conectado = false,
    this.miUsuarioId,
  });

  ColaboracionState copyWith({
    List<Colaborador>? colaboradores,
    bool? conectado,
    int? miUsuarioId,
  }) {
    return ColaboracionState(
      colaboradores: colaboradores ?? this.colaboradores,
      conectado: conectado ?? this.conectado,
      miUsuarioId: miUsuarioId ?? this.miUsuarioId,
    );
  }

  int get totalConectados =>
      colaboradores.length + (miUsuarioId != null ? 1 : 0);

  Colaborador? colaboradorPorId(int id) {
    for (final c in colaboradores) {
      if (c.id == id) return c;
    }
    return null;
  }
}

// ======================================================================
// Notifier
// ======================================================================
class ColaboracionNotifier extends StateNotifier<ColaboracionState> {
  ColaboracionNotifier() : super(const ColaboracionState());

  // ==================================================================
  // Configuración inicial
  // ==================================================================
  void setMiUsuarioId(int id) {
    state = state.copyWith(miUsuarioId: id);
  }

  void setConectado(bool conectado) {
    state = state.copyWith(conectado: conectado);
  }

  // ==================================================================
  // Snapshot completo (evento sync_snapshot)
  // ==================================================================
  void setConectados(List<Map<String, dynamic>> conectados) {
    final miId = state.miUsuarioId;
    final lista = conectados
        .where((c) => c['id'] != miId)
        .map((c) {
          final id = (c['id'] as num).toInt();
          return Colaborador(
            id: id,
            nombre: c['nombre'] as String? ?? 'Usuario $id',
          );
        })
        .toList();

    state = state.copyWith(colaboradores: lista);
  }

  // ==================================================================
  // Eventos incrementales (join / leave)
  // ==================================================================
  void agregarColaborador(int id, String nombre) {
    if (id == state.miUsuarioId) return;
    if (state.colaboradorPorId(id) != null) return;

    state = state.copyWith(
      colaboradores: [
        ...state.colaboradores,
        Colaborador(id: id, nombre: nombre),
      ],
    );
  }

  void quitarColaborador(int id) {
    state = state.copyWith(
      colaboradores:
          state.colaboradores.where((c) => c.id != id).toList(),
    );
  }

  // ==================================================================
  // Cursor y selección
  // ==================================================================
  void actualizarCursor(int id, Offset posicion) {
    final actuales = state.colaboradores.map((c) {
      if (c.id != id) return c;
      return c.copyWith(cursor: posicion, tieneCursor: true);
    }).toList();
    state = state.copyWith(colaboradores: actuales);
  }

  void actualizarSeleccion(int id, String tipo, int idElemento) {
    final actuales = state.colaboradores.map((c) {
      if (c.id != id) return c;
      return c.copyWith(seleccionTipo: tipo, seleccionId: idElemento);
    }).toList();
    state = state.copyWith(colaboradores: actuales);
  }

  void limpiarSeleccion(int id) {
    final actuales = state.colaboradores.map((c) {
      if (c.id != id) return c;
      return c.copyWith(clearSeleccion: true);
    }).toList();
    state = state.copyWith(colaboradores: actuales);
  }

  // ==================================================================
  // Limpieza
  // ==================================================================
  void limpiar() {
    state = ColaboracionState(miUsuarioId: state.miUsuarioId);
  }
}

// ======================================================================
// Provider
// ======================================================================
final colaboracionProvider =
    StateNotifierProvider<ColaboracionNotifier, ColaboracionState>((ref) {
  return ColaboracionNotifier();
});

// ======================================================================
// Selectores
// ======================================================================
final conectadosCountProvider = Provider<int>((ref) {
  return ref.watch(colaboracionProvider).totalConectados;
});