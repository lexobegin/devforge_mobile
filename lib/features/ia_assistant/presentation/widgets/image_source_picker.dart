// lib/features/ia_assistant/presentation/widgets/image_source_picker.dart
//
// Bottom sheet para elegir fuente de imagen: cámara o galería.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

class ImageSourcePicker {
  /// Muestra el bottom sheet y devuelve el archivo elegido (o null si
  /// el usuario cancela).
  static Future<XFile?> show(BuildContext context) async {
    return showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: AppColors.surface900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _ImageSourceSheet(),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  Future<void> _elegir(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final archivo = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      if (!context.mounted) return;
      Navigator.pop(context, archivo);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al elegir imagen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            'Subir boceto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Foto de un diagrama de clases para reconstruir con IA.',
            style: TextStyle(fontSize: 12, color: AppColors.surface400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          _SourceTile(
            icon: Icons.camera_alt_outlined,
            titulo: 'Tomar foto',
            subtitulo: 'Usar la cámara del dispositivo',
            onTap: () => _elegir(context, ImageSource.camera),
          ),
          const SizedBox(height: 8),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            titulo: 'Elegir de la galería',
            subtitulo: 'Seleccionar una imagen existente',
            onTap: () => _elegir(context, ImageSource.gallery),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface800.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brand600.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.brand400, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.surface400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.surface500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}