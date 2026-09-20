// lib/features/proyectos/presentation/pages/proyectos_list_page.dart
//
// Pantalla principal: listado de proyectos.
//
// - Muestra proyectos en una lista.
// - Permite crear un proyecto (FAB + bottom sheet).
// - Filtro "incluir archivados" en el AppBar.
// - Íconos de notificaciones y perfil en el AppBar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notificaciones/presentation/providers/notificaciones_provider.dart';
import '../providers/proyectos_provider.dart';
import '../widgets/crear_proyecto_sheet.dart';
import '../widgets/proyecto_card.dart';

class ProyectosListPage extends ConsumerStatefulWidget {
  const ProyectosListPage({super.key});

  @override
  ConsumerState<ProyectosListPage> createState() => _ProyectosListPageState();
}

class _ProyectosListPageState extends ConsumerState<ProyectosListPage> {
  @override
  void initState() {
    super.initState();
    // Cargar al montar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
      ref.read(notificacionesProvider.notifier).refrescarContador();
    });
  }

  void _cargar() {
    final filtros = ref.read(proyectosFiltrosProvider);
    ref.read(proyectosProvider.notifier).cargar(
          incluirArchivados: filtros.incluirArchivados,
        );
  }

  Future<void> _abrirCrearProyecto() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const CrearProyectoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proyectosProvider);
    final filtros = ref.watch(proyectosFiltrosProvider);
    final usuario = ref.watch(usuarioActualProvider);
    final noLeidas = ref.watch(noLeidasCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        actions: [
          // Notificaciones con badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go(AppRoutes.notificaciones),
              ),
              if (noLeidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      noLeidas > 99 ? '99+' : '$noLeidas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Perfil
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go(AppRoutes.perfil),
            tooltip: usuario?.nombreCompleto ?? 'Perfil',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargar(),
        child: Column(
          children: [
            // Filtro
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: AppColors.surface500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${state.total} proyecto${state.total == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.surface400,
                    ),
                  ),
                  const Spacer(),
                  // Toggle archivados
                  Row(
                    children: [
                      const Text(
                        'Archivados',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.surface400,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: filtros.incluirArchivados,
                        onChanged: (v) {
                          ref
                              .read(proyectosFiltrosProvider.notifier)
                              .state = filtros.copyWith(incluirArchivados: v);
                          _cargar();
                        },
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: state.isLoading && state.proyectos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.proyectos.isEmpty
                      ? _EmptyState(onCrear: _abrirCrearProyecto)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.proyectos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final proyecto = state.proyectos[index];
                            return ProyectoCard(
                              proyecto: proyecto,
                              onTap: () => context.go(
                                AppRoutes.proyectoDetalle(proyecto.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCrearProyecto,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;

  const _EmptyState({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface800,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.folder_outlined,
                size: 40,
                color: AppColors.surface500,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Todavía no tenés proyectos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Creá tu primer proyecto para empezar a modelar\ndiagramas UML con tu equipo.',
              style: TextStyle(fontSize: 13, color: AppColors.surface400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text('Crear primer proyecto'),
            ),
          ],
        ),
      ),
    );
  }
}