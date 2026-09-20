// lib/features/intercambio/data/intercambio_model.dart
//
// Mappers JSON ↔ entidades de Intercambio.

//import '../../domain/intercambio_entity.dart';
import '../domain/intercambio_entity.dart';

class IntercambioModel {
  const IntercambioModel._();

  // ==================================================================
  // Exportación
  // ==================================================================
  static ExportacionDiagrama exportacionFromJson(Map<String, dynamic> json) {
    return ExportacionDiagrama(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      formato: FormatoIntercambio.fromValue(
        json['formato'] as String? ?? 'XMI',
      ),
      rutaArchivo: json['ruta_archivo'] as String? ?? '',
      idUsuario: (json['id_usuario'] as num).toInt(),
      exportedAt: _parseDateTime(json['exported_at']),
    );
  }

  static ExportacionResultado exportacionResultadoFromJson(
    Map<String, dynamic> json,
  ) {
    return ExportacionResultado(
      exportacion: exportacionFromJson(
        (json['exportacion'] as Map).cast<String, dynamic>(),
      ),
      downloadUrl: json['download_url'] as String? ?? '',
    );
  }

  // ==================================================================
  // Importación
  // ==================================================================
  static ImportacionDiagrama importacionFromJson(Map<String, dynamic> json) {
    return ImportacionDiagrama(
      id: (json['id'] as num).toInt(),
      idDiagrama: (json['id_diagrama'] as num).toInt(),
      formato: FormatoIntercambio.fromValue(
        json['formato'] as String? ?? 'XMI',
      ),
      archivoOrigen: json['archivo_origen'] as String? ?? '',
      estado: EstadoImportacion.fromValue(
        json['estado'] as String? ?? 'PENDIENTE',
      ),
      idUsuario: (json['id_usuario'] as num).toInt(),
      importedAt: _parseDateTime(json['imported_at']),
    );
  }

  static ImportacionResultado importacionResultadoFromJson(
    Map<String, dynamic> json,
  ) {
    final resumenRaw =
        (json['resumen'] as Map?)?.cast<String, dynamic>() ?? {};
    final resumen = resumenRaw.map(
      (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
    );

    return ImportacionResultado(
      importacion: importacionFromJson(
        (json['importacion'] as Map).cast<String, dynamic>(),
      ),
      resumen: resumen,
    );
  }
}

// ======================================================================
// Helpers
// ======================================================================
DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value);
    } catch (_) {}
  }
  return DateTime.now();
}