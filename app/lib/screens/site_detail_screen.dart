import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/site.dart';
import '../providers/auth_provider.dart';
import '../providers/site_provider.dart';
import '../services/cloudinary_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'site_operacional_screen.dart';

/// Tela de detalhes de um Site específico
class SiteDetailScreen extends StatefulWidget {
  final Site site;

  const SiteDetailScreen({super.key, required this.site});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  late List<String?> _imageUrls;
  late Site _currentSite;
  final List<bool> _loadingSlots = List.filled(5, false);
  final _cloudinaryService = CloudinaryService();
  final _supabaseService = SupabaseService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentSite = widget.site;
    _imageUrls = List.from(widget.site.imageUrls);
  }

  // Atualiza estado local + provider atomicamente
  void _syncUrls(List<String?> urls) {
    setState(() => _imageUrls = urls);
    context.read<SiteProvider>().updateSiteImageUrls(widget.site.siteId, urls);
  }

  Future<void> _pickAndUpload(int index, {required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null) return;

    setState(() => _loadingSlots[index] = true);
    String? uploadedUrl;
    try {
      uploadedUrl = await _cloudinaryService.upload(File(picked.path));
      final isNew = _imageUrls[index] == null;
      await _supabaseService.updateFoto(widget.site.siteId, index, uploadedUrl);
      await _supabaseService.insertAuditLog(
        siteId: widget.site.siteId,
        action: isNew ? 'foto_add' : 'foto_update',
        detail: 'foto_${index + 1} → $uploadedUrl',
      );
      final updated = List<String?>.from(_imageUrls);
      updated[index] = uploadedUrl;
      if (mounted) _syncUrls(updated);
    } catch (e) {
      if (mounted) {
        final msg = uploadedUrl != null
            ? 'Foto enviada mas não foi possível salvar. Tente novamente.'
            : 'Falha no envio da foto. Verifique a conexão.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSlots[index] = false);
    }
  }

  Future<void> _deletePhoto(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover foto'),
        content: const Text('Tem certeza que deseja remover esta foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loadingSlots[index] = true);
    try {
      await _supabaseService.deleteFoto(widget.site.siteId, index);
      await _supabaseService.insertAuditLog(
        siteId: widget.site.siteId,
        action: 'foto_delete',
        detail: 'foto_${index + 1} removida',
      );
      final updated = List<String?>.from(_imageUrls);
      updated[index] = null;
      if (mounted) _syncUrls(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao remover foto.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingSlots[index] = false);
    }
  }

  // Slot vazio: opções para adicionar foto
  void _showAddOptions(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Adicionar foto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(index, fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(index, fromCamera: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Slot com foto: visualizar, trocar ou excluir
  void _showPhotoOptions(int index, String url) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.fullscreen),
              title: const Text('Visualizar foto'),
              onTap: () {
                Navigator.pop(context);
                _viewPhoto(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_outlined),
              title: const Text('Trocar foto'),
              onTap: () {
                Navigator.pop(context);
                _showAddOptions(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deletePhoto(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps() async {
    final site = widget.site;
    // 1ª opção: intent nativo google.navigation: — abre navegação turn-by-turn direto no Maps
    final navIntent = Uri.parse(site.googleMapsNavIntent);
    try {
      final launched = await launchUrl(navIntent, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    // 2ª opção: geo: URI — abre o Maps na localização
    final geoUri = Uri.parse('geo:${site.latStr},${site.lngStr}?q=${site.latStr},${site.lngStr}(${Uri.encodeComponent(site.nome)})');
    try {
      final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    // 3ª opção: URL web como último fallback
    await launchUrl(
      Uri.parse(site.googleMapsNavigationUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _launchGoogleMapsView() async {
    final site = widget.site;
    // 1ª opção: geo: URI com label do site
    final geoUri = Uri.parse('geo:${site.latStr},${site.lngStr}?q=${site.latStr},${site.lngStr}(${Uri.encodeComponent(site.nome)})');
    try {
      final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (launched) return;
    } catch (_) {}

    // 2ª opção: URL web
    await launchUrl(
      Uri.parse(site.googleMapsViewUrl),
      mode: LaunchMode.externalApplication,
    );
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

        _buildInfoCard(
          icon: Icons.person_outline,
          label: 'Técnico',
          value: widget.site.tecnico,
          onTap: () {},
        ),
        const SizedBox(height: 12),

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
        const SizedBox(height: 12),

        _buildOperacionalCard(context),
      ],
    );
  }

  Widget _buildOperacionalCard(BuildContext context) {
    // Lê diretamente do provider para reagir imediatamente a qualquer atualização
    final allSites = context.watch<SiteProvider>().allSites;
    final site = allSites.firstWhere(
      (s) => s.siteId == widget.site.siteId,
      orElse: () => _currentSite,
    );
    final isCellOwner =
        context.watch<AuthProvider>().profile?.isCellOwner ?? false;

    // Verifica se há algum campo operacional preenchido
    final temDados = [
      site.chavePortao,
      site.chaveGradil01,
      site.chaveGradil02,
      site.fonte01,
      site.fonte02,
      site.consumoFonte01,
      site.consumoFonte02,
      site.bateriasFonte01,
      site.bateriasFonte02,
    ].any((v) => v != null && v.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Informações do Site',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              if (isCellOwner)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SiteOperacionalScreen(site: site),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          if (temDados) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Chaves
            if (site.chavePortao != null || site.chaveGradil01 != null || site.chaveGradil02 != null) ...[
              _buildOperacionalRow('Chave Portão', site.chavePortao),
              _buildOperacionalRow('Chave Gradil 01', site.chaveGradil01),
              _buildOperacionalRow('Chave Gradil 02', site.chaveGradil02),
              const SizedBox(height: 8),
            ],
            // Gabinete 01
            if (site.fonte01 != null || site.consumoFonte01 != null || site.bateriasFonte01 != null) ...[
              _buildOperacionalSubtitle('Gabinete 01'),
              _buildOperacionalRow('Fonte', site.fonte01),
              _buildOperacionalRow('Consumo', site.consumoFonte01 != null ? '${site.consumoFonte01} A' : null),
              _buildOperacionalRow('Baterias', site.bateriasFonte01),
              const SizedBox(height: 8),
            ],
            // Gabinete 02
            if (site.fonte02 != null || site.consumoFonte02 != null || site.bateriasFonte02 != null) ...[
              _buildOperacionalSubtitle('Gabinete 02'),
              _buildOperacionalRow('Fonte', site.fonte02),
              _buildOperacionalRow('Consumo', site.consumoFonte02 != null ? '${site.consumoFonte02} A' : null),
              _buildOperacionalRow('Baterias', site.bateriasFonte02),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Text(
              isCellOwner
                  ? 'Nenhuma informação registrada. Toque em Editar para preencher.'
                  : 'Nenhuma informação do site registrada.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOperacionalSubtitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildOperacionalRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildTechnologiesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tecnologias Disponíveis',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.site.tecnologias.map((tech) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tech,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (_, index) => _buildPhotoSlot(index),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(int index) {
    final url = _imageUrls.length > index ? _imageUrls[index] : null;
    final isLoading = _loadingSlots[index];
    // watch garante rebuild quando o perfil terminar de carregar
    final isCellOwner =
        context.watch<AuthProvider>().profile?.isCellOwner ?? false;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              if (url != null) {
                // cell_owner vê opções completas; geral só visualiza
                if (isCellOwner) {
                  _showPhotoOptions(index, url);
                } else {
                  _viewPhoto(url);
                }
              } else if (isCellOwner) {
                _showAddOptions(index);
              }
            },
      child: Container(
        width: 96,
        height: 96,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : url != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isCellOwner)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 28,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Foto ${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
