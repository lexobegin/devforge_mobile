// lib/features/diagrama_editor/presentation/widgets/class_node.dart
//
// Caja visual de una clase UML.
//
// Renderiza:
//   ┌─────────────────────────┐
//   │ <<stereotype>>          │
//   │ NombreClase             │  (en cursiva si es abstracta)
//   ├─────────────────────────┤
//   │ - atributo: Tipo        │
//   │ + otro: Tipo            │
//   ├─────────────────────────┤
//   │ + operacion(): Tipo     │
//   └─────────────────────────┘

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/clase_uml_entity.dart';

class ClassNode extends StatelessWidget {
  final ClaseUml clase;
  final bool seleccionada;
  final Color? colorColaborador;
  final String? nombreColaborador;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(Offset delta)? onDrag;

  const ClassNode({
    super.key,
    required this.clase,
    this.seleccionada = false,
    this.colorColaborador,
    this.nombreColaborador,
    this.onTap,
    this.onLongPress,
    this.onDrag,
  });

  static const double width = 200;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onPanUpdate: onDrag != null
          ? (details) => onDrag!(details.delta)
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Caja principal
          Container(
            width: width,
            decoration: BoxDecoration(
              color: AppColors.surface900,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorColaborador ??
                    (seleccionada
                        ? AppColors.brand500
                        : AppColors.surface600),
                width: seleccionada || colorColaborador != null ? 2 : 1.5,
              ),
              boxShadow: seleccionada
                  ? [
                      BoxShadow(
                        color: AppColors.brand500.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // -------- Cabecera --------
                _Header(clase: clase),

                // -------- Atributos --------
                if (clase.atributos.isNotEmpty) ...[
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surface700),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: clase.atributos
                          .map((a) => _MiembroLine(
                                texto: '${a.visibilidad.value} ${a.nombre}',
                                tipo: a.tipoDato,
                                esEstatico: a.esEstatico,
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // -------- Operaciones --------
                if (clase.operaciones.isNotEmpty) ...[
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.surface700),
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: clase.operaciones
                          .map((op) => _MiembroLine(
                                texto:
                                    '${op.visibilidad.value} ${op.nombre}()',
                                tipo: op.tipoRetorno,
                                esEstatico: op.esEstatico,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Etiqueta de colaborador (encima de la caja)
          if (colorColaborador != null && nombreColaborador != null)
            Positioned(
              top: -20,
              left: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorColaborador,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  nombreColaborador!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================================================================
// Cabecera
// ======================================================================
class _Header extends StatelessWidget {
  final ClaseUml clase;

  const _Header({required this.clase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          if (clase.estereotipo != null &&
              clase.estereotipo!.isNotEmpty) ...[
            Text(
              '«${clase.estereotipo}»',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.surface400,
                letterSpacing: 0.5,
              ),
            ),
          ],
          Text(
            clase.nombre,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontStyle:
                  clase.esAbstracta ? FontStyle.italic : FontStyle.normal,
              color: AppColors.surface100,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Línea de atributo u operación
// ======================================================================
class _MiembroLine extends StatelessWidget {
  final String texto;
  final String tipo;
  final bool esEstatico;

  const _MiembroLine({
    required this.texto,
    required this.tipo,
    this.esEstatico = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 10, height: 1.4),
          children: [
            TextSpan(
              text: texto,
              style: TextStyle(
                color: AppColors.surface200,
                decoration:
                    esEstatico ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
            if (tipo.isNotEmpty) ...[
              const TextSpan(text: ': '),
              TextSpan(
                text: tipo,
                style: const TextStyle(color: AppColors.surface500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}