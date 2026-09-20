// lib/features/intercambio/domain/intercambio_entity.dart
//
// Entidades: ExportacionDiagrama, ImportacionDiagrama y resultados.

import 'package:flutter/foundation.dart';

// ======================================================================
// Enums
// ======================================================================
enum FormatoIntercambio {
  xmi('XMI', 'XMI (DevForge)'),
  xml('XML', 'XML (DevForge)'),
  ea('EA', 'XMI 1.1 (Enterprise Architect)');

  const FormatoIntercambio(this.value, this.label);

  final String value;
  final String label;

  static FormatoIntercambio fromValue(String value) {
    return FormatoIntercambio.values.firstWhere(
      (f) => f.value == value.toUpperCase(),
      orElse: () => FormatoIntercambio.xmi,
    );
  }
}

enum EstadoImportacion {
  pendiente('PENDIENTE', 'Pendiente'),
  exitoso('EXITOSO', 'Exitoso'),
  fallido('FALLIDO', 'Fallido');

  const EstadoImportacion(this.value, this.label);

  final String value;
  final String label;

  static EstadoImportacion fromValue(String value) {
    return EstadoImportacion.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoImportacion.pendiente,
    );
  }
}

// ======================================================================
// Exportación
// ======================================================================
@immutable
class ExportacionDiagrama {
  final int id;
  final int idDiagrama;
  final FormatoIntercambio formato;
  final String rutaArchivo;
  final int idUsuario;
  final DateTime exportedAt;

  const ExportacionDiagrama({
    required this.id,
    required this.idDiagrama,
    required this.formato,
    required this.rutaArchivo,
    required this.idUsuario,
    required this.exportedAt,
  });
}

@immutable
class ExportacionResultado {
  final ExportacionDiagrama exportacion;
  final String downloadUrl;

  const ExportacionResultado({
    required this.exportacion,
    required this.downloadUrl,
  });
}

// ======================================================================
// Importación
// ======================================================================
@immutable
class ImportacionDiagrama {
  final int id;
  final int idDiagrama;
  final FormatoIntercambio formato;
  final String archivoOrigen;
  final EstadoImportacion estado;
  final int idUsuario;
  final DateTime importedAt;

  const ImportacionDiagrama({
    required this.id,
    required this.idDiagrama,
    required this.formato,
    required this.archivoOrigen,
    required this.estado,
    required this.idUsuario,
    required this.importedAt,
  });
}

@immutable
class ImportacionResultado {
  final ImportacionDiagrama importacion;

  /// Resumen devuelto por el backend:
  /// { "clases_insertadas": 3, "relaciones_insertadas": 5, ... }
  final Map<String, int> resumen;

  const ImportacionResultado({
    required this.importacion,
    required this.resumen,
  });

  int get totalInsertados => resumen.values.fold(0, (a, b) => a + b);
}