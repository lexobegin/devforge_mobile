// lib/features/diagrama_editor/presentation/widgets/canvas_toolbar.dart
//
// Toolbar flotante del canvas.
// Botones: seleccionar, agregar clase, agregar relación, zoom in/out,
// ajustar a pantalla.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/diagrama_provider.dart';

class CanvasToolbar extends StatelessWidget {
  final ModoEditor modo;
  final VoidCallback onSelect;
  final VoidCallback onAddClass;
  final VoidCallback onAddRelation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitView;

  const CanvasToolbar({
    super.key,
    required this.modo,
    required this.onSelect,
    required this.onAddClass,
    required this.onAddRelation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface800),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarButton(
            icon: Icons.pan_tool_outlined,
            tooltip: 'Seleccionar',
            active: modo == ModoEditor.select,
            onTap: onSelect,
          ),
          const SizedBox(height: 2),
          _ToolbarButton(
            icon: Icons.add_box_outlined,
            tooltip: 'Agregar clase',
            active: modo == ModoEditor.addClass,
            onTap: onAddClass,
          ),
          const SizedBox(height: 2),
          _ToolbarButton(
            icon: Icons.timeline,
            tooltip: 'Agregar relación',
            active: modo == ModoEditor.addRelation,
            onTap: onAddRelation,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Divider(height: 1, color: AppColors.surface700),
          ),
          _ToolbarButton(
            icon: Icons.zoom_in,
            tooltip: 'Acercar',
            onTap: onZoomIn,
          ),
          const SizedBox(height: 2),
          _ToolbarButton(
            icon: Icons.zoom_out,
            tooltip: 'Alejar',
            onTap: onZoomOut,
          ),
          const SizedBox(height: 2),
          _ToolbarButton(
            icon: Icons.fit_screen_outlined,
            tooltip: 'Ajustar a pantalla',
            onTap: onFitView,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? AppColors.brand600 : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.white : AppColors.surface300,
            ),
          ),
        ),
      ),
    );
  }
}