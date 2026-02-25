import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';

/// Dialog para seleção de fonte de imagem (câmera ou galeria)
class ImagePickerDialog extends StatelessWidget {
  final Function(File file) onImageSelected;
  final ImagePicker? customPicker;

  const ImagePickerDialog({
    super.key,
    required this.onImageSelected,
    this.customPicker,
  });

  @override
  Widget build(BuildContext context) {
    final picker = customPicker ?? ImagePicker();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecionar imagem',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Opção: Câmera
            _buildOption(
              context: context,
              icon: Icons.camera_alt,
              title: 'Câmera',
              subtitle: 'Tirar uma nova foto',
              onTap: () async {
                try {
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                    maxWidth: 1920,
                    maxHeight: 1920,
                  );
                  if (photo != null && context.mounted) {
                    Navigator.pop(context);
                    onImageSelected(File(photo.path));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao acessar câmera: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 12),

            // Opção: Galeria
            _buildOption(
              context: context,
              icon: Icons.photo_library,
              title: 'Galeria',
              subtitle: 'Escolher da galeria',
              onTap: () async {
                try {
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                    maxWidth: 1920,
                    maxHeight: 1920,
                  );
                  if (image != null && context.mounted) {
                    Navigator.pop(context);
                    onImageSelected(File(image.path));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao acessar galeria: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 24),

            // Botão cancelar
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mostra um dialog para selecionar imagem
/// Retorna a imagem selecionada ou null se cancelado
Future<File?> showImagePickerDialog(
  BuildContext context, {
  ImagePicker? customPicker,
}) async {
  File? selectedFile;

  await showDialog(
    context: context,
    builder: (context) => ImagePickerDialog(
      onImageSelected: (file) {
        selectedFile = file;
      },
      customPicker: customPicker,
    ),
  );

  return selectedFile;
}
