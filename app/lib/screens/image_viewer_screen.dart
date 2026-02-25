import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../services/image_service.dart';
import '../widgets/image_picker_dialog.dart';

/// Tela de visualização de imagem em tela cheia com zoom
/// Permite navegar entre imagens, trocar e excluir
class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final List<String> allImageUrls;
  final int initialIndex;
  final Function(int index, String newUrl)? onImageReplace;
  final Function(int index)? onImageDelete;
  final Function(File file)? onNewImageSelected;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.allImageUrls,
    this.initialIndex = 0,
    this.onImageReplace,
    this.onImageDelete,
    this.onNewImageSelected,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late int _currentIndex;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allImageUrls.indexOf(widget.imageUrl);
    if (_currentIndex < 0) _currentIndex = 0;
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentIndex < widget.allImageUrls.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _resetZoom();
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _resetZoom();
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _showReplaceOptions() async {
    final file = await showImagePickerDialog(context);
    if (file != null && widget.onImageReplace != null) {
      // Para implementar troca, precisamos passar o File para o callback
      // Mas o onImageReplace atual espera apenas o índice e a nova URL
      // Por enquanto, vamos mostrar uma mensagem
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Função de trocar da ImageViewerScreen requer implementação adicional'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir foto'),
        content: const Text('Tem certeza que deseja excluir esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onImageDelete?.call(_currentIndex);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = widget.allImageUrls.isNotEmpty
        ? widget.allImageUrls[_currentIndex]
        : widget.imageUrl;
    final hasMultipleImages = widget.allImageUrls.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Imagem principal com zoom
          GestureDetector(
            onDoubleTap: () {
              final currentScale = _transformationController.value.getMaxScaleOnAxis();
              if (currentScale > 1) {
                _resetZoom();
              } else {
                _transformationController.value = Matrix4.identity()..scale(2);
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: currentUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top bar com indicador e botão fechar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicador de posição
                    if (hasMultipleImages)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} de ${widget.allImageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Botão fechar
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botões de navegação lateral (se houver múltiplas imagens)
          if (hasMultipleImages) ...[
            // Botão anterior
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 36),
                    onPressed: _previousImage,
                  ),
                ),
              ),
            ),
            // Botão próximo
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white, size: 36),
                    onPressed: _nextImage,
                  ),
                ),
              ),
            ),
          ],

          // Bottom bar com ações
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão de trocar
                    _buildActionButton(
                      icon: Icons.camera_alt,
                      label: 'Trocar',
                      onTap: _showReplaceOptions,
                    ),
                    // Botão de compartilhar
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Compartilhar',
                      onTap: () {
                        // TODO: Implementar compartilhamento
                      },
                    ),
                    // Botão de excluir
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Excluir',
                      onTap: _showDeleteConfirm,
                      isDanger: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDanger ? AppColors.error : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDanger ? AppColors.error : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
