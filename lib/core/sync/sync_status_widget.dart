// lib/core/sync/sync_status_widget.dart
//
// Widget que muestra el estado de sincronización en la UI.
//
// Estados posibles:
// - Todo OK (online + sin pendientes): no muestra nada.
// - Offline: badge amarillo "Offline · N pendientes".
// - Sincronizando: badge azul con spinner.
// - Online con pendientes: badge azul "N pendientes", tap para sincronizar.
// - Con conflictos: badge naranja "Conflictos", tap para verlos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sincronizacion/presentation/pages/conflictos_page.dart';
import '../providers/core_providers.dart';
import '../theme/app_colors.dart';
import 'sync_providers.dart';

class SyncStatusWidget extends ConsumerWidget {
  /// ID del diagrama actual (opcional). Si está presente y hay
  /// conflictos, permite navegar a la pantalla de resolución.
  final int? diagramaId;

  const SyncStatusWidget({super.key, this.diagramaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncState = ref.watch(syncProvider);
    final pendientes = syncState.pendientes;
    final sincronizando = syncState.sincronizando;
    final hayConflictos = syncState.hayConflictos;

    // ---------- Conflicto pendiente ----------
    if (hayConflictos && diagramaId != null) {
      return _Badge(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        texto: 'Conflictos',
        onTap: () => _verConflictos(context, ref),
      );
    }

    // ---------- Offline ----------
    if (!isOnline) {
      return _Badge(
        icon: Icons.cloud_off,
        color: AppColors.warning,
        texto: pendientes > 0
            ? 'Offline · $pendientes pendiente${pendientes == 1 ? '' : 's'}'
            : 'Offline',
        onTap: () => _mostrarDetalle(context, pendientes),
      );
    }

    // ---------- Sincronizando ----------
    if (sincronizando) {
      return const _Badge(
        icon: Icons.sync,
        color: AppColors.brand400,
        texto: 'Sincronizando…',
        animado: true,
      );
    }

    // ---------- Online con pendientes ----------
    if (pendientes > 0) {
      return _Badge(
        icon: Icons.cloud_upload_outlined,
        color: AppColors.brand400,
        texto: '$pendientes pendiente${pendientes == 1 ? '' : 's'}',
        onTap: () => _sincronizar(context, ref),
      );
    }

    // ---------- Todo bien ----------
    return const SizedBox.shrink();
  }

  // ==================================================================
  // Acciones
  // ==================================================================
  Future<void> _sincronizar(BuildContext context, WidgetRef ref) async {
    try {
      final result =
          await ref.read(syncProvider.notifier).sincronizarTodo();

      if (!context.mounted) return;

      if (result.total == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay cambios pendientes')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.todoOk
                ? '${result.sincronizados} cambio${result.sincronizados == 1 ? '' : 's'} sincronizado${result.sincronizados == 1 ? '' : 's'}'
                : 'Sincronizados: ${result.sincronizados} · '
                    'Conflictos: ${result.conflictos} · '
                    'Fallidos: ${result.fallidos}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al sincronizar: $e')),
      );
    }
  }

  void _verConflictos(BuildContext context, WidgetRef ref) {
    if (diagramaId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConflictosPage(diagramaId: diagramaId!),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, int pendientes) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sin conexión'),
        content: Text(
          pendientes > 0
              ? 'Tenés $pendientes cambio${pendientes == 1 ? '' : 's'} '
                  'pendiente${pendientes == 1 ? '' : 's'} de sincronizar. '
                  'Se enviarán automáticamente cuando recuperes conexión.'
              : 'Estás trabajando sin conexión. Los cambios se guardarán '
                  'localmente y se sincronizarán cuando vuelvas a estar online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Badge
// ======================================================================
class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String texto;
  final VoidCallback? onTap;
  final bool animado;

  const _Badge({
    required this.icon,
    required this.color,
    required this.texto,
    this.onTap,
    this.animado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (animado)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                else
                  Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}