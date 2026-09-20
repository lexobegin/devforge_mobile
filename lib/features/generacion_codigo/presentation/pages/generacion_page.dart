// lib/features/generacion_codigo/presentation/pages/generacion_page.dart
//
// Pantalla de estado de una generación.
//
// - Hace polling del estado del trabajo activo (via provider).
// - Al terminar exitosamente, muestra el resumen de entidades y el botón
//   para descargar el ZIP.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/generacion_entity.dart';
import '../providers/generacion_provider.dart';

class GeneracionPage extends ConsumerStatefulWidget {
  final int trabajoId;

  const GeneracionPage({super.key, required this.trabajoId});

  @override
  ConsumerState<GeneracionPage> createState() => _GeneracionPageState();
}

class _GeneracionPageState extends ConsumerState<GeneracionPage> {
  bool _descargando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(trabajoActivoProvider.notifier)
          .seguirTrabajo(widget.trabajoId);
    });
  }

  @override
  void dispose() {
    ref.read(trabajoActivoProvider.notifier).detenerPolling();
    super.dispose();
  }

  Future<void> _descargar() async {
  setState(() => _descargando = true);

  try {
    // Pedir la URL de descarga
    final descarga = await ref
        .read(generacionRepositoryProvider)
        .obtenerUrlDescarga(widget.trabajoId);

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/devforge-backend-${widget.trabajoId}.zip';

    await ref.read(generacionRepositoryProvider).descargarZip(
          downloadUrl: descarga.downloadUrl,
          savePath: savePath,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Descargado en: $savePath'),
        duration: const Duration(seconds: 4),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al descargar: $e')),
    );
  } finally {
    if (mounted) setState(() => _descargando = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trabajoActivoProvider);
    final estadoActual = state.estadoActual;
    final detalle = state.detalle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.proyectos),
        ),
      ),
      body: SafeArea(
        child: estadoActual == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metadata
                    Text(
                      'Trabajo #${widget.trabajoId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Spring Boot + JPA + PostgreSQL',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.surface400,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card de estado
                    _EstadoCard(estado: estadoActual, estadoGeneracion: state.estado),

                    const SizedBox(height: 24),

                    // Resultado exitoso
                    if (estadoActual == EstadoTrabajoGeneracion.exitoso &&
                        detalle != null) ...[
                      _ResultadoExitoso(
                        detalle: detalle,
                        onDescargar: _descargar,
                        descargando: _descargando,
                      ),
                    ],

                    // Fallo
                    if (estadoActual == EstadoTrabajoGeneracion.fallido) ...[
                      const _ResultadoFallido(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// ======================================================================
// Card de estado
// ======================================================================
class _EstadoCard extends StatelessWidget {
  final EstadoTrabajoGeneracion estado;
  final EstadoGeneracion? estadoGeneracion;

  const _EstadoCard({required this.estado, this.estadoGeneracion});

  @override
  Widget build(BuildContext context) {
    final config = _configPorEstado(estado);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.border),
      ),
      child: Row(
        children: [
          config.esEnCurso
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : Icon(
                  config.icon,
                  size: 28,
                  color: config.color,
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: config.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.descripcion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.surface400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _EstadoConfig _configPorEstado(EstadoTrabajoGeneracion estado) {
    switch (estado) {
      case EstadoTrabajoGeneracion.pendiente:
        return const _EstadoConfig(
          titulo: 'En cola',
          descripcion: 'El trabajo espera ser procesado.',
          icon: Icons.schedule,
          color: AppColors.surface300,
          bg: Color(0x1AFFFFFF),
          border: AppColors.surface700,
          esEnCurso: true,
        );
      case EstadoTrabajoGeneracion.enProceso:
        return const _EstadoConfig(
          titulo: 'Generando…',
          descripcion: 'Se está generando el backend. Podés tardar unos segundos.',
          icon: Icons.settings,
          color: AppColors.brand300,
          bg: Color(0x1A6366F1),
          border: AppColors.brand600,
          esEnCurso: true,
        );
      case EstadoTrabajoGeneracion.exitoso:
        return const _EstadoConfig(
          titulo: 'Generación completada',
          descripcion: 'El backend está listo para descargar.',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
          bg: Color(0x1A10B981),
          border: AppColors.success,
          esEnCurso: false,
        );
      case EstadoTrabajoGeneracion.fallido:
        return const _EstadoConfig(
          titulo: 'Error en la generación',
          descripcion: 'Algo falló durante el proceso.',
          icon: Icons.error_outline,
          color: AppColors.danger,
          bg: Color(0x1AEF4444),
          border: AppColors.danger,
          esEnCurso: false,
        );
    }
  }
}

class _EstadoConfig {
  final String titulo;
  final String descripcion;
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final bool esEnCurso;

  const _EstadoConfig({
    required this.titulo,
    required this.descripcion,
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.esEnCurso,
  });
}

// ======================================================================
// Resultado exitoso
// ======================================================================
class _ResultadoExitoso extends StatelessWidget {
  final TrabajoGeneracionDetalle detalle;
  final VoidCallback onDescargar;
  final bool descargando;

  const _ResultadoExitoso({
    required this.detalle,
    required this.onDescargar,
    required this.descargando,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Backend generado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(
                    label: 'Entidades',
                    value: '${detalle.totalEntidades}',
                  ),
                  const SizedBox(width: 24),
                  _Stat(
                    label: 'Campos',
                    value: '${detalle.totalCampos}',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tabla de entidades
        if (detalle.entidades.isNotEmpty) ...[
          const Text(
            'Entidades generadas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface900,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surface800),
            ),
            child: Column(
              children: detalle.entidades.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.surface800),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.nombreClaseJava,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Text(
                        e.nombreTabla,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.surface500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${e.totalCampos}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.surface400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Botón descargar
        ElevatedButton.icon(
          onPressed: descargando ? null : onDescargar,
          icon: descargando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download_outlined, size: 18),
          label: Text(descargando ? 'Descargando…' : 'Descargar ZIP'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.surface500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Resultado fallido
// ======================================================================
class _ResultadoFallido extends StatelessWidget {
  const _ResultadoFallido();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'La generación falló',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Revisá los logs del backend o intentá generar de nuevo.',
            style: TextStyle(fontSize: 12, color: AppColors.surface400),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.proyectos),
            child: const Text('Volver a proyectos'),
          ),
        ],
      ),
    );
  }
}