// lib/features/proyectos/presentation/pages/proyecto_detail_page.dart
//
// Detalle de proyecto: metadata, miembros y diagramas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../diagrama_editor/presentation/providers/diagrama_provider.dart';
import '../../domain/proyecto_entity.dart';
import '../providers/proyecto_detalle_provider.dart';
import '../providers/proyectos_provider.dart';

import '../../../diagrama_editor/domain/diagrama_entity.dart';
import '../../../diagrama_editor/data/diagrama_remote_datasource.dart';

class ProyectoDetailPage extends ConsumerStatefulWidget {
  final int proyectoId;

  const ProyectoDetailPage({super.key, required this.proyectoId});

  @override
  ConsumerState<ProyectoDetailPage> createState() => _ProyectoDetailPageState();
}

class _ProyectoDetailPageState extends ConsumerState<ProyectoDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Limpiar el estado anterior y cargar el nuevo proyecto
      ref.read(proyectoDetalleProvider.notifier).limpiar();
      ref.read(proyectoDetalleProvider.notifier).cargar(widget.proyectoId);
      _cargarDiagramas();
    });
  }

  @override
  void dispose() {
    //ref.read(proyectoDetalleProvider.notifier).limpiar();
    super.dispose();
  }

  List<Diagrama> _diagramas = [];
  bool _cargandoDiagramas = true;

  Future<void> _cargarDiagramas() async {
    setState(() => _cargandoDiagramas = true);
    try {
      final remote = ref.read(diagramaRemoteDataSourceProvider);
      final items = await remote.listarPorProyecto(widget.proyectoId);
      if (mounted) {
        setState(() {
          _diagramas = items;
          _cargandoDiagramas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _diagramas = [];
          _cargandoDiagramas = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminar(Proyecto proyecto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text(
          '¿Eliminar el proyecto "${proyecto.nombre}"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref.read(proyectosProvider.notifier).eliminar(proyecto.id);
      if (mounted) {
        context.go(AppRoutes.proyectos);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(proyectoDetalleProvider);
    final proyecto = state.proyecto?.proyecto;
    final miembros = state.proyecto?.miembros ?? [];
    final usuario = ref.watch(usuarioActualProvider);

    // Rol del usuario actual
    RolEnProyecto? miRol;
    if (usuario != null && state.proyecto != null) {
      miRol = state.proyecto!.rolDeUsuario(usuario.id);
    }
    final esPropietario = miRol == RolEnProyecto.propietario;
    final puedeEditar = miRol?.alMenos(RolEnProyecto.editor) ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.proyectos),
        ),
        title: Text(proyecto?.nombre ?? 'Proyecto'),
        actions: [
          if (puedeEditar)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'archivar':
                    if (proyecto != null) {
                      ref
                          .read(proyectosProvider.notifier)
                          .archivar(proyecto.id);
                    }
                    break;
                  case 'reactivar':
                    if (proyecto != null) {
                      ref
                          .read(proyectosProvider.notifier)
                          .reactivar(proyecto.id);
                    }
                    break;
                  case 'eliminar':
                    if (proyecto != null) _confirmarEliminar(proyecto);
                    break;
                }
              },
              itemBuilder: (_) => [
                if (esPropietario && proyecto?.estaActivo == true)
                  const PopupMenuItem(
                    value: 'archivar',
                    child: Text('Archivar'),
                  ),
                if (esPropietario && proyecto?.estaArchivado == true)
                  const PopupMenuItem(
                    value: 'reactivar',
                    child: Text('Reactivar'),
                  ),
                if (esPropietario)
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Text(
                      'Eliminar',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorView(
                  message: state.error!.userMessage,
                  onRetry: () => ref
                      .read(proyectoDetalleProvider.notifier)
                      .cargar(widget.proyectoId),
                )
              : proyecto == null
                  ? const Center(child: Text('Proyecto no encontrado'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Metadata
                          _InfoCard(
                            proyecto: proyecto,
                            miembros: miembros.length,
                          ),
                          const SizedBox(height: 24),

                          // Miembros
                          _SectionTitle(
                            title: 'Miembros (${miembros.length})',
                            action: puedeEditar
                                ? TextButton.icon(
                                    onPressed: () => _abrirMiembrosSheet(
                                      context,
                                      miembros,
                                      esPropietario,
                                    ),
                                    icon: const Icon(Icons.settings, size: 16),
                                    label: const Text('Gestionar'),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          _MiembrosList(miembros: miembros),
                          const SizedBox(height: 24),

                          // Diagramas
                          _SectionTitle(
                            title: 'Diagramas UML',
                            action: puedeEditar
                                ? TextButton.icon(
                                    onPressed: () => _crearDiagrama(),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Nuevo'),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          _cargandoDiagramas
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              : _diagramas.isEmpty
                                  ? const _DiagramasVacio()
                                  : _DiagramasList(
                                      diagramas: _diagramas,
                                      onAbrir: (id) => context
                                          .go(AppRoutes.diagramaEditor(id)),
                                    ),
                        ],
                      ),
                    ),
    );
  }

  void _abrirMiembrosSheet(
    BuildContext context,
    List<MiembroProyecto> miembros,
    bool esPropietario,
  ) {
    // Placeholder: en la siguiente iteración lo implementamos completo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestión de miembros (próximamente)')),
    );
  }

  void _crearDiagrama() {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo diagrama'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre del diagrama',
            hintText: 'Diagrama de clases — módulo de salud',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = controller.text.trim();
              if (nombre.isEmpty) return;

              try {
                final diagrama = await ref
                    .read(diagramaRepositoryProvider)
                    .crear(widget.proyectoId, nombre: nombre);

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                context.go(AppRoutes.diagramaEditor(diagrama.id));
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Widgets auxiliares
// ======================================================================
class _InfoCard extends StatelessWidget {
  final Proyecto proyecto;
  final int miembros;

  const _InfoCard({required this.proyecto, required this.miembros});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: proyecto.estaActivo
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.surface700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    proyecto.estado.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: proyecto.estaActivo
                          ? AppColors.success
                          : AppColors.surface300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (proyecto.descripcion != null &&
                proyecto.descripcion!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                proyecto.descripcion!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.surface300,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('Miembros', '$miembros'),
                const SizedBox(width: 24),
                _stat(
                  'Creado',
                  '${proyecto.createdAt.day}/${proyecto.createdAt.month}/${proyecto.createdAt.year}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.surface500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _MiembrosList extends StatelessWidget {
  final List<MiembroProyecto> miembros;

  const _MiembrosList({required this.miembros});

  @override
  Widget build(BuildContext context) {
    if (miembros.isEmpty) {
      return const Text(
        'Sin miembros cargados.',
        style: TextStyle(fontSize: 13, color: AppColors.surface500),
      );
    }

    return Column(
      children: miembros.map((m) {
        final nombre = m.nombreUsuario ?? 'Usuario #${m.idUsuario}';
        final iniciales = nombre.trim().isEmpty
            ? '?'
            : nombre
                .trim()
                .split(' ')
                .take(2)
                .map((w) => w[0])
                .join()
                .toUpperCase();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.colorPorId(m.idUsuario),
                child: Text(
                  iniciales,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (m.emailUsuario != null)
                      Text(
                        m.emailUsuario!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.surface500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: m.esPropietario
                      ? AppColors.brand600.withValues(alpha: 0.15)
                      : AppColors.surface800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m.rol.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: m.esPropietario
                        ? AppColors.brand300
                        : AppColors.surface400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DiagramasVacio extends StatelessWidget {
  const _DiagramasVacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface800),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_tree_outlined,
              size: 40, color: AppColors.surface500),
          SizedBox(height: 8),
          Text(
            'No hay diagramas todavía',
            style: TextStyle(fontSize: 13, color: AppColors.surface400),
          ),
          SizedBox(height: 4),
          Text(
            'Creá el primero con el botón "Nuevo"',
            style: TextStyle(fontSize: 11, color: AppColors.surface500),
          ),
        ],
      ),
    );
  }
}

class _DiagramasList extends StatelessWidget {
  final List<Diagrama> diagramas;
  final void Function(int id) onAbrir;

  const _DiagramasList({
    required this.diagramas,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: diagramas.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface900,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surface800),
          ),
          child: Material (
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.brand600.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: AppColors.brand400,
              ),
            ),
            title: Text(
              d.nombre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'UML ${d.versionUml} · v${d.numeroVersion}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.surface500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.surface500,
            ),
            onTap: () => onAbrir(d.id),
          ),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.surface300),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
