import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/site.dart';
import '../services/image_service.dart';

/// Provider para gerenciar as imagens de um site
/// Permite adicionar, trocar e excluir imagens (máximo 5 por site)
/// Com proteções de segurança e validações
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

  // Timestamp da última operação para rate limiting
  DateTime? _lastOperationTime;

  // Constantes
  static const int maxImages = 5;

  // Rate limiting: mínimo de 2 segundos entre operações
  static const Duration rateLimitDelay = Duration(seconds: 2);

  // Timeout para operações de upload (30 segundos)
  static const Duration uploadTimeout = Duration(seconds: 30);

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

  /// Valida se uma URL do Cloudinary é segura (HTTPS, domínio correto)
  bool _isSecureCloudinaryUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https' && uri.host.contains('cloudinary.com');
    } catch (_) {
      return false;
    }
  }

  /// Verifica se pode fazer uma operação (rate limiting)
  bool _canPerformOperation() {
    if (_lastOperationTime == null) return true;

    final elapsed = DateTime.now().difference(_lastOperationTime!);
    if (elapsed >= rateLimitDelay) {
      return true;
    }

    debugPrint('Rate limiting: Operação muito rápida');
    return false;
  }

  /// Sanitiza uma lista de URLs para evitar duplicatas e URLs inválidas
  List<String> _sanitizeImageUrls(List<String> urls) {
    final sanitized = <String>[];

    for (final url in urls) {
      // Remove URLs vazias ou apenas espaços
      if (url.trim().isEmpty) continue;

      // Remove URLs duplicadas
      if (!sanitized.contains(url)) {
        sanitized.add(url);
      }
    }

    return sanitized;
  }

  /// Valida se um File é válido (não null, existe, etc)
  bool _validateFile(File? file) {
    if (file == null) {
      debugPrint('Erro: File é null');
      return false;
    }

    if (!file.existsSync()) {
      debugPrint('Erro: Arquivo não existe: ${file.path}');
      return false;
    }

    return true;
  }

  /// Inicializa o provider
  static Future<ImageProvider> create() async {
    await ImageService.initialize();
    return ImageProvider();
  }

  /// Carrega as imagens de um site
  Future<void> loadSiteImages(Site site) async {
    debugPrint('ImageProvider: loadSiteImages - siteId: ${site.siteId}');
    debugPrint('ImageProvider: loadSiteImages - imagens carregadas: ${site.imageUrls.length}');

    _currentSite = site;

    // Sanitiza URLs carregadas do site
    final sanitizedUrls = _sanitizeImageUrls(site.imageUrls);

    _imageUrls = sanitizedUrls;
    _error = null;
    _lastOperationTime = null;
    notifyListeners();
  }

  /// Adiciona uma nova imagem (de arquivo para upload)
  /// Retorna true se bem-sucedido, false caso contrário
  Future<bool> addImage(File imageFile) async {
    // Validação 1: File válido
    if (!_validateFile(imageFile)) {
      _error = 'Arquivo inválido';
      notifyListeners();
      return false;
    }

    // Validação 2: Rate limiting
    if (!_canPerformOperation()) {
      _error = 'Aguarde alguns segundos antes de tentar novamente';
      notifyListeners();
      return false;
    }

    // Validação 3: Máximo de imagens
    if (!canAddImage) {
      _error = 'Máximo de $maxImages imagens atingido';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _lastOperationTime = DateTime.now();
    notifyListeners();

    try {
      // Comprime a imagem
      debugPrint('Comprimindo imagem...');
      final compressedImage = await _imageService.compressImage(imageFile);

      // Faz upload para Cloudinary
      debugPrint('Fazendo upload para Cloudinary...');
      final imageUrl = await _imageService.uploadToCloudinary(compressedImage);

      if (imageUrl == null || imageUrl!.isEmpty) {
        _error = 'Erro ao fazer upload da imagem';
        _isLoading = false;
        _lastOperationTime = null;
        notifyListeners();
        return false;
      }

      // Validação 4: URL segura
      if (!_isSecureCloudinaryUrl(imageUrl)) {
        _error = 'URL retornada não é segura';
        _isLoading = false;
        _lastOperationTime = null;
        notifyListeners();
        return false;
      }

      // Adiciona a URL à lista
      _imageUrls.add(imageUrl);
      _isLoading = false;
      _error = null;
      notifyListeners();

      // Sincroniza com a planilha Google Sheets
      debugPrint('Sincronizando com Google Sheets...');
      if (_currentSite != null) {
        await _syncWithRetry(() =>
            _imageService.syncToGoogleSheets(_currentSite!.siteId, _imageUrls));
      }

      debugPrint('Imagem adicionada com sucesso');
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _lastOperationTime = null;
      notifyListeners();
      return false;
    }
  }

  /// Troca uma imagem existente por uma nova
  /// Retorna true se bem-sucedido, false caso contrário
  Future<bool> replaceImage(int index, File newImageFile) async {
    // Validação 1: Índice válido
    if (index < 0 || index >= _imageUrls.length) {
      _error = 'Índice inválido: deve estar entre 0 e ${_imageUrls.length - 1}';
      notifyListeners();
      return false;
    }

    // Validação 2: File válido
    if (!_validateFile(newImageFile)) {
      _error = 'Arquivo inválido';
      notifyListeners();
      return false;
    }

    // Validação 3: Rate limiting
    if (!_canPerformOperation()) {
      _error = 'Aguarde alguns segundos antes de tentar novamente';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _lastOperationTime = DateTime.now();
    notifyListeners();

    try {
      // Comprime a nova imagem
      debugPrint('Comprimindo nova imagem...');
      final compressedImage = await _imageService.compressImage(newImageFile);

      // Faz upload para Cloudinary
      debugPrint('Fazendo upload para Cloudinary...');
      final newImageUrl = await _imageService.uploadToCloudinary(compressedImage);

      if (newImageUrl == null || newImageUrl!.isEmpty) {
        _error = 'Erro ao fazer upload da nova imagem';
        _isLoading = false;
        _lastOperationTime = null;
        notifyListeners();
        return false;
      }

      // Validação 4: URL segura
      if (!_isSecureCloudinaryUrl(newImageUrl)) {
        _error = 'URL retornada não é segura';
        _isLoading = false;
        _lastOperationTime = null;
        notifyListeners();
        return false;
      }

      // Substitui a URL
      _imageUrls[index] = newImageUrl;
      _isLoading = false;
      _error = null;
      notifyListeners();

      // Sincroniza com a planilha Google Sheets
      debugPrint('Sincronizando com Google Sheets...');
      if (_currentSite != null) {
        await _syncWithRetry(() =>
            _imageService.syncToGoogleSheets(_currentSite!.siteId, _imageUrls));
      }

      debugPrint('Imagem substituída com sucesso');
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _lastOperationTime = null;
      notifyListeners();
      return false;
    }
  }

  /// Exclui uma imagem
  /// Retorna true se bem-sucedido, false caso contrário
  Future<bool> deleteImage(int index) async {
    // Validação 1: Índice válido
    if (index < 0 || index >= _imageUrls.length) {
      _error = 'Índice inválido: deve estar entre 0 e ${_imageUrls.length - 1}';
      notifyListeners();
      return false;
    }

    // Validação 2: Rate limiting
    if (!_canPerformOperation()) {
      _error = 'Aguarde alguns segundos antes de tentar novamente';
      notifyListeners();
      return false;
    }

    // Remove da lista
    final removedUrl = _imageUrls.removeAt(index);
    _error = null;
    _lastOperationTime = DateTime.now();
    notifyListeners();

    // Sincroniza com a planilha Google Sheets
    debugPrint('Sincronizando com Google Sheets...');
    if (_currentSite != null) {
      await _syncWithRetry(() =>
          _imageService.syncToGoogleSheets(_currentSite!.siteId, _imageUrls));
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
    _lastOperationTime = null;
    notifyListeners();
  }

  /// Limpa o erro atual
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sincroniza com retry em caso de falha
  Future<void> _syncWithRetry(Future<bool> Function() syncFunction) async {
    const maxRetries = 2;
    const retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('Tentativa de sincronização $attempt/$maxRetries');

      try {
        final success = await syncFunction().timeout(uploadTimeout);
        if (success) {
          debugPrint('Sincronização bem-sucedida na tentativa $attempt');
          return;
        }
      } catch (e) {
        debugPrint('Erro na tentativa $attempt: $e');

        if (attempt == maxRetries) {
          debugPrint('Máximo de tentativas atingido');
        } else {
          await Future.delayed(retryDelay);
        }
      }
    }
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
