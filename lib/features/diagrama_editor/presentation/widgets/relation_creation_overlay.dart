// lib/features/diagrama_editor/presentation/widgets/relation_creation_overlay.dart
//
// Overlay que guía al usuario para crear una relación tocando dos clases.
//
// Flujo:
// 1. Usuario toca "Agregar relación" en la toolbar → modo.addRelation.
// 2. El overlay captura el primer tap en una clase (origen).
// 3. Captura el segundo tap en otra clase (destino).
// 4. Abre un diálogo para elegir tipo y multiplicidades.
// 5. Llama a diagramaProvider.crearRelacion(...).
//
// Este overlay se monta ENCIMA del canvas, con fondo transparente,
// absorbiendo los taps cuando el modo es addRelation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/relacion_uml_entity.dart';
import '../providers/diagrama_provider.dart';

class RelationCreationOverlay extends ConsumerStatefulWidget {
  const RelationCreationOverlay({super.key});

  @override
  ConsumerState<RelationCreationOverlay> createState() =>
      _RelationCreationOverlayState();
}

class _RelationCreationOverlayState
    extends ConsumerState<RelationCreationOverlay> {
  int? _origenId;

  @override
  Widget build(BuildContext context) {
    final modo = ref.watch(diagramaProvider).modo;
    if (modo != ModoEditor.addRelation) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _onTapUp,
        child: IgnorePointer(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _origenId == null
                      ? AppColors.brand600
                      : AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _origenId == null
                      ? 'Tocá la clase ORIGEN'
                      : 'Ahora tocá la clase DESTINO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTapUp(TapUpDetails details) async {
    // Encontrar la clase bajo el tap
    final pos = details.localPosition;
    final clases = ref.read(clasesProvider);

    int? claseTocada;
    for (final clase in clases) {
      // Área aproximada del nodo: 200x~100
      final rect = Rect.fromLTWH(clase.posX, clase.posY, 200, 100);
      if (rect.contains(pos)) {
        claseTocada = clase.id;
        break;
      }
    }

    if (claseTocada == null) return;

    // Primer tap: guardar origen
    if (_origenId == null) {
      setState(() => _origenId = claseTocada);
      return;
    }

    // Segundo tap: crear relación
    if (_origenId == claseTocada) {
      // Misma clase: resetear
      setState(() => _origenId = null);
      return;
    }

    final origen = _origenId!;
    setState(() => _origenId = null);

    await _mostrarDialogoCreacion(origen, claseTocada);
  }

  Future<void> _mostrarDialogoCreacion(int origenId, int destinoId) async {
    final tipo = await showDialog<TipoRelacion>(
      context: context,
      builder: (ctx) => _TipoRelacionDialog(),
    );

    if (tipo == null) return;

    try {
      await ref.read(diagramaProvider.notifier).crearRelacion(
            idClaseOrigen: origenId,
            idClaseDestino: destinoId,
            tipo: tipo,
          );

      ref.read(diagramaProvider.notifier).setModo(ModoEditor.select);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relación creada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// ======================================================================
// Diálogo de tipo de relación
// ======================================================================
class _TipoRelacionDialog extends StatefulWidget {
  @override
  State<_TipoRelacionDialog> createState() => _TipoRelacionDialogState();
}

class _TipoRelacionDialogState extends State<_TipoRelacionDialog> {
  TipoRelacion _seleccionado = TipoRelacion.asociacion;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tipo de relación'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: TipoRelacion.values.map((t) {
          return RadioListTile<TipoRelacion>(
            value: t,
            groupValue: _seleccionado,
            onChanged: (v) => setState(() => _seleccionado = v!),
            title: Text(t.label),
            dense: true,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _seleccionado),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}