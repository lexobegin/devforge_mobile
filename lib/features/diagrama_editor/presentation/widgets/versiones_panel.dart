// lib/features/diagrama_editor/presentation/widgets/versiones_panel.dart
//
// Panel de versiones guardadas del diagrama.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../trazabilidad/presentation/providers/trazabilidad_provider.dart';
import '../providers/diagrama_provider.dart';

class VersionesPanel extends ConsumerStatefulWidget {
  final int diagramaId;

  const VersionesPanel({super.key, required this.diagramaId});

  @override
  ConsumerState<VersionesPanel> createState() => _VersionesPanelState();
}

class _VersionesPanelState extends ConsumerState<VersionesPanel> {
  bool _guardando = false;

  Future<void> _guardarVersion() async {
    final comentario = await _pedirComentario();
    if (comentario == null) return;

    setState(() => _guardando = true);
    try {
      final diagramaState = ref.read(diagramaProvider);
      final contenido = {
        'clases': diagramaState.clases.map((c) => {
              'id': c.id,
              'nombre': c.nombre,
              'pos_x': c.posX,
              'pos_y': c.posY,
            }).toList(),
        'relaciones': diagramaState.relaciones.map((r) => {
              'id': r.id,
              'origen': r.idClaseOrigen,
              'destino': r.idClaseDestino,
              'tipo': r.tipoRelacion.value,
            }).toList(),
      };

      await ref
          .read(trazabilidadRepositoryProvider)
          .guardarVersion(
            widget.diagramaId,
            contenidoJson: contenido,
            comentario: comentario.isEmpty ? null : comentario,
          );

      ref.invalidate(versionesProvider(widget.diagramaId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versión guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<String?> _pedirComentario() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar versión'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Comentario (opcional)',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final versionesAsync = ref.watch(versionesProvider(widget.diagramaId));

    return Column(
      children: [
        // Botón guardar
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarVersion,
              icon: _guardando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: const Text('Guardar versión'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const Divider(height: 1),

        // Lista de versiones
        Expanded(
          child: versionesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ),
            data: (versiones) {
              if (versiones.isEmpty) {
                return const Center(
                  child: Text(
                    'Sin versiones guardadas',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.surface500,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: versiones.length,
                itemBuilder: (_, i) {
                  final v = versiones[i];
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
                            Text(
                              'v${v.numeroVersion}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatFecha(v.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.surface500,
                              ),
                            ),
                          ],
                        ),
                        if (v.comentario != null &&
                            v.comentario!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            v.comentario!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.surface400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}