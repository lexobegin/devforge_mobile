// lib/features/proyectos/presentation/widgets/crear_proyecto_sheet.dart
//
// Bottom sheet para crear un proyecto.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/proyectos_provider.dart';

class CrearProyectoSheet extends ConsumerStatefulWidget {
  const CrearProyectoSheet({super.key});

  @override
  ConsumerState<CrearProyectoSheet> createState() =>
      _CrearProyectoSheetState();
}

class _CrearProyectoSheetState extends ConsumerState<CrearProyectoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(proyectosProvider.notifier).crear(
            nombre: _nombreCtrl.text.trim(),
            descripcion:
                _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto creado')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Nuevo proyecto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Creá un proyecto para empezar a modelar.',
              style: TextStyle(fontSize: 13, color: AppColors.surface400),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _nombreCtrl,
              enabled: !_isLoading,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 150,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Sistema de Salud Universal',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresá un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _descCtrl,
              enabled: !_isLoading,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Breve descripción del proyecto',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _crear,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Crear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}