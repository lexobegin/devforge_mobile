// lib/features/diagrama_editor/presentation/widgets/diagram_canvas.dart
//
// Canvas del editor.
//
// Usa InteractiveViewer para pan/zoom. Dentro, un Stack posiciona:
//   1. Un CustomPaint con todas las relaciones (abajo).
//   2. Los ClassNode en sus posiciones (arriba).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../colaboracion/presentation/providers/colaboracion_provider.dart';
import '../../domain/clase_uml_entity.dart';
import '../../domain/relacion_uml_entity.dart';
import '../providers/diagrama_provider.dart';
import 'class_node.dart';
import 'relationship_painter.dart';

class DiagramCanvas extends ConsumerStatefulWidget {
  final TransformationController controller;
  final void Function(Offset flowPosition) onCanvasTap;

  const DiagramCanvas({
    super.key,
    required this.controller,
    required this.onCanvasTap,
  });

  @override
  ConsumerState<DiagramCanvas> createState() => _DiagramCanvasState();
}

class _DiagramCanvasState extends ConsumerState<DiagramCanvas> {
  // Tamaño del "lienzo lógico". Es grande para permitir mucho espacio.
  static const double canvasWidth = 3000;
  static const double canvasHeight = 3000;

  @override
  Widget build(BuildContext context) {
    final clases = ref.watch(clasesProvider);
    final relaciones = ref.watch(relacionesProvider);

    // LOG TEMPORAL
    print('[CANVAS] clases=${clases.length} relaciones=${relaciones.length}');

    final seleccion = ref.watch(diagramaProvider).seleccion;
    final colaboradores = ref.watch(colaboracionProvider).colaboradores;

    return InteractiveViewer(
      transformationController: widget.controller,
      minScale: 0.3,
      maxScale: 3.0,
      boundaryMargin: const EdgeInsets.all(200),
      constrained: false,
      child: GestureDetector(
        onTapUp: (details) {
          // Convertir posición de pantalla a coordenadas del lienzo
          widget.onCanvasTap(details.localPosition);
        },
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // -------- Fondo con grid --------
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),

              // -------- Relaciones (CustomPaint) --------
              Positioned.fill(
                child: CustomPaint(
                  painter: RelationshipPainter(
                    clases: clases,
                    relaciones: relaciones,
                    seleccionadaId: seleccion?.esRelacion == true
                        ? seleccion!.id
                        : null,
                  ),
                ),
              ),

              // -------- Nodos --------
              for (final clase in clases)
                Positioned(
                  left: clase.posX,
                  top: clase.posY,
                  child: _NodoClase(
                    clase: clase,
                    seleccionada: seleccion?.esClase == true &&
                        seleccion!.id == clase.id,
                    colaboradorSeleccionando: _colaboradorQueSelecciona(
                      clase.id,
                      colaboradores,
                    ),
                  ),
                ),

              // -------- Cursores remotos --------
              for (final colab in colaboradores)
                if (colab.tieneCursor)
                  Positioned(
                    left: colab.cursor.dx,
                    top: colab.cursor.dy,
                    child: _CursorRemoto(
                      color: colab.color,
                      nombre: colab.nombre,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Colaborador? _colaboradorQueSelecciona(
    int claseId,
    List<Colaborador> colaboradores,
  ) {
    for (final c in colaboradores) {
      if (c.seleccionTipo == 'clase' && c.seleccionId == claseId) {
        return c;
      }
    }
    return null;
  }
}

// ======================================================================
// Nodo con drag
// ======================================================================
class _NodoClase extends ConsumerStatefulWidget {
  final ClaseUml clase;
  final bool seleccionada;
  final Colaborador? colaboradorSeleccionando;

  const _NodoClase({
    required this.clase,
    required this.seleccionada,
    this.colaboradorSeleccionando,
  });

  @override
  ConsumerState<_NodoClase> createState() => _NodoClaseState();
}

class _NodoClaseState extends ConsumerState<_NodoClase> {
  @override
  Widget build(BuildContext context) {
    return ClassNode(
      clase: widget.clase,
      seleccionada: widget.seleccionada,
      colorColaborador: widget.colaboradorSeleccionando?.color,
      nombreColaborador: widget.colaboradorSeleccionando?.nombre,
      onTap: () {
        ref.read(diagramaProvider.notifier).seleccionar(
              ElementoSeleccionado.clase(widget.clase.id),
            );
      },
      onDrag: (delta) {
        final notifier = ref.read(diagramaProvider.notifier);
        notifier.moverClaseLocal(
          widget.clase.id,
          widget.clase.posX + delta.dx,
          widget.clase.posY + delta.dy,
        );
      },
    );
  }
}

// ======================================================================
// Cursor remoto
// ======================================================================
class _CursorRemoto extends StatelessWidget {
  final Color color;
  final String nombre;

  const _CursorRemoto({required this.color, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.navigation, color: color, size: 20),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Grid de fondo
// ======================================================================
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 24.0;
    final paint = Paint()
      ..color = AppColors.surface800.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}