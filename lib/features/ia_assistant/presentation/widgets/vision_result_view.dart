// lib/features/ia_assistant/presentation/widgets/vision_result_view.dart
//
// Vista del resultado del reconocimiento de bocetos.
//
// Muestra:
// - Confianza y cantidad de clases/relaciones detectadas.
// - Lista de clases con sus atributos.
// - Advertencias.
// - Botones: descartar / insertar en el diagrama.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/ia_entity.dart';
import '../../../diagrama_editor/presentation/providers/diagrama_provider.dart';

class VisionResultView extends ConsumerStatefulWidget {
  final VisionReconocimiento resultado;
  final VoidCallback onDescartar;

  const VisionResultView({
    super.key,
    required this.resultado,
    required this.onDescartar,
  });

  @override
  ConsumerState<VisionResultView> createState() => _VisionResultViewState();
}

class _VisionResultViewState extends ConsumerState<VisionResultView> {
  bool _insertando = false;

  /// Inserta las clases detectadas en el diagrama activo.
  Future<void> _insertar() async {
    final clases = (widget.resultado.diagramaReconstruido['clases'] as List?) ??
        [];
    if (clases.isEmpty) return;

    setState(() => _insertando = true);

    final notifier = ref.read(diagramaProvider.notifier);
    int insertadas = 0;
    int errores = 0;

    // Distribuir las clases en un grid simple para que no se superpongan
    const startX = 100.0;
    const startY = 100.0;
    const gapX = 240.0;
    const gapY = 160.0;
    const porFila = 3;

    for (var i = 0; i < clases.length; i++) {
      final c = (clases[i] as Map).cast<String, dynamic>();
      final nombre = (c['nombre'] as String?)?.trim() ?? '';
      if (nombre.isEmpty) continue;

      final col = i % porFila;
      final fila = i ~/ porFila;

      try {
        await notifier.crearClase(
          nombre: nombre,
          posX: startX + col * gapX,
          posY: startY + fila * gapY,
        );
        insertadas++;
      } catch (e) {
        errores++;
      }
    }

    setState(() => _insertando = false);

    if (!mounted) return;

    if (insertadas > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$insertadas clase${insertadas == 1 ? '' : 's'} insertada${insertadas == 1 ? '' : 's'}'
            '${errores > 0 ? ' ($errores con error)' : ''}',
          ),
        ),
      );
      widget.onDescartar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo insertar ninguna clase')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;
    final clases = (r.diagramaReconstruido['clases'] as List?) ?? [];
    final relaciones =
        (r.diagramaReconstruido['relaciones'] as List?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------- Resumen --------
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface900,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surface800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Reconocimiento',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (r.confianza != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _colorConfianza(r.confianza!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(r.confianza! * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stat(
                      label: 'Clases',
                      value: '${r.totalClases}',
                      color: AppColors.brand400,
                    ),
                    const SizedBox(width: 16),
                    _Stat(
                      label: 'Relaciones',
                      value: '${r.totalRelaciones}',
                      color: AppColors.info,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // -------- Advertencias --------
          if (r.tieneAdvertencias) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: r.advertencias.map((a) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_outlined,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // -------- Clases detectadas --------
          if (clases.isNotEmpty) ...[
            const Text(
              'Clases detectadas',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...clases.take(15).map((c) {
              final clase = (c as Map).cast<String, dynamic>();
              final nombre = (clase['nombre'] as String?) ?? '?';
              final atributos = (clase['atributos'] as List?) ?? [];
              final operaciones = (clase['operaciones'] as List?) ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface800.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${atributos.length} attr · ${operaciones.length} op',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.surface500,
                          ),
                        ),
                      ],
                    ),
                    if (atributos.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: atributos.take(5).map((a) {
                            final attr = (a as Map).cast<String, dynamic>();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              child: Text(
                                '• ${attr['nombre']}: ${attr['tipo_dato']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.surface400,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (clases.length > 15) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '… y ${clases.length - 15} clases más',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.surface500,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // -------- Botones --------
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _insertando ? null : widget.onDescartar,
                  child: const Text('Descartar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed:
                      _insertando || clases.isEmpty ? null : _insertar,
                  icon: _insertando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, size: 16),
                  label: Text(
                    _insertando
                        ? 'Insertando…'
                        : 'Insertar ${clases.length} clases',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorConfianza(double confianza) {
    if (confianza >= 0.7) return AppColors.success;
    if (confianza >= 0.4) return AppColors.warning;
    return AppColors.danger;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.surface500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}