import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/site.dart';
import '../services/image_service.dart';

/// Provider para gerenciar as imagens de um site
/// Permite adicionar, trocar e excluir imagens (máximo 5 por site)
class ImageProvider extends ChangeNotifier {
  final ImageService _imageService = ImageService();

  // Site atual sendo gerenciado
  Site? _currentSite;

  // Lista de URLs de imagens (max 5)
  List<String> _imageUrls = [];

  // Estado de loading
  bool _isLoading = false;

  // Erro atual (se houver)
  String? _error;

  // Constantes
  static const int maxImages = 5;

  /// Getter para o site atual
  Site? get currentSite => _currentSite;

  /// Getter para as URLs de imagens
  List<String> get imageUrls => List.unmodifiable(_imageUrls);

  /// Getter para se está carregando
  bool get isLoading => _isLoading;

  /// Getter para o erro atual
  String? get error => _error;

  /// Getter para se pode adicionar mais imagens
  bool get canAddImage => _imageUrls.length < maxImages;

  /// Getter para contagem de imagens
  int get imageCount => _imageUrls.length;

  /// Inicializa o provider
  static Future<ImageProvider> create() async {
    await ImageService.initialize();
    return ImageProvider();
  }

  /// Carrega as imagens de um site
  Future<void> loadSiteImages(Site site) async {
    print('ImageProvider: loadSiteImages - siteId: ${site.siteId}');
    print('ImageProvider: loadSiteImages - imagens carregadas: ${site.imageUrls.length}');
    _currentSite = site;
    _imageUrls = List.from(site.imageUrls);
    _error = null;
    notifyListeners();
  }

  /// Adiciona uma nova imagem (de arquivo para upload)
  /// Retorna true se bem-sucedido, false caso contrário
  Future<bool> addImage(File imageFile) async {
    if (!canAddImage) {
      _error = 'Máximo de $maxImages imagens atingido';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Comprime a imagem
      final compressedImage = await _imageService.compressImage(imageFile);

      // Faz upload para Cloudinary
      final imageUrl = await _imageService.uploadToCloudinary(compressedImage);

      if (imageUrl == null) {
        _error = 'Erro ao fazer upload da imagem';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Adiciona a URL à lista
      _imageUrls.add(imageUrl);
      _isLoading = false;
      _error = null;
      notifyListeners();

      // Sincroniza com a planilha Google Sheets
      if (_currentSite != null) {
        await _imageService.syncToGoogleSheets(_currentSite!.siteId, _imageUrls);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Troca uma imagem existente por uma nova
  /// Retorna true se bem-sucedido, false caso contrário
  Future<bool> replaceImage(int index, File newImageFile) async {
    if (index < 0 || index >= _imageUrls.length) {
      _error = 'Índice inválido';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Comprime a nova imagem
      final compressedImage = await _imageService.compressImage(newImageFile);

      // Faz upload para Cloudinary
      final newImageUrl = await _imageService.uploadToCloudinary(compressedImage);

      if (newImageUrl == null) {
        _error = 'Erro ao fazer upload da nova imagem';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Substitui a URL
      _imageUrls[index] = newImageUrl;
      _isLoading = false;
      _error = null;
      notifyListeners();

      // Sincroniza com a planilha Google Sheets
      if (_currentSite != null) {
        await _imageService.syncToGoogleSheets(_currentSite!.siteId, _imageUrls);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Exclui uma imagem
  /// Retorna true se bem-sucedido, false caso contrário
  Future<bool> deleteImage(int index) async {
    if (index < 0 || index >= _imageUrls.length) {
      _error = 'Índice inválido';
      notifyListeners();
      return false;
    }

    // Remove da lista
    final removedUrl = _imageUrls.removeAt(index);
    _error = null;
    notifyListeners();

    // Sincroniza com a planilha Google Sheets
    if (_currentSite != null) {
      await _imageService.syncToGoogleSheets(_currentSite!.siteId, _imageUrls);
    }

    // Nota: A deleção física do Cloudinary não é implementada
    // pois requer autenticação completa (API key + secret)
    // A URL removida permanecerá no Cloudinary até ser deletada manualmente

    debugPrint('Imagem removida localmente: $removedUrl');
    return true;
  }

  /// Limpa todas as imagens
  void clearImages() {
    _imageUrls.clear();
    _error = null;
    notifyListeners();
  }

  /// Limpa o erro atual
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Gera URL de thumbnail para uma imagem
  String getThumbnailUrl(int index, {int width = 200, int height = 200}) {
    if (index < 0 || index >= _imageUrls.length) return '';
    return _imageService.getThumbnailUrl(_imageUrls[index], width: width, height: height);
  }

  /// Gera URL de thumbnail para uma URL específica
  String getThumbnailUrlForUrl(String imageUrl, {int width = 200, int height = 200}) {
    return _imageService.getThumbnailUrl(imageUrl, width: width, height: height);
  }

  /// Verifica se o Cloudinary está configurado
  bool get isCloudinaryConfigured => _imageService.isCloudinaryConfigured;

  /// Retorna o site atual com as imagens atualizadas
  Site? getUpdatedSite() {
    if (_currentSite == null) return null;

    // Cria uma nova instância do Site com as imagens atualizadas
    return Site(
      siteId: _currentSite!.siteId,
      sigla: _currentSite!.sigla,
      nome: _currentSite!.nome,
      endereco: _currentSite!.endereco,
      municipio: _currentSite!.municipio,
      tecnico: _currentSite!.tecnico,
      latitude: _currentSite!.latitude,
      longitude: _currentSite!.longitude,
      detentora: _currentSite!.detentora,
      uc: _currentSite!.uc,
      status: _currentSite!.status,
      imageUrls: _imageUrls,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
