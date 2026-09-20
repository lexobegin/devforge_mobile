// lib/features/diagrama_editor/presentation/widgets/colaboradores_panel.dart
//
// Panel de colaboradores conectados.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../colaboracion/presentation/providers/colaboracion_provider.dart';

class ColaboradoresPanel extends ConsumerWidget {
  const ColaboradoresPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colaboracion = ref.watch(colaboracionProvider);
    final usuario = ref.watch(usuarioActualProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Conectados',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${colaboracion.totalConectados})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.surface500,
                ),
              ),
              const Spacer(),
              // Indicador de conexión
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colaboracion.conectado
                          ? AppColors.success
                          : AppColors.surface600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    colaboracion.conectado ? 'En vivo' : 'Offline',
                    style: TextStyle(
                      fontSize: 10,
                      color: colaboracion.conectado
                          ? AppColors.success
                          : AppColors.surface500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Yo
          if (usuario != null)
            _ColaboradorTile(
              nombre: usuario.nombreCompleto,
              color: AppColors.brand500,
              esYo: true,
            ),

          // Otros
          ...colaboracion.colaboradores.map(
            (c) => _ColaboradorTile(
              nombre: c.nombre,
              color: c.color,
            ),
          ),

          if (colaboracion.colaboradores.isEmpty && usuario != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No hay otros colaboradores conectados.',
                style: TextStyle(fontSize: 11, color: AppColors.surface500),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColaboradorTile extends StatelessWidget {
  final String nombre;
  final Color color;
  final bool esYo;

  const _ColaboradorTile({
    required this.nombre,
    required this.color,
    this.esYo = false,
  });

  @override
  Widget build(BuildContext context) {
    final iniciales = nombre.trim().isEmpty
        ? '?'
        : nombre.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(
              iniciales,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              esYo ? '$nombre (vos)' : nombre,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}