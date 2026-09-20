// lib/features/ia_assistant/presentation/widgets/voice_button.dart
//
// Botón de dictado por voz usando `speech_to_text`.
//
// Flujo:
// 1. Pide permiso de micrófono.
// 2. Inicia el reconocimiento con locale es-BO.
// 3. Al detectar texto final, llama a `onResultado`.
// 4. Se detiene automáticamente cuando el usuario deja de hablar.

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/permissions/permission_service.dart';
import '../../../../core/theme/app_colors.dart';

class VoiceButton extends StatefulWidget {
  final void Function(String texto) onResultado;
  final bool enabled;

  const VoiceButton({
    super.key,
    required this.onResultado,
    this.enabled = true,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  final _speech = SpeechToText();

  bool _inicializado = false;
  bool _escuchando = false;
  bool _soportado = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final disponible = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
      if (!mounted) return;
      setState(() {
        _inicializado = true;
        _soportado = disponible;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inicializado = true;
        _soportado = false;
      });
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _escuchando = false);

    String mensaje;
    switch (error.errorMsg) {
      case 'error_no_match':
        mensaje = 'No se entendió el audio. Probá de nuevo.';
        break;
      case 'error_audio':
        mensaje = 'Error de audio. Verificá el micrófono.';
        break;
      case 'error_network':
        mensaje = 'Sin conexión para reconocimiento.';
        break;
      default:
        mensaje = 'Error de reconocimiento: ${error.errorMsg}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' && _escuchando) {
      setState(() => _escuchando = false);
    }
  }

  Future<void> _toggle() async {
    if (!_soportado || !_inicializado) return;

    if (_escuchando) {
      await _speech.stop();
      if (mounted) setState(() => _escuchando = false);
      return;
    }

    // Verificar permiso
    final permiso = await PermissionService.instance.pedirMicrofono();
    if (!permiso) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de micrófono denegado')),
      );
      return;
    }

    setState(() => _escuchando = true);

    try {
      await _speech.listen(
        onResult: _onResult,
        localeId: 'es_BO',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _escuchando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar micrófono: $e')),
      );
    }
  }

  void _onResult(SpeechRecognitionResult resultado) {
    if (!resultado.finalResult) return;

    final texto = resultado.recognizedWords.trim();
    if (texto.isEmpty) return;

    setState(() => _escuchando = false);
    widget.onResultado(texto);
  }

  @override
  Widget build(BuildContext context) {
    if (!_soportado) {
      return const IconButton(
        onPressed: null,
        icon: Icon(Icons.mic_off, size: 20),
        tooltip: 'Reconocimiento de voz no disponible',
        color: AppColors.surface600,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (_escuchando)
          const _PulseAnimation(),
        Material(
          color: _escuchando ? AppColors.danger : Colors.transparent,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: widget.enabled ? _toggle : null,
            icon: Icon(
              _escuchando ? Icons.mic : Icons.mic_none,
              size: 20,
            ),
            tooltip: _escuchando ? 'Detener' : 'Dictar por voz',
            color: _escuchando ? Colors.white : AppColors.brand400,
          ),
        ),
      ],
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  const _PulseAnimation();

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final escala = 1 + (_controller.value * 0.4);
        final opacidad = 1 - _controller.value;

        return Container(
          width: 40 * escala,
          height: 40 * escala,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger.withValues(alpha: opacidad * 0.4),
          ),
        );
      },
    );
  }
}