// lib/features/diagrama_editor/presentation/providers/diagrama_provider.dart
//
// Provider del editor de diagramas.
//
// Mantiene:
// - El diagrama cargado (metadata + clases + relaciones + interfaces).
// - La selección actual (clase, relación o nada).
// - El modo del editor (select, addClass, addRelation).
// - El estado de guardado (isSaving) y errores.
//
// Modo offline-first:
// - Al leer, si hay red, trae del backend y cachea en SQLite.
// - Si no hay red, lee del cache local.
// - Al escribir, si falla por red, encola el cambio en la cola de sync
//   y aplica el cambio localmente con ids temporales (negativos).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/tipos_sync.dart';
import '../../data/diagrama_local_datasource.dart';
import '../../data/diagrama_remote_datasource.dart';
import '../../data/diagrama_repository.dart';
import '../../domain/clase_uml_entity.dart';
import '../../domain/diagrama_entity.dart';
import '../../domain/relacion_uml_entity.dart';

// ======================================================================
// Providers base
// ======================================================================
final diagramaRemoteDataSourceProvider =
    Provider<DiagramaRemoteDataSource>((ref) {
  return DiagramaRemoteDataSource(ref.watch(apiClientProvider));
});

final diagramaLocalDataSourceProvider =
    Provider<DiagramaLocalDataSource>((ref) {
  return DiagramaLocalDataSource(ref.watch(appDatabaseProvider));
});

final diagramaRepositoryProvider = Provider<DiagramaRepository>((ref) {
  return DiagramaRepository(
    remote: ref.watch(diagramaRemoteDataSourceProvider),
    local: ref.watch(diagramaLocalDataSourceProvider),
  );
});

// ======================================================================
// Selección
// ======================================================================
@immutable
class ElementoSeleccionado {
  final String tipo; // 'clase' | 'relacion' | 'interfaz'
  final int id;

  const ElementoSeleccionado({required this.tipo, required this.id});

  const ElementoSeleccionado.clase(int id) : this(tipo: 'clase', id: id);
  const ElementoSeleccionado.relacion(int id) : this(tipo: 'relacion', id: id);
  const ElementoSeleccionado.interfaz(int id) : this(tipo: 'interfaz', id: id);

  bool get esClase => tipo == 'clase';
  bool get esRelacion => tipo == 'relacion';
  bool get esInterfaz => tipo == 'interfaz';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ElementoSeleccionado &&
        other.tipo == tipo &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(tipo, id);
}

// ======================================================================
// Modo del editor
// ======================================================================
enum ModoEditor { select, addClass, addRelation, addInterface }

// ======================================================================
// Estado
// ======================================================================
@immutable
class DiagramaState {
  final Diagrama? diagrama;
  final List<ClaseUml> clases;
  final List<RelacionUml> relaciones;
  final List<InterfazUml> interfaces;

  final ElementoSeleccionado? seleccion;
  final ModoEditor modo;

  final bool isLoading;
  final bool isSaving;
  final ApiError? error;

  const DiagramaState({
    this.diagrama,
    this.clases = const [],
    this.relaciones = const [],
    this.interfaces = const [],
    this.seleccion,
    this.modo = ModoEditor.select,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  DiagramaState copyWith({
    Diagrama? diagrama,
    List<ClaseUml>? clases,
    List<RelacionUml>? relaciones,
    List<InterfazUml>? interfaces,
    ElementoSeleccionado? seleccion,
    ModoEditor? modo,
    bool? isLoading,
    bool? isSaving,
    ApiError? error,
    bool clearError = false,
    bool clearSeleccion = false,
  }) {
    return DiagramaState(
      diagrama: diagrama ?? this.diagrama,
      clases: clases ?? this.clases,
      relaciones: relaciones ?? this.relaciones,
      interfaces: interfaces ?? this.interfaces,
      seleccion: clearSeleccion ? null : (seleccion ?? this.seleccion),
      modo: modo ?? this.modo,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // ==================================================================
  // Getters derivados
  // ==================================================================
  ClaseUml? get claseSeleccionada {
    if (seleccion == null || !seleccion!.esClase) return null;
    for (final c in clases) {
      if (c.id == seleccion!.id) return c;
    }
    return null;
  }

  RelacionUml? get relacionSeleccionada {
    if (seleccion == null || !seleccion!.esRelacion) return null;
    for (final r in relaciones) {
      if (r.id == seleccion!.id) return r;
    }
    return null;
  }

  ClaseUml? clasePorId(int id) {
    for (final c in clases) {
      if (c.id == id) return c;
    }
    return null;
  }
}

// ======================================================================
// Notifier
// ======================================================================
class DiagramaNotifier extends StateNotifier<DiagramaState> {
  DiagramaNotifier(this._repo, this._syncQueue)
      : super(const DiagramaState());

  final DiagramaRepository _repo;
  final SyncQueue _syncQueue;

  // ==================================================================
  // Cargar
  // ==================================================================
  Future<void> cargar(int diagramaId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final completo = await _repo.obtenerCompleto(diagramaId);
      state = DiagramaState(
        diagrama: completo.diagrama,
        clases: completo.clases,
        relaciones: completo.relaciones,
        interfaces: completo.interfaces,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiError.unknown(e.toString()),
      );
    }
  }

  void limpiar() {
    state = const DiagramaState();
  }

  // ==================================================================
  // Selección y modo
  // ==================================================================
  void seleccionar(ElementoSeleccionado? elemento) {
    state = elemento == null
        ? state.copyWith(clearSeleccion: true)
        : state.copyWith(seleccion: elemento);
  }

  void setModo(ModoEditor modo) {
    state = state.copyWith(modo: modo);
  }

  // ==================================================================
  // Clases
  // ==================================================================
  Future<ClaseUml> crearClase({
    required String nombre,
    double? posX,
    double? posY,
  }) async {
    final diagrama = state.diagrama;
    if (diagrama == null) throw StateError('No hay diagrama activo');

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final clase = await _repo.crearClase(
        diagrama.id,
        nombre: nombre,
        posX: posX,
        posY: posY,
      );
      state = state.copyWith(
        clases: [...state.clases, clase],
        isSaving: false,
      );
      return clase;
    } on ApiException catch (e) {
      // Sin red: encolar y crear clase temporal local
      if (e.status == 0) {
        await _syncQueue.encolar(
          idDiagrama: diagrama.id,
          tipoOperacion: TipoOperacionSync.crearClase,
          payload: {
            'nombre': nombre,
            'pos_x': posX ?? 0,
            'pos_y': posY ?? 0,
          },
        );

        final claseTemporal = ClaseUml(
          id: -DateTime.now().millisecondsSinceEpoch,
          idDiagrama: diagrama.id,
          nombre: nombre,
          posX: posX ?? 0,
          posY: posY ?? 0,
          idCreador: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        state = state.copyWith(
          clases: [...state.clases, claseTemporal],
          isSaving: false,
        );
        return claseTemporal;
      }

      // Otro error: propagar
      state = state.copyWith(
        isSaving: false,
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: ApiError.unknown(e.toString()),
      );
      rethrow;
    }
  }

  Future<void> actualizarClase(
    int id, {
    String? nombre,
    bool? esAbstracta,
    String? estereotipo,
    double? posX,
    double? posY,
  }) async {
    final anterior = state.clasePorId(id);
    if (anterior == null) return;

    // Optimistic update
    state = state.copyWith(
      clases: state.clases.map((c) {
        if (c.id != id) return c;
        return c.copyWith(
          nombre: nombre,
          esAbstracta: esAbstracta,
          estereotipo: estereotipo,
          posX: posX,
          posY: posY,
        );
      }).toList(),
    );

    // Si la clase es temporal (negativa), no llamar al backend
    if (id < 0) return;

    try {
      final actualizada = await _repo.actualizarClase(
        id,
        nombre: nombre,
        esAbstracta: esAbstracta,
        estereotipo: estereotipo,
        posX: posX,
        posY: posY,
      );
      state = state.copyWith(
        clases: state.clases
            .map((c) => c.id == id ? actualizada : c)
            .toList(),
      );
    } on ApiException catch (e) {
      if (e.status == 0) {
        final diagrama = state.diagrama;
        if (diagrama != null) {
          await _syncQueue.encolar(
            idDiagrama: diagrama.id,
            tipoOperacion: TipoOperacionSync.modificarClase,
            payload: {
              'id_clase': id,
              if (nombre != null) 'nombre': nombre,
              if (esAbstracta != null) 'es_abstracta': esAbstracta,
              if (estereotipo != null) 'estereotipo': estereotipo,
              if (posX != null) 'pos_x': posX,
              if (posY != null) 'pos_y': posY,
            },
          );
        }
        return;
      }

      // Rollback
      state = state.copyWith(
        clases: state.clases
            .map((c) => c.id == id ? anterior : c)
            .toList(),
        error: ApiError(status: e.status, code: e.code, detail: e.detail),
      );
    }
  }

  /// Actualiza solo la posición local (durante un drag).
  /// No persiste al backend: eso lo hace `persistirPosicionClase()` al soltar.
  void moverClaseLocal(int id, double posX, double posY) {
    state = state.copyWith(
      clases: state.clases.map((c) {
        if (c.id != id) return c;
        return c.copyWith(posX: posX, posY: posY);
      }).toList(),
    );
  }

  /// Persiste la posición tras un drag (llamado en onDragStop).
  Future<void> persistirPosicionClase(int id) async {
    final clase = state.clasePorId(id);
    if (clase == null) return;

    // Si es una clase temporal, no persistir
    if (id < 0) return;

    try {
      await _repo.actualizarClase(
        id,
        posX: clase.posX,
        posY: clase.posY,
      );
    } on ApiException catch (e) {
      if (e.status == 0) {
        final diagrama = state.diagrama;
        if (diagrama != null) {
          await _syncQueue.encolar(
            idDiagrama: diagrama.id,
            tipoOperacion: TipoOperacionSync.modificarClase,
            payload: {
              'id_clase': id,
              'pos_x': clase.posX,
              'pos_y': clase.posY,
            },
          );
        }
      }
      // Silencioso: la posición se reintentará en la próxima sincronización
    }
  }

  Future<void> eliminarClase(int id) async {
    final diagrama = state.diagrama;
    if (diagrama == null) return;

    final clasesAnteriores = state.clases;
    final relacionesAnteriores = state.relaciones;

    // Optimistic: quitar clase y relaciones asociadas
    state = state.copyWith(
      clases: state.clases.where((c) => c.id != id).toList(),
      relaciones: state.relaciones
          .where((r) =>
              r.idClaseOrigen != id && r.idClaseDestino != id)
          .toList(),
      clearSeleccion: state.seleccion?.id == id,
    );

    // Si es temporal, no encolar
    if (id < 0) return;

    try {
      await _repo.eliminarClase(id);
    } on ApiException catch (e) {
      if (e.status == 0) {
        await _syncQueue.encolar(
          idDiagrama: diagrama.id,
          tipoOperacion: TipoOperacionSync.eliminarClase,
          payload: {'id_clase': id},
        );
      } else {
        // Rollback
        state = state.copyWith(
          clases: clasesAnteriores,
          relaciones: relacionesAnteriores,
          error: ApiError(
            status: e.status,
            code: e.code,
            detail: e.detail,
          ),
        );
      }
    }
  }

  // ==================================================================
  // Atributos
  // ==================================================================
  Future<void> agregarAtributo(
    int claseId, {
    required String nombre,
    required String tipoDato,
  }) async {
    final diagrama = state.diagrama;
    if (diagrama == null) return;

    try {
      final atributo = await _repo.agregarAtributo(
        claseId,
        nombre: nombre,
        tipoDato: tipoDato,
      );
      state = state.copyWith(
        clases: state.clases.map((c) {
          if (c.id != claseId) return c;
          return c.copyWith(atributos: [...c.atributos, atributo]);
        }).toList(),
      );
    } on ApiException catch (e) {
      if (e.status == 0) {
        await _syncQueue.encolar(
          idDiagrama: diagrama.id,
          tipoOperacion: TipoOperacionSync.agregarAtributo,
          payload: {
            'id_clase': claseId,
            'nombre': nombre,
            'tipo_dato': tipoDato,
          },
        );

        // Agregar atributo temporal local
        final attrTemporal = AtributoUml(
          id: -DateTime.now().millisecondsSinceEpoch,
          idClase: claseId,
          nombre: nombre,
          tipoDato: tipoDato,
        );

        state = state.copyWith(
          clases: state.clases.map((c) {
            if (c.id != claseId) return c;
            return c.copyWith(atributos: [...c.atributos, attrTemporal]);
          }).toList(),
        );
      } else {
        state = state.copyWith(
          error: ApiError(
            status: e.status,
            code: e.code,
            detail: e.detail,
          ),
        );
      }
    }
  }

  Future<void> eliminarAtributo(int claseId, int atributoId) async {
    final anterior = state.clasePorId(claseId);
    if (anterior == null) return;

    state = state.copyWith(
      clases: state.clases.map((c) {
        if (c.id != claseId) return c;
        return c.copyWith(
          atributos: c.atributos.where((a) => a.id != atributoId).toList(),
        );
      }).toList(),
    );

    // Si es temporal, no llamar al backend
    if (atributoId < 0) return;

    try {
      await _repo.eliminarAtributo(atributoId);
    } on ApiException catch (e) {
      if (e.status == 0) {
        final diagrama = state.diagrama;
        if (diagrama != null) {
          await _syncQueue.encolar(
            idDiagrama: diagrama.id,
            tipoOperacion: TipoOperacionSync.eliminarAtributo,
            payload: {'id_atributo': atributoId},
          );
        }
      } else {
        state = state.copyWith(
          clases: state.clases
              .map((c) => c.id == claseId ? anterior : c)
              .toList(),
        );
      }
    }
  }

  // ==================================================================
  // Relaciones
  // ==================================================================
  Future<RelacionUml> crearRelacion({
    required int idClaseOrigen,
    required int idClaseDestino,
    TipoRelacion tipo = TipoRelacion.asociacion,
    String? multiplicidadOrigen,
    String? multiplicidadDestino,
  }) async {
    final diagrama = state.diagrama;
    if (diagrama == null) throw StateError('No hay diagrama activo');

    try {
      final relacion = await _repo.crearRelacion(
        diagrama.id,
        idClaseOrigen: idClaseOrigen,
        idClaseDestino: idClaseDestino,
        tipoRelacion: tipo.value,
        multiplicidadOrigen: multiplicidadOrigen,
        multiplicidadDestino: multiplicidadDestino,
      );
      state = state.copyWith(relaciones: [...state.relaciones, relacion]);
      return relacion;
    } on ApiException catch (e) {
      if (e.status == 0) {
        await _syncQueue.encolar(
          idDiagrama: diagrama.id,
          tipoOperacion: TipoOperacionSync.crearRelacion,
          payload: {
            'id_clase_origen': idClaseOrigen,
            'id_clase_destino': idClaseDestino,
            'tipo_relacion': tipo.value,
            'multiplicidad_origen': multiplicidadOrigen,
            'multiplicidad_destino': multiplicidadDestino,
          },
        );

        final relTemporal = RelacionUml(
          id: -DateTime.now().millisecondsSinceEpoch,
          idDiagrama: diagrama.id,
          idClaseOrigen: idClaseOrigen,
          idClaseDestino: idClaseDestino,
          tipoRelacion: tipo,
          multiplicidadOrigen: multiplicidadOrigen,
          multiplicidadDestino: multiplicidadDestino,
        );

        state = state.copyWith(
          relaciones: [...state.relaciones, relTemporal],
        );
        return relTemporal;
      }
      rethrow;
    }
  }

  Future<void> actualizarRelacion(
    int id, {
    TipoRelacion? tipo,
    String? multiplicidadOrigen,
    String? multiplicidadDestino,
    String? nombreAsociacion,
    String? rolOrigen,
    String? rolDestino,
  }) async {
    try {
      final actualizada = await _repo.actualizarRelacion(
        id,
        tipoRelacion: tipo?.value,
        multiplicidadOrigen: multiplicidadOrigen,
        multiplicidadDestino: multiplicidadDestino,
        nombreAsociacion: nombreAsociacion,
        rolOrigen: rolOrigen,
        rolDestino: rolDestino,
      );
      state = state.copyWith(
        relaciones: state.relaciones
            .map((r) => r.id == id ? actualizada : r)
            .toList(),
      );
    } on ApiException catch (e) {
      if (e.status == 0) {
        final diagrama = state.diagrama;
        if (diagrama != null) {
          await _syncQueue.encolar(
            idDiagrama: diagrama.id,
            tipoOperacion: TipoOperacionSync.modificarRelacion,
            payload: {
              'id_relacion': id,
              if (tipo != null) 'tipo_relacion': tipo.value,
              if (multiplicidadOrigen != null)
                'multiplicidad_origen': multiplicidadOrigen,
              if (multiplicidadDestino != null)
                'multiplicidad_destino': multiplicidadDestino,
              if (nombreAsociacion != null)
                'nombre_asociacion': nombreAsociacion,
              if (rolOrigen != null) 'rol_origen': rolOrigen,
              if (rolDestino != null) 'rol_destino': rolDestino,
            },
          );
        }
      } else {
        state = state.copyWith(
          error: ApiError(
            status: e.status,
            code: e.code,
            detail: e.detail,
          ),
        );
      }
    }
  }

  Future<void> eliminarRelacion(int id) async {
    final diagrama = state.diagrama;
    if (diagrama == null) return;

    final anteriores = state.relaciones;
    state = state.copyWith(
      relaciones: state.relaciones.where((r) => r.id != id).toList(),
      clearSeleccion: state.seleccion?.id == id,
    );

    if (id < 0) return;

    try {
      await _repo.eliminarRelacion(id);
    } on ApiException catch (e) {
      if (e.status == 0) {
        await _syncQueue.encolar(
          idDiagrama: diagrama.id,
          tipoOperacion: TipoOperacionSync.eliminarRelacion,
          payload: {'id_relacion': id},
        );
      } else {
        state = state.copyWith(relaciones: anteriores);
      }
    }
  }

  // ==================================================================
  // Cambios remotos (desde WebSocket)
  // ==================================================================
  void aplicarClaseRemota(ClaseUml clase) {
    final existe = state.clases.any((c) => c.id == clase.id);
    state = state.copyWith(
      clases: existe
          ? state.clases.map((c) => c.id == clase.id ? clase : c).toList()
          : [...state.clases, clase],
    );
  }

  void aplicarClaseEliminada(int claseId) {
    state = state.copyWith(
      clases: state.clases.where((c) => c.id != claseId).toList(),
      relaciones: state.relaciones
          .where((r) =>
              r.idClaseOrigen != claseId && r.idClaseDestino != claseId)
          .toList(),
    );
  }

  void aplicarRelacionRemota(RelacionUml relacion) {
    final existe = state.relaciones.any((r) => r.id == relacion.id);
    state = state.copyWith(
      relaciones: existe
          ? state.relaciones
              .map((r) => r.id == relacion.id ? relacion : r)
              .toList()
          : [...state.relaciones, relacion],
    );
  }

  void aplicarRelacionEliminada(int relacionId) {
    state = state.copyWith(
      relaciones:
          state.relaciones.where((r) => r.id != relacionId).toList(),
    );
  }

  // ==================================================================
  // Mapeo de ids temporales → reales (tras sync)
  // ==================================================================
  /// Aplica un mapeo de ids temporales (negativos) a ids reales del
  /// backend, luego de una sincronización exitosa.
  ///
  /// El backend devuelve `{id_temporal_local: id_real}`. Como el id
  /// temporal es un string y no lo guardamos en la clase, usamos el
  /// orden de creación: las clases con id negativo se reasignan a los
  /// ids reales en orden.
  Future<void> aplicarMapeoIds(Map<String, int> mapeo) async {
    if (mapeo.isEmpty) return;

    // Tomar las clases con id negativo (creadas offline) en orden
    final clasesNegativas =
        state.clases.where((c) => c.id < 0).toList();
    final relacionesNegativas =
        state.relaciones.where((r) => r.id < 0).toList();

    // Los ids reales en orden
    final idsReales = mapeo.values.toList();

    // Mapear clases por posición
    final mapaClases = <int, int>{};
    for (var i = 0;
        i < clasesNegativas.length && i < idsReales.length;
        i++) {
      mapaClases[clasesNegativas[i].id] = idsReales[i];
    }

    // Actualizar clases
    final nuevasClases = state.clases.map((c) {
      if (mapaClases.containsKey(c.id)) {
        return c.copyWith(id: mapaClases[c.id]);
      }
      return c;
    }).toList();

    // Actualizar relaciones (origen y destino apuntando a clases reales)
    // y reasignar relaciones temporales.
    final nuevasRelaciones = <RelacionUml>[];
    var relIndex = 0;

    for (final r in state.relaciones) {
      final nuevoOrigen = mapaClases[r.idClaseOrigen];
      final nuevoDestino = mapaClases[r.idClaseDestino];

      var nuevaRel = r;

      if (nuevoOrigen != null || nuevoDestino != null) {
        nuevaRel = nuevaRel.copyWith(
          idClaseOrigen: nuevoOrigen ?? r.idClaseOrigen,
          idClaseDestino: nuevoDestino ?? r.idClaseDestino,
        );
      }

      // Si la relación es temporal (id negativo), reasignar
      if (r.id < 0 && relIndex < relacionesNegativas.length) {
        // Buscar un id real disponible (el primero que no hayamos usado
        // para relaciones). Como no tenemos un mapeo explícito para
        // relaciones, usamos el siguiente id real que no esté ya en uso.
        final idsEnUso = nuevasRelaciones.map((nr) => nr.id).toSet();
        int? nuevoId;
        for (final id in idsReales) {
          if (!idsEnUso.contains(id) && !mapaClases.containsValue(id)) {
            nuevoId = id;
            break;
          }
        }
        if (nuevoId != null) {
          nuevaRel = nuevaRel.copyWith(id: nuevoId);
        }
        relIndex++;
      }

      nuevasRelaciones.add(nuevaRel);
    }

    state = state.copyWith(
      clases: nuevasClases,
      relaciones: nuevasRelaciones,
    );
  }

  // ==================================================================
  // Limpiar error
  // ==================================================================
  void limpiarError() => state = state.copyWith(clearError: true);
}

// ======================================================================
// Provider principal
// ======================================================================
final diagramaProvider =
    StateNotifierProvider<DiagramaNotifier, DiagramaState>((ref) {
  return DiagramaNotifier(
    ref.watch(diagramaRepositoryProvider),
    ref.watch(syncQueueProvider),
  );
});

// ======================================================================
// Selectores útiles
// ======================================================================
final claseSeleccionadaProvider = Provider<ClaseUml?>((ref) {
  return ref.watch(diagramaProvider).claseSeleccionada;
});

final relacionSeleccionadaProvider = Provider<RelacionUml?>((ref) {
  return ref.watch(diagramaProvider).relacionSeleccionada;
});

final clasesProvider = Provider<List<ClaseUml>>((ref) {
  return ref.watch(diagramaProvider).clases;
});

final relacionesProvider = Provider<List<RelacionUml>>((ref) {
  return ref.watch(diagramaProvider).relaciones;
});