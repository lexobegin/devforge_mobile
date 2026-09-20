// lib/features/generacion_codigo/presentation/widgets/generar_backend_sheet.dart
//
// Bottom sheet para disparar la generación de backend Spring Boot.
//
// Opciones:
// - Incluir colección Postman (on por defecto).
// - Nombre del proyecto (opcional).
// - Package base (opcional, colapsable).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/generacion_provider.dart';

class GenerarBackendSheet extends ConsumerStatefulWidget {
  final int diagramaId;

  const GenerarBackendSheet({super.key, required this.diagramaId});

  @override
  ConsumerState<GenerarBackendSheet> createState() =>
      _GenerarBackendSheetState();
}

class _GenerarBackendSheetState extends ConsumerState<GenerarBackendSheet> {
  bool _incluirPostman = true;
  bool _avanzadoAbierto = false;
  final _nombreCtrl = TextEditingController();
  final _packageCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _packageCtrl.dispose();
    super.dispose();
  }

  Future<void> _generar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trabajo = await ref
          .read(trabajoActivoProvider.notifier)
          .generar(
            widget.diagramaId,
            incluirPostman: _incluirPostman,
            nombreProyecto: _nombreCtrl.text.trim().isEmpty
                ? null
                : _nombreCtrl.text.trim(),
            packageBase: _packageCtrl.text.trim().isEmpty
                ? null
                : _packageCtrl.text.trim(),
          );

      if (!mounted) return;
      Navigator.pop(context);
      context.go(AppRoutes.generacionStatus(trabajo.id));
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
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
              'Generar backend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Se generará un proyecto Spring Boot completo a partir del '
              'diagrama actual.',
              style: TextStyle(fontSize: 13, color: AppColors.surface400),
            ),
            const SizedBox(height: 20),

            // Stack destino (info)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface800.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surface800),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STACK DESTINO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  _StackItem(texto: 'Java 17 + Spring Boot 3.2'),
                  _StackItem(
                    texto:
                        'Controller / Service / Repository / Entity / DTO',
                  ),
                  _StackItem(texto: 'JPA / Hibernate + PostgreSQL'),
                  _StackItem(texto: 'API REST + colección Postman'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Postman
            CheckboxListTile(
              value: _incluirPostman,
              onChanged: (v) => setState(() => _incluirPostman = v ?? true),
              title: const Text(
                'Incluir colección Postman',
                style: TextStyle(fontSize: 14),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            // Avanzado
            InkWell(
              onTap: () =>
                  setState(() => _avanzadoAbierto = !_avanzadoAbierto),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _avanzadoAbierto
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 18,
                      color: AppColors.brand400,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Opciones avanzadas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.brand400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_avanzadoAbierto) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _nombreCtrl,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Nombre del proyecto',
                  hintText: 'salud-universal-backend',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _packageCtrl,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Package base',
                  hintText: 'com.devforge.generated.salud',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
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
            ],

            const SizedBox(height: 24),

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
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: const Text('Generar backend'),
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

class _StackItem extends StatelessWidget {
  final String texto;

  const _StackItem({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Text(
            '▸',
            style: TextStyle(color: AppColors.brand400, fontSize: 11),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.surface300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}