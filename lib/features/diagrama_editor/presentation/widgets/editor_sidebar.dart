// lib/features/diagrama_editor/presentation/widgets/editor_sidebar.dart
//
// Sidebar derecho del editor con tabs:
// - Propiedades (contextual: clase o relación)
// - Versiones
// - Comentarios
// - Colaboradores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../proyectos/presentation/providers/proyecto_detalle_provider.dart';
import '../providers/diagrama_provider.dart';
import 'colaboradores_panel.dart';
import 'comentarios_panel.dart';
import 'propiedades_editor.dart';
import 'versiones_panel.dart';

enum EditorTab { propiedades, versiones, comentarios, colaboradores }

class EditorSidebar extends ConsumerStatefulWidget {
  final int diagramaId;
  final EditorTab initialTab;

  const EditorSidebar({
    super.key,
    required this.diagramaId,
    this.initialTab = EditorTab.propiedades,
  });

  @override
  ConsumerState<EditorSidebar> createState() => _EditorSidebarState();
}

class _EditorSidebarState extends ConsumerState<EditorSidebar> {
  // EditorTab _tab = EditorTab.propiedades;

  late EditorTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant EditorSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cuando el padre cambia initialTab, actualizar el tab activo
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() => _tab = widget.initialTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagramaProvider);
    final usuario = ref.watch(usuarioActualProvider);
    final proyectoDetalle = ref.watch(proyectoDetalleProvider);
    final miRol = (usuario != null && proyectoDetalle.proyecto != null)
        ? proyectoDetalle.proyecto!.rolDeUsuario(usuario.id)
        : null;
    final soloLectura = miRol?.value == 'LECTOR';

    return Container(
      //width: 300,
      decoration: const BoxDecoration(
        color: AppColors.surface900,
        border: Border(left: BorderSide(color: AppColors.surface800)),
      ),
      child: Column(
        children: [
          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surface800),
              ),
            ),
            child: Row(
              children: [
                _TabBtn(
                  icon: Icons.tune,
                  tooltip: 'Propiedades',
                  active: _tab == EditorTab.propiedades,
                  onTap: () => setState(() => _tab = EditorTab.propiedades),
                ),
                _TabBtn(
                  icon: Icons.history,
                  tooltip: 'Versiones',
                  active: _tab == EditorTab.versiones,
                  onTap: () => setState(() => _tab = EditorTab.versiones),
                ),
                _TabBtn(
                  icon: Icons.comment_outlined,
                  tooltip: 'Comentarios',
                  active: _tab == EditorTab.comentarios,
                  onTap: () => setState(() => _tab = EditorTab.comentarios),
                ),
                _TabBtn(
                  icon: Icons.people_outline,
                  tooltip: 'Colaboradores',
                  active: _tab == EditorTab.colaboradores,
                  onTap: () => setState(() => _tab = EditorTab.colaboradores),
                ),
              ],
            ),
          ),

          // Contenido
          Expanded(
            child: _buildContenido(state, soloLectura),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(DiagramaState state, bool soloLectura) {
    switch (_tab) {
      case EditorTab.propiedades:
        final clase = state.claseSeleccionada;
        if (clase != null) {
          return PropiedadesEditor(
            key: ValueKey('clase-${clase.id}'),
            clase: clase,
            soloLectura: soloLectura,
          );
        }
        return const _EmptyPropiedades();

      case EditorTab.versiones:
        return VersionesPanel(diagramaId: widget.diagramaId);

      case EditorTab.comentarios:
        return ComentariosPanel(diagramaId: widget.diagramaId);

      case EditorTab.colaboradores:
        return const ColaboradoresPanel();
    }
  }
}

class _TabBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? AppColors.brand500 : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? AppColors.brand400 : AppColors.surface400,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPropiedades extends StatelessWidget {
  const _EmptyPropiedades();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_outlined,
              size: 40,
              color: AppColors.surface600,
            ),
            SizedBox(height: 12),
            Text(
              'Nada seleccionado',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.surface300,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Seleccioná una clase para ver sus propiedades.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.surface500),
            ),
          ],
        ),
      ),
    );
  }
}