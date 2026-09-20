// lib/features/notificaciones/presentation/pages/notificaciones_page.dart
//
// Pantalla de notificaciones completa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/notificacion_entity.dart';
import '../providers/notificaciones_provider.dart';

class NotificacionesPage extends ConsumerStatefulWidget {
  const NotificacionesPage({super.key});

  @override
  ConsumerState<NotificacionesPage> createState() =>
      _NotificacionesPageState();
}

class _NotificacionesPageState extends ConsumerState<NotificacionesPage> {
  bool _soloNoLeidas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificacionesProvider.notifier).cargar();
    });
  }

  Future<void> _marcarTodasLeidas() async {
    await ref.read(notificacionesProvider.notifier).marcarTodasLeidas();
  }

  Future<void> _limpiarLeidas() async {
    final eliminadas =
        await ref.read(notificacionesProvider.notifier).limpiarLeidas();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eliminadas > 0
              ? 'Se eliminaron $eliminadas notificaciones'
              : 'No había notificaciones leídas',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificacionesProvider);

    final lista = _soloNoLeidas
        ? state.notificaciones.where((n) => !n.leida).toList()
        : state.notificaciones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (state.noLeidas > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas leídas',
              onPressed: _marcarTodasLeidas,
            ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Limpiar leídas',
            onPressed: _limpiarLeidas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  state.noLeidas > 0
                      ? '${state.noLeidas} sin leer'
                      : 'Todas leídas',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.surface400,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Solo no leídas',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.surface400,
                  ),
                ),
                Switch(
                  value: _soloNoLeidas,
                  onChanged: (v) => setState(() => _soloNoLeidas = v),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: state.isLoading && state.notificaciones.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : lista.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay notificaciones',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.surface500,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(notificacionesProvider.notifier).cargar(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: lista.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _NotificacionCard(
                            notificacion: lista[i],
                            onToggle: () {
                              final n = lista[i];
                              if (n.leida) {
                                ref
                                    .read(notificacionesProvider.notifier)
                                    .marcarNoLeida(n.id);
                              } else {
                                ref
                                    .read(notificacionesProvider.notifier)
                                    .marcarLeida(n.id);
                              }
                            },
                            onEliminar: () => ref
                                .read(notificacionesProvider.notifier)
                                .eliminar(lista[i].id),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _NotificacionCard extends StatelessWidget {
  final Notificacion notificacion;
  final VoidCallback onToggle;
  final VoidCallback onEliminar;

  const _NotificacionCard({
    required this.notificacion,
    required this.onToggle,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final leida = notificacion.leida;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: leida
            ? AppColors.surface900
            : AppColors.brand600.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: leida
              ? AppColors.surface800
              : AppColors.brand600.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: leida ? AppColors.surface600 : AppColors.brand500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificacion.mensaje,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: leida ? FontWeight.w400 : FontWeight.w500,
                    color: leida
                        ? AppColors.surface300
                        : AppColors.surface100,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface800,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        notificacion.tipo.label,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatFecha(notificacion.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.surface500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Acciones
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  leida ? Icons.mark_email_unread_outlined : Icons.done,
                  size: 18,
                ),
                color: AppColors.surface400,
                tooltip: leida ? 'Marcar no leída' : 'Marcar leída',
                onPressed: onToggle,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.surface400,
                tooltip: 'Eliminar',
                onPressed: onEliminar,
                visualDensity: VisualDensity.compact,
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
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}