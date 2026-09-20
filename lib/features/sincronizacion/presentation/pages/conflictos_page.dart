// lib/features/sincronizacion/presentation/pages/conflictos_page.dart
//
// Pantalla de conflictos de sincronización.
//
// Solo accesible para el PROPIETARIO del proyecto.
// Muestra la lista de conflictos pendientes y permite resolverlos con
// una de las 3 estrategias.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_providers.dart';
import '../../../../core/sync/tipos_sync.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/sincronizacion_entity.dart';

class ConflictosPage extends ConsumerStatefulWidget {
  final int diagramaId;

  const ConflictosPage({super.key, required this.diagramaId});

  @override
  ConsumerState<ConflictosPage> createState() => _ConflictosPageState();
}

class _ConflictosPageState extends ConsumerState<ConflictosPage> {
  List<ConflictoSync> _conflictos = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resolver = ref.read(conflictResolverProvider);
      final conflictos = await resolver.listarConflictos(widget.diagramaId);
      if (mounted) {
        setState(() {
          _conflictos = conflictos;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _resolver(ConflictoSync conflicto) async {
    final estrategia = await showDialog<EstrategiaConflicto>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver conflicto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operación: ${conflicto.tipoOperacion}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Qué versión conservar?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...EstrategiaConflicto.values.map((e) {
              return RadioListTile<EstrategiaConflicto>(
                value: e,
                groupValue: _estrategiaSeleccionada,
                onChanged: (v) =>
                    setState(() => _estrategiaSeleccionada = v),
                title: Text(e.label),
                dense: true,
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _estrategiaSeleccionada != null
                ? () => Navigator.pop(ctx, _estrategiaSeleccionada)
                : null,
            child: const Text('Resolver'),
          ),
        ],
      ),
    );

    if (estrategia == null) return;

    try {
      final resolver = ref.read(conflictResolverProvider);
      await resolver.resolver(
        conflictoId: conflicto.id,
        estrategia: estrategia,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conflicto resuelto')),
      );
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  EstrategiaConflicto? _estrategiaSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflictos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(mensaje: _error!, onRetry: _cargar)
              : _conflictos.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _conflictos.length,
                        itemBuilder: (_, i) => _ConflictoCard(
                          conflicto: _conflictos[i],
                          onResolver: () => _resolver(_conflictos[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _ConflictoCard extends StatelessWidget {
  final ConflictoSync conflicto;
  final VoidCallback onResolver;

  const _ConflictoCard({
    required this.conflicto,
    required this.onResolver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
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
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CONFLICTO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatFecha(conflicto.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.surface500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Operación: ${conflicto.tipoOperacion}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'El mismo elemento fue modificado en el servidor y offline. '
            'Necesitás elegir qué versión conservar.',
            style: TextStyle(fontSize: 12, color: AppColors.surface400),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onResolver,
              child: const Text('Resolver'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60,
              color: AppColors.success,
            ),
            SizedBox(height: 12),
            Text(
              'Sin conflictos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Todo sincronizado correctamente.',
              style: TextStyle(fontSize: 12, color: AppColors.surface500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorView({required this.mensaje, required this.onRetry});

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
              mensaje,
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