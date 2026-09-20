// lib/features/diagrama_editor/presentation/widgets/comentarios_panel.dart
//
// Panel de comentarios dentro del editor.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trazabilidad/domain/trazabilidad_entity.dart';
import '../../../trazabilidad/presentation/providers/trazabilidad_provider.dart';

class ComentariosPanel extends ConsumerStatefulWidget {
  final int diagramaId;

  const ComentariosPanel({super.key, required this.diagramaId});

  @override
  ConsumerState<ComentariosPanel> createState() => _ComentariosPanelState();
}

class _ComentariosPanelState extends ConsumerState<ComentariosPanel> {
  final _textoCtrl = TextEditingController();
  bool _soloNoResueltos = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  void _cargar() {
    ref.read(comentariosProvider(widget.diagramaId).notifier).cargar(
          soloNoResueltos: _soloNoResueltos,
        );
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);
    try {
      await ref
          .read(comentariosProvider(widget.diagramaId).notifier)
          .crear(texto: texto);
      _textoCtrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comentariosProvider(widget.diagramaId));
    final usuario = ref.watch(usuarioActualProvider);

    return Column(
      children: [
        // Filtro
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Sin resolver',
                style: TextStyle(fontSize: 12, color: AppColors.surface400),
              ),
              const SizedBox(width: 4),
              Switch(
                value: _soloNoResueltos,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) {
                  setState(() => _soloNoResueltos = v);
                  _cargar();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Lista
        Expanded(
          child: state.isLoading && state.comentarios.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.comentarios.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin comentarios',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.surface500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.comentarios.length,
                      itemBuilder: (_, i) {
                        final c = state.comentarios[i];
                        final esAutor = c.idUsuario == usuario?.id;
                        return _ComentarioCard(
                          comentario: c,
                          esAutor: esAutor,
                          onToggle: () => ref
                              .read(comentariosProvider(widget.diagramaId)
                                  .notifier)
                              .toggleResuelto(c),
                          onEliminar: esAutor
                              ? () => ref
                                  .read(comentariosProvider(widget.diagramaId)
                                      .notifier)
                                  .eliminar(c.id)
                              : null,
                        );
                      },
                    ),
        ),

        // Input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.surface800),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textoCtrl,
                  maxLines: 3,
                  minLines: 1,
                  enabled: !_enviando,
                  decoration: const InputDecoration(
                    hintText: 'Escribí un comentario…',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                color: AppColors.brand400,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComentarioCard extends StatelessWidget {
  final ComentarioDiagrama comentario;
  final bool esAutor;
  final VoidCallback onToggle;
  final VoidCallback? onEliminar;

  const _ComentarioCard({
    required this.comentario,
    required this.esAutor,
    required this.onToggle,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: comentario.resuelto
            ? AppColors.surface800.withValues(alpha: 0.3)
            : AppColors.surface800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: comentario.resuelto
              ? AppColors.surface700
              : AppColors.brand600.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comentario.texto,
            style: TextStyle(
              fontSize: 12,
              color: comentario.resuelto
                  ? AppColors.surface500
                  : AppColors.surface200,
              decoration: comentario.resuelto
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatFecha(comentario.createdAt),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.surface500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: comentario.resuelto
                      ? AppColors.surface400
                      : AppColors.success,
                ),
                child: Text(
                  comentario.resuelto ? 'Reabrir' : 'Resolver',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
              if (onEliminar != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  color: AppColors.surface500,
                  onPressed: onEliminar,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return 'hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inDays}d';
  }
}