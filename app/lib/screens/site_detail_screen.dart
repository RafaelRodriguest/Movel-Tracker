import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/site.dart';
import '../theme/app_colors.dart';
import '../providers/image_provider.dart' as img;
import '../widgets/image_picker_dialog.dart';
import 'image_viewer_screen.dart';

/// Tela de detalhes de um Site específico
class SiteDetailScreen extends StatefulWidget {
  final Site site;

  const SiteDetailScreen({super.key, required this.site});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  late img.ImageProvider _imageProvider;
  List<String> _currentImageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _imageProvider = context.read<img.ImageProvider>();
    _currentImageUrls = List.from(widget.site.imageUrls);
    print('SiteDetailScreen: initState - siteId: ${widget.site.siteId}');
    print('SiteDetailScreen: initState - imagens iniciais: ${_currentImageUrls.length}');
    _imageProvider.loadSiteImages(widget.site);
  }

  Future<void> _launchGoogleMaps() async {
    final uri = Uri.parse(widget.site.googleMapsNavigationUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback para esquema geo se a URL web falhar
        await launchUrl(
          Uri.parse('geo:${widget.site.latitude},${widget.site.longitude}?q=${widget.site.latitude},${widget.site.longitude}'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Tenta geo como fallback final
      await launchUrl(
        Uri.parse('geo:${widget.site.latitude},${widget.site.longitude}'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _launchGoogleMapsView() async {
    final uri = Uri.parse(widget.site.googleMapsViewUrl);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Fallback para geo
      await launchUrl(
        Uri.parse('geo:${widget.site.latitude},${widget.site.longitude}?q=${widget.site.latitude},${widget.site.longitude}'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top App Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.site.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Mapa
                  _buildMapSection(context),

                  // Informações do site
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título e Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.site.nome,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Município
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.site.municipio,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: widget.site.ativo
                                              ? AppColors.success
                                              : AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.site.ativo
                                                ? 'Site Operacional'
                                                : 'Site Inativo',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: widget.site.ativo
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ID: ${widget.site.siteId}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Cards de informações
                        _buildInfoCards(context),
                        const SizedBox(height: 24),

                        // Seção de fotos (placeholder)
                        _buildPhotosSection(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botão de ação fixo
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _launchGoogleMaps,
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text(
                    'INICIAR ROTA NO GOOGLE MAPS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(widget.site.latitude, widget.site.longitude),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.claro.claro_sites_ma',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.site.latitude, widget.site.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Botão de minha localização
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: AppColors.textSecondary),
                onPressed: _launchGoogleMapsView,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    return Column(
      children: [
        // Endereço
        _buildInfoCard(
          icon: Icons.map_outlined,
          label: 'Endereço',
          value: widget.site.endereco,
          onTap: () {},
        ),
        const SizedBox(height: 12),

        // Técnico
        _buildInfoCard(
          icon: Icons.person_outline,
          label: 'Técnico',
          value: widget.site.tecnico,
          onTap: () {},
        ),
        const SizedBox(height: 12),

        // Coordenadas e Proprietário (grid)
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.explore,
                label: 'Coordenadas',
                value: widget.site.coordenadasFormatadas,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.business_center,
                label: 'Proprietário',
                value: widget.site.detentora,
                isCompact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sigla e UC (grid)
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.tag,
                label: 'Sigla',
                value: widget.site.sigla,
                isCompact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.electric_bolt,
                label: 'UC',
                value: widget.site.uc,
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: Icon(
                Icons.content_copy,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: 18,
              ),
              onPressed: onTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    final imageCount = _currentImageUrls.length;
    final hasImages = imageCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fotos do Local',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            if (imageCount > 0)
              Text(
                '$imageCount/5',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hasImages ? imageCount + 1 : 1,
            itemBuilder: (context, index) {
              // Botão de adicionar nova foto (apenas se menos de 5)
              if (index == imageCount && imageCount < 5) {
                return _buildAddPhotoButton(context);
              }

              // Exibe foto existente
              if (hasImages && index < imageCount) {
                return _buildPhotoCard(context, index, _currentImageUrls[index]);
              }

              // Placeholder inicial (sem fotos)
              return _buildEmptyState(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(BuildContext context, int index, String imageUrl) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Stack(
        children: [
          // Imagem com cache
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CachedNetworkImage(
              imageUrl: widget.site.getThumbnailUrl(imageUrl, width: 200, height: 200),
              width: 98,
              height: 98,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 98,
                height: 98,
                color: AppColors.backgroundLight,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 98,
                height: 98,
                color: AppColors.backgroundLight,
                child: Icon(
                  Icons.broken_image,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
            ),
          ),
          // Botão de ações (tap para visualizar)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _showImageOptions(context, index, imageUrl);
                },
                child: Container(),
              ),
            ),
          ),
          // Indicador de número
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showImagePicker(context);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Adicionar',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showImagePicker(context);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 28,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Adicionar foto',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) async {
    print('_showImagePicker: Iniciado');
    if (_isLoading) {
      print('_showImagePicker: Já carregando, ignorando');
      return;
    }

    final file = await showImagePickerDialog(context);
    print('_showImagePicker: Imagem selecionada: ${file != null ? "null" : file?.path}');

    if (file != null && context.mounted) {
      print('_showImagePicker: Chamando addImage...');
      setState(() {
        _isLoading = true;
      });

      final success = await _imageProvider.addImage(file);
      print('_showImagePicker: Result addImage: $success');

      if (success && mounted) {
        setState(() {
          _currentImageUrls = List.from(_imageProvider.imageUrls);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto adicionada com sucesso!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_imageProvider.error ?? 'Erro ao adicionar foto'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showImageOptions(BuildContext context, int index, String imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Preview da imagem
                    if (imageUrl.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.backgroundLight,
                              child: Icon(
                                Icons.broken_image,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Botão de visualizar em tela cheia
                    ListTile(
                      leading: Icon(Icons.fullscreen, color: AppColors.primary),
                      title: const Text('Visualizar em tela cheia'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              imageUrl: imageUrl,
                              allImageUrls: _currentImageUrls,
                              initialIndex: index,
                              onImageDelete: (index) async {
                                print('_showImageOptions: Excluindo imagem $index');
                                Navigator.pop(context);
                                final success = await _imageProvider.deleteImage(index);
                                print('_showImageOptions: Result deleteImage: $success');
                                if (success && mounted) {
                                  setState(() {
                                    _currentImageUrls = List.from(_imageProvider.imageUrls);
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    // Botão de trocar
                    ListTile(
                      leading: Icon(Icons.camera_alt, color: AppColors.primary),
                      title: const Text('Trocar foto'),
                      onTap: () async {
                        Navigator.pop(context);
                        if (_isLoading) return;

                        final file = await showImagePickerDialog(context);
                        if (file != null && context.mounted) {
                          print('_showImageOptions: Trocando imagem $index');
                          setState(() {
                            _isLoading = true;
                          });

                          final success = await _imageProvider.replaceImage(index, file);
                          print('_showImageOptions: Result replaceImage: $success');

                          if (success && mounted) {
                            setState(() {
                              _currentImageUrls = List.from(_imageProvider.imageUrls);
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Foto trocada com sucesso!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_imageProvider.error ?? 'Erro ao trocar foto'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    // Botão de excluir
                    ListTile(
                      leading: Icon(Icons.delete, color: AppColors.error),
                      title: const Text('Excluir foto'),
                      onTap: () async {
                        Navigator.pop(context);

                        // Mostrar confirmação
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Excluir foto'),
                            content: const Text('Tem certeza que deseja excluir esta foto?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Excluir'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && mounted) {
                          final success = await _imageProvider.deleteImage(index);
                          if (success && mounted) {
                            setState(() {
                              _currentImageUrls = List.from(_imageProvider.imageUrls);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Foto excluída com sucesso!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
