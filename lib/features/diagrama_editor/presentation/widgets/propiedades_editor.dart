// lib/features/diagrama_editor/presentation/widgets/propiedades_editor.dart
//
// Panel de propiedades completo.
// Permite editar la clase seleccionada y sus atributos/operaciones.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/clase_uml_entity.dart';
import '../providers/diagrama_provider.dart';

class PropiedadesEditor extends ConsumerStatefulWidget {
  final ClaseUml clase;
  final bool soloLectura;

  const PropiedadesEditor({
    super.key,
    required this.clase,
    this.soloLectura = false,
  });

  @override
  ConsumerState<PropiedadesEditor> createState() =>
      _PropiedadesEditorState();
}

class _PropiedadesEditorState extends ConsumerState<PropiedadesEditor> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _estereotipoCtrl;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.clase.nombre);
    _estereotipoCtrl =
        TextEditingController(text: widget.clase.estereotipo ?? '');
  }

  @override
  void didUpdateWidget(covariant PropiedadesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clase.id != widget.clase.id) {
      _nombreCtrl.text = widget.clase.nombre;
      _estereotipoCtrl.text = widget.clase.estereotipo ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _estereotipoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarNombre() async {
    final nuevo = _nombreCtrl.text.trim();
    if (nuevo.isEmpty || nuevo == widget.clase.nombre) return;

    await ref
        .read(diagramaProvider.notifier)
        .actualizarClase(widget.clase.id, nombre: nuevo);
  }

  Future<void> _guardarEstereotipo() async {
    final nuevo = _estereotipoCtrl.text.trim();
    if (nuevo == (widget.clase.estereotipo ?? '')) return;

    await ref.read(diagramaProvider.notifier).actualizarClase(
          widget.clase.id,
          estereotipo: nuevo.isEmpty ? null : nuevo,
        );
  }

  @override
  Widget build(BuildContext context) {
    final clase = widget.clase;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Nombre
        _Field(
          label: 'Nombre',
          controller: _nombreCtrl,
          enabled: !widget.soloLectura,
          onBlur: _guardarNombre,
        ),
        const SizedBox(height: 12),

        // Estereotipo
        _Field(
          label: 'Estereotipo',
          controller: _estereotipoCtrl,
          enabled: !widget.soloLectura,
          hint: 'entity, control, boundary…',
          onBlur: _guardarEstereotipo,
        ),
        const SizedBox(height: 12),

        // Abstracta
        if (!widget.soloLectura)
          CheckboxListTile(
            value: clase.esAbstracta,
            onChanged: (v) {
              if (v == null) return;
              ref.read(diagramaProvider.notifier).actualizarClase(
                    clase.id,
                    esAbstracta: v,
                  );
            },
            title: const Text(
              'Clase abstracta',
              style: TextStyle(fontSize: 13),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // -------- Atributos --------
        _SeccionHeader(
          titulo: 'Atributos (${clase.atributos.length})',
          onAgregar: widget.soloLectura
              ? null
              : () => _agregarAtributo(context),
        ),
        const SizedBox(height: 8),

        if (clase.atributos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin atributos.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.surface500,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...clase.atributos.map((a) => _AtributoRow(
                atributo: a,
                soloLectura: widget.soloLectura,
                onEliminar: () => ref
                    .read(diagramaProvider.notifier)
                    .eliminarAtributo(clase.id, a.id),
              )),

        const SizedBox(height: 20),

        // -------- Operaciones --------
        _SeccionHeader(
          titulo: 'Operaciones (${clase.operaciones.length})',
          onAgregar: widget.soloLectura
              ? null
              : () => _agregarOperacion(context),
        ),
        const SizedBox(height: 8),

        if (clase.operaciones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin operaciones.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.surface500,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...clase.operaciones.map((op) => _OperacionRow(
                operacion: op,
                soloLectura: widget.soloLectura,
              )),
      ],
    );
  }

  Future<void> _agregarAtributo(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final tipoCtrl = TextEditingController(text: 'String');

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo atributo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tipoCtrl,
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (resultado == true && nombreCtrl.text.trim().isNotEmpty) {
      await ref.read(diagramaProvider.notifier).agregarAtributo(
            widget.clase.id,
            nombre: nombreCtrl.text.trim(),
            tipoDato: tipoCtrl.text.trim().isEmpty
                ? 'String'
                : tipoCtrl.text.trim(),
          );
    }
  }

  Future<void> _agregarOperacion(BuildContext context) async {
    final nombreCtrl = TextEditingController();
    final retornoCtrl = TextEditingController(text: 'void');

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva operación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: retornoCtrl,
              decoration: const InputDecoration(labelText: 'Retorno'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (resultado == true && nombreCtrl.text.trim().isNotEmpty) {
      // Nota: por ahora no implementamos operaciones en el móvil (falta
      // endpoint de creación específico). Mostramos un aviso.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operaciones: próximamente'),
        ),
      );
    }
  }
}

// ======================================================================
// Widgets auxiliares
// ======================================================================
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? hint;
  final VoidCallback onBlur;

  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.hint,
    required this.onBlur,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) onBlur();
      },
      child: TextField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String titulo;
  final VoidCallback? onAgregar;

  const _SeccionHeader({required this.titulo, this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.surface300,
          ),
        ),
        const Spacer(),
        if (onAgregar != null)
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            color: AppColors.surface400,
            onPressed: onAgregar,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

class _AtributoRow extends StatelessWidget {
  final AtributoUml atributo;
  final bool soloLectura;
  final VoidCallback onEliminar;

  const _AtributoRow({
    required this.atributo,
    required this.soloLectura,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(
            atributo.visibilidad.value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.surface500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.surface200),
                children: [
                  TextSpan(text: atributo.nombre),
                  if (atributo.tipoDato.isNotEmpty)
                    TextSpan(
                      text: ': ${atributo.tipoDato}',
                      style: const TextStyle(color: AppColors.surface500),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!soloLectura)
            IconButton(
              icon: const Icon(Icons.close, size: 14),
              color: AppColors.surface500,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              onPressed: onEliminar,
            ),
        ],
      ),
    );
  }
}

class _OperacionRow extends StatelessWidget {
  final OperacionUml operacion;
  final bool soloLectura;

  const _OperacionRow({required this.operacion, required this.soloLectura});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: AppColors.surface200),
          children: [
            TextSpan(text: '${operacion.visibilidad.value} '),
            TextSpan(text: '${operacion.nombre}()'),
            if (operacion.tipoRetorno.isNotEmpty)
              TextSpan(
                text: ': ${operacion.tipoRetorno}',
                style: const TextStyle(color: AppColors.surface500),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}