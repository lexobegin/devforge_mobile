// lib/features/ia_assistant/presentation/widgets/ia_panel.dart
//
// Panel del asistente de IA dentro del editor.
// Dos tabs: Chat (texto/voz) y Visión (bocetos).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/ia_entity.dart';
import '../providers/ia_provider.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'image_source_picker.dart';
import 'vision_result_view.dart';
import 'voice_button.dart';

import '../../../diagrama_editor/presentation/providers/diagrama_provider.dart';

class IAPanel extends ConsumerStatefulWidget {
  final int proyectoId;
  final int diagramaId;
  final VoidCallback onCerrar;

  const IAPanel({
    super.key,
    required this.proyectoId,
    required this.diagramaId,
    required this.onCerrar,
  });

  @override
  ConsumerState<IAPanel> createState() => _IAPanelState();
}

class _IAPanelState extends ConsumerState<IAPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface900,
        border: Border(left: BorderSide(color: AppColors.surface800)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surface800),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.brand600.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppColors.brand400,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Asistente IA',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onCerrar,
                  visualDensity: VisualDensity.compact,
                  color: AppColors.surface400,
                ),
              ],
            ),
          ),

          // Tabs
          Row(
            children: [
              _TabBtn(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                active: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _TabBtn(
                icon: Icons.image_outlined,
                label: 'Imagen',
                active: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: _tab == 0
                ? _ChatTab(
                    proyectoId: widget.proyectoId,
                    diagramaId: widget.diagramaId,
                  )
                : _VisionTab(diagramaId: widget.diagramaId),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.brand500 : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? AppColors.brand400 : AppColors.surface400,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.brand400 : AppColors.surface400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Tab de chat
// ======================================================================
class _ChatTab extends ConsumerStatefulWidget {
  final int proyectoId;
  final int diagramaId;

  const _ChatTab({required this.proyectoId, required this.diagramaId});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _textoCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty) return;

    _textoCtrl.clear();
    _scrollToBottom();

    try {
      await ref.read(iaChatProvider.notifier).enviarPrompt(
            proyectoId: widget.proyectoId,
            texto: texto,
            idDiagrama: widget.diagramaId,
          );
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _aplicarAcciones(ChatMessage mensaje) async {
    final notifier = ref.read(diagramaProvider.notifier);
    final clases = ref.read(diagramaProvider).clases;

    int aplicadas = 0;
    int errores = 0;

    for (final accion in mensaje.acciones) {
      try {
        switch (accion.tipo.toUpperCase()) {
          case 'CREAR_CLASE':
            final nombre = (accion.payload['nombre'] as String?)?.trim() ?? '';
            if (nombre.isEmpty) continue;
            await notifier.crearClase(
              nombre: nombre,
              posX: 200 + (aplicadas * 240.0),
              posY: 150 + (aplicadas * 40.0),
            );
            aplicadas++;
            break;

          case 'AGREGAR_ATRIBUTO':
            final claseNombre =
                (accion.payload['clase'] as String?)?.trim() ?? '';
            final atributoNombre =
                (accion.payload['atributo'] as String?)?.trim() ?? '';
            final tipoDato =
                (accion.payload['tipo_dato'] as String?)?.trim() ?? 'String';

            if (claseNombre.isEmpty || atributoNombre.isEmpty) continue;

            // Buscar la clase
            final clase = clases.firstWhere(
              (c) => c.nombre.toLowerCase() == claseNombre.toLowerCase(),
              orElse: () =>
                  throw StateError('Clase no encontrada: $claseNombre'),
            );

            await notifier.agregarAtributo(
              clase.id,
              nombre: atributoNombre,
              tipoDato: tipoDato,
            );
            aplicadas++;
            break;

          default:
            // Tipo no soportado todavía
            continue;
        }
      } catch (_) {
        errores++;
      }
    }

    if (!mounted) return;
    if (aplicadas > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$aplicadas acción${aplicadas == 1 ? '' : 'es'} aplicada${aplicadas == 1 ? '' : 's'}'
            '${errores > 0 ? ' ($errores con error)' : ''}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo aplicar ninguna acción')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iaChatProvider);

    return Column(
      children: [
        // Historial
        Expanded(
          child: state.mensajes.isEmpty
              ? const _EmptyChat()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: state.mensajes.length,
                  itemBuilder: (_, i) => _MensajeBubble(
                    mensaje: state.mensajes[i],
                    onAplicar: (id) async {
                      final msg = state.mensajes.firstWhere((m) => m.id == id);
                      await _aplicarAcciones(msg);
                      ref.read(iaChatProvider.notifier).marcarAplicada(id);
                    },
                  ),
                ),
        ),

        // Input
        // Input
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.surface800),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textoCtrl,
                      enabled: !state.enviando,
                      maxLines: 3,
                      minLines: 1,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(
                        hintText: 'Escribí un prompt…',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Botón de voz
                  VoiceButton(
                    enabled: !state.enviando,
                    onResultado: (texto) {
                      _textoCtrl.text = texto;
                      _enviar();
                    },
                  ),

                  // Botón de enviar
                  IconButton(
                    onPressed: state.enviando ? null : _enviar,
                    icon: state.enviando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: AppColors.brand400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 40, color: AppColors.brand500),
            SizedBox(height: 12),
            Text(
              'Asistente IA',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Pedile a la IA que cree clases, agregue atributos o modifique '
              'el diagrama en lenguaje natural.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.surface500),
            ),
          ],
        ),
      ),
    );
  }
}

class _MensajeBubble extends StatelessWidget {
  final ChatMessage mensaje;
  final void Function(String id) onAplicar;

  const _MensajeBubble({required this.mensaje, required this.onAplicar});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.esUsuario;

    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: esUsuario ? AppColors.brand600 : AppColors.surface800,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mensaje.texto,
              style: TextStyle(
                fontSize: 12,
                color: esUsuario ? Colors.white : AppColors.surface200,
              ),
            ),
            if (mensaje.tieneAcciones && !mensaje.aplicada) ...[
              const SizedBox(height: 8),
              ...mensaje.acciones.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${a.etiqueta}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.surface400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onAplicar(mensaje.id),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
            if (mensaje.aplicada) ...[
              const SizedBox(height: 4),
              const Text(
                '✓ Aplicado',
                style: TextStyle(fontSize: 10, color: AppColors.success),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Tab de visión
// ======================================================================
class _VisionTab extends ConsumerStatefulWidget {
  final int diagramaId;

  const _VisionTab({required this.diagramaId});

  @override
  ConsumerState<_VisionTab> createState() => _VisionTabState();
}

class _VisionTabState extends ConsumerState<_VisionTab> {
  File? _imagenSeleccionada;

  Future<void> _elegirImagen() async {
    // Pedir permiso según la fuente
    final archivo = await ImageSourcePicker.show(context);
    if (archivo == null) return;

    setState(() => _imagenSeleccionada = File(archivo.path));

    try {
      await ref.read(visionProvider.notifier).reconocerParaDiagrama(
            diagramaId: widget.diagramaId,
            imagen: File(archivo.path),
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar: $e')),
      );
    }
  }

  void _descartar() {
    setState(() => _imagenSeleccionada = null);
    ref.read(visionProvider.notifier).limpiar();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visionProvider);

    // Si hay resultado, mostrar el resultado
    if (state.resultado != null) {
      return VisionResultView(
        resultado: state.resultado!,
        onDescartar: _descartar,
      );
    }

    // Si está procesando, mostrar progreso
    if (state.procesando) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_imagenSeleccionada != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imagenSeleccionada!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text(
                'Procesando imagen…',
                style: TextStyle(fontSize: 13, color: AppColors.surface400),
              ),
              const SizedBox(height: 4),
              const Text(
                'Esto puede tardar unos segundos',
                style: TextStyle(fontSize: 11, color: AppColors.surface500),
              ),
            ],
          ),
        ),
      );
    }

    // Vista inicial: subir boceto
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: _elegirImagen,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.surface700,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppColors.surface500,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Subir boceto',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Foto de un diagrama de clases.\n'
                          'La IA lo reconstruye automáticamente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.surface500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _elegirImagen,
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _elegirImagen,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
