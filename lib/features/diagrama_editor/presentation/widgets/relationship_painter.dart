// lib/features/diagrama_editor/presentation/widgets/relationship_painter.dart
//
// CustomPainter que dibuja todas las relaciones UML entre clases.
//
// Se dibuja POR DEBAJO de los nodos en el Stack, para que las líneas
// queden "detrás" de las cajas.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/clase_uml_entity.dart';
import '../../domain/relacion_uml_entity.dart';

class RelationshipPainter extends CustomPainter {
  final List<ClaseUml> clases;
  final List<RelacionUml> relaciones;
  final int? seleccionadaId;

  /// Dimensiones aproximadas del nodo (para calcular los bordes de las cajas).
  static const double nodeWidth = 200;
  static const double nodeHeightApprox = 100;

  RelationshipPainter({
    required this.clases,
    required this.relaciones,
    this.seleccionadaId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final relacion in relaciones) {
      final origen = _clasePorId(relacion.idClaseOrigen);
      final destino = _clasePorId(relacion.idClaseDestino);
      if (origen == null || destino == null) continue;

      final seleccionada = relacion.id == seleccionadaId;
      _dibujarRelacion(canvas, origen, destino, relacion, seleccionada);
    }
  }

  // ==================================================================
  // Dibujo de una relación
  // ==================================================================
  void _dibujarRelacion(
    Canvas canvas,
    ClaseUml origen,
    ClaseUml destino,
    RelacionUml relacion,
    bool seleccionada,
  ) {
    // Calcular puntos de anclaje (centro de cada caja)
    final c1 = Offset(origen.posX + nodeWidth / 2, origen.posY + 50);
    final c2 = Offset(destino.posX + nodeWidth / 2, destino.posY + 50);

    final color = seleccionada ? AppColors.brand400 : AppColors.surface500;
    final paint = Paint()
      ..color = color
      ..strokeWidth = seleccionada ? 2.5 : 1.8
      ..style = PaintingStyle.stroke;

    // Aplicar estilo según tipo
    if (relacion.tipoRelacion == TipoRelacion.dependencia ||
        relacion.tipoRelacion == TipoRelacion.realizacion) {
      _dibujarLineaDiscontinua(canvas, c1, c2, paint);
    } else {
      canvas.drawLine(c1, c2, paint);
    }

    // Extremo decorativo
    _dibujarExtremo(canvas, c2, c1, relacion.tipoRelacion, color);

    // Multiplicidades
    _dibujarMultiplicidades(canvas, c1, c2, relacion);

    // Nombre de la asociación (si lo hay)
    if (relacion.nombreAsociacion != null &&
        relacion.nombreAsociacion!.isNotEmpty) {
      _dibujarTextoCentro(canvas, c1, c2, relacion.nombreAsociacion!);
    }
  }

  // ==================================================================
  // Extremos según tipo
  // ==================================================================
  void _dibujarExtremo(
    Canvas canvas,
    Offset punta,
    Offset desde,
    TipoRelacion tipo,
    Color color,
  ) {
    final angulo = math.atan2(punta.dy - desde.dy, punta.dx - desde.dx);

    switch (tipo) {
      case TipoRelacion.generalizacion:
      case TipoRelacion.realizacion:
        _dibujarTrianguloHueco(canvas, punta, angulo, color);
        break;
      case TipoRelacion.composicion:
        _dibujarDiamante(canvas, desde, angulo, color, relleno: true);
        break;
      case TipoRelacion.agregacion:
        _dibujarDiamante(canvas, desde, angulo, color, relleno: false);
        break;
      case TipoRelacion.asociacion:
      case TipoRelacion.dependencia:
        _dibujarFlechaAbierta(canvas, punta, angulo, color);
        break;
    }
  }

  void _dibujarTrianguloHueco(
    Canvas canvas,
    Offset punta,
    double angulo,
    Color color,
  ) {
    const tam = 12.0;
    final p1 = punta;
    final p2 = punta +
        Offset(
          -tam * math.cos(angulo - math.pi / 6),
          -tam * math.sin(angulo - math.pi / 6),
        );
    final p3 = punta +
        Offset(
          -tam * math.cos(angulo + math.pi / 6),
          -tam * math.sin(angulo + math.pi / 6),
        );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.surface900
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _dibujarDiamante(
    Canvas canvas,
    Offset centro,
    double angulo,
    Color color, {
    bool relleno = false,
  }) {
    const tam = 10.0;
    final p1 = centro +
        Offset(tam * math.cos(angulo), tam * math.sin(angulo));
    final p2 = centro +
        Offset(
          tam * 0.7 * math.cos(angulo + math.pi / 2),
          tam * 0.7 * math.sin(angulo + math.pi / 2),
        );
    final p3 = centro +
        Offset(
          -tam * 0.3 * math.cos(angulo),
          -tam * 0.3 * math.sin(angulo),
        );
    final p4 = centro +
        Offset(
          tam * 0.7 * math.cos(angulo - math.pi / 2),
          tam * 0.7 * math.sin(angulo - math.pi / 2),
        );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = relleno ? color : AppColors.surface900
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _dibujarFlechaAbierta(
    Canvas canvas,
    Offset punta,
    double angulo,
    Color color,
  ) {
    const tam = 10.0;
    final p1 = punta +
        Offset(
          -tam * math.cos(angulo - math.pi / 6),
          -tam * math.sin(angulo - math.pi / 6),
        );
    final p2 = punta +
        Offset(
          -tam * math.cos(angulo + math.pi / 6),
          -tam * math.sin(angulo + math.pi / 6),
        );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(punta, p1, paint);
    canvas.drawLine(punta, p2, paint);
  }

  // ==================================================================
  // Multiplicidades
  // ==================================================================
  void _dibujarMultiplicidades(
    Canvas canvas,
    Offset c1,
    Offset c2,
    RelacionUml relacion,
  ) {
    if (relacion.multiplicidadOrigen != null) {
      final pos = Offset.lerp(c1, c2, 0.15)!;
      _dibujarTexto(canvas, pos, relacion.multiplicidadOrigen!);
    }
    if (relacion.multiplicidadDestino != null) {
      final pos = Offset.lerp(c1, c2, 0.85)!;
      _dibujarTexto(canvas, pos, relacion.multiplicidadDestino!);
    }
  }

  void _dibujarTexto(Canvas canvas, Offset pos, String texto) {
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(
          color: AppColors.surface400,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Fondo
    final rect = Rect.fromLTWH(
      pos.dx - painter.width / 2 - 2,
      pos.dy - painter.height / 2 - 1,
      painter.width + 4,
      painter.height + 2,
    );
    canvas.drawRect(
      rect,
      Paint()..color = AppColors.surface950.withValues(alpha: 0.85),
    );

    painter.paint(
      canvas,
      Offset(pos.dx - painter.width / 2, pos.dy - painter.height / 2),
    );
  }

  void _dibujarTextoCentro(
    Canvas canvas,
    Offset c1,
    Offset c2,
    String texto,
  ) {
    final centro = Offset.lerp(c1, c2, 0.5)!;

    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: const TextStyle(
          color: AppColors.surface300,
          fontSize: 10,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromLTWH(
      centro.dx - painter.width / 2 - 3,
      centro.dy - painter.height / 2 - 1,
      painter.width + 6,
      painter.height + 2,
    );
    canvas.drawRect(
      rect,
      Paint()..color = AppColors.surface950,
    );

    painter.paint(
      canvas,
      Offset(centro.dx - painter.width / 2, centro.dy - painter.height / 2),
    );
  }

  // ==================================================================
  // Línea discontinua
  // ==================================================================
  void _dibujarLineaDiscontinua(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
  ) {
    const dash = 6.0;
    const gap = 4.0;
    final total = (p2 - p1).distance;
    final dir = (p2 - p1) / total;

    double recorrido = 0;
    while (recorrido < total) {
      final start = p1 + dir * recorrido;
      final end = p1 + dir * math.min(recorrido + dash, total);
      canvas.drawLine(start, end, paint);
      recorrido += dash + gap;
    }
  }

  // ==================================================================
  // Helpers
  // ==================================================================
  ClaseUml? _clasePorId(int id) {
    for (final c in clases) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant RelationshipPainter oldDelegate) {
    return oldDelegate.clases != clases ||
        oldDelegate.relaciones != relaciones ||
        oldDelegate.seleccionadaId != seleccionadaId;
  }
}