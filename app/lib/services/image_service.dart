import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

/// Serviço para gerenciamento de imagens
/// - Seleção de imagens da câmera ou galeria
/// - Compressão local de imagens
/// - Upload para Cloudinary com validações de segurança
class ImageService {
  final ImagePicker _picker = ImagePicker();

  // Limites de segurança para upload
  static const int maxImageWidth = 1080;
  static const int maxImageHeight = 1920;
  static const int maxImageWidthHD = 1920;
  static const int maxImageHeightHD = 2560;
  static const int imageQuality = 85;
  static const int minImageQuality = 70;

  // Limites de tamanho de arquivo (25MB)
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25MB
  static const int maxFileSizeKb = maxFileSizeBytes ~/ 1024; // 25MB em KB

  // Tipos de arquivo permitidos
  static const List<String> allowedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.webp', '.heic'
  ];

  // MIME types permitidos
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
  ];

  /// Inicializa o serviço
  static Future<void> initialize() async {
    // Configuração está carregada via CloudinaryConfig
  }

  /// Retorna o nome da nuvem do Cloudinary
  String get _cloudName => CloudinaryConfig.cloudName;

  /// Retorna o preset de upload do Cloudinary
  String get _uploadPreset => CloudinaryConfig.uploadPreset;

  /// Verifica se o Cloudinary está configurado
  bool get isCloudinaryConfigured => CloudinaryConfig.isConfigured;

  /// Valida se a extensão do arquivo é permitida
  bool _isAllowedExtension(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    return allowedImageExtensions.contains(extension);
  }

  /// Extrai a extensão do arquivo
  String _getFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex >= 0 ? fileName.substring(dotIndex) : '';
  }

  /// Valida se o arquivo está dentro dos limites de tamanho
  bool _isFileSizeValid(File file) {
    try {
      final fileSize = file.lengthSync();
      if (fileSize > maxFileSizeBytes) {
        debugPrint('Tamanho de arquivo excedido: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB');
        return false;
      }
      if (fileSize < 1024) {
        debugPrint('Arquivo muito pequeno: ${fileSize}B (possivelmente corrompido)');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao verificar tamanho do arquivo: $e');
      return false;
    }
  }

  /// Sanitiza o nome do arquivo para evitar ataques de path traversal
  String _sanitizeFileName(String fileName) {
    // Remove caminhos relativos (../, ./)
    final sanitized = fileName
        .replaceAll(RegExp(r'\.\./'), '')
        .replaceAll(RegExp(r'\.\./'), '')
        .replaceAll(RegExp(r'^[/\\]'), '');

    // Remove caracteres perigosos do nome de arquivo
    final dangerousChars = RegExp(r'[\x00-\x1f\x7f-\x9f]', multiLine: true);
    final withoutDangerous = sanitized.replaceAll(dangerousChars, '');

    // Limita tamanho do nome
    final maxLength = 255;
    return withoutDangerous.length > maxLength
        ? withoutDangerous.substring(0, maxLength)
        : withoutDangerous;
  }

  /// Valida se a URL do Cloudinary é segura
  bool _isValidCloudinaryUrl(String? url) {
    if (url == null || url!.isEmpty) return false;

    try {
      final uri = Uri.parse(url!);

      // Verifica se é HTTPS
      if (uri.scheme != 'https') {
        debugPrint('URL não usa HTTPS: ${uri.scheme}');
        return false;
      }

      // Verifica se é do domínio correto do Cloudinary
      if (!uri.host.contains('cloudinary.com')) {
        debugPrint('URL não é do Cloudinary: ${uri.host}');
        return false;
      }

      // Verifica se não há caracteres suspeitosos na URL
      final suspiciousPatterns = [
        RegExp(r'<script[^>]*>'),
        RegExp(r'javascript:', caseSensitive: false),
        RegExp(r'on\w*\s*='),
        RegExp(r'data:', caseSensitive: false),
      ];

      for (final pattern in suspiciousPatterns) {
        if (pattern.hasMatch(url!)) {
          debugPrint('URL contém padrão suspeito: ${pattern.pattern}');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao validar URL: $e');
      return false;
    }
  }

  /// Seleciona uma imagem da câmera ou galeria com validações
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: maxImageWidth.toDouble(),
        maxHeight: maxImageHeight.toDouble(),
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);

      // Validação 1: Tamanho do arquivo
      if (!await _isFileSizeValid(file)) {
        throw Exception(
          'Arquivo muito grande ou muito pequeno. '
          'Máximo permitido: ${maxFileSizeKb}KB',
        );
      }

      // Validação 2: Extensão do arquivo
      if (!_isAllowedExtension(file.path)) {
        throw Exception(
          'Formato de arquivo não suportado. '
          'Use: JPG, JPEG, PNG, WEBP, HEIC',
        );
      }

      // Sanitização: Log do nome do arquivo para segurança
      final originalName = file.path.split('/').last;
      final sanitizedName = _sanitizeFileName(originalName);
      debugPrint('Arquivo selecionado: $originalName -> $sanitizedName');

      return file;
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Comprime uma imagem para reduzir tamanho
  Future<File> compressImage(File image) async {
    try {
      // Validação pré-compressão: verifica se o arquivo é válido
      if (!await _isFileSizeValid(image)) {
        throw Exception('Arquivo inválido ou muito grande');
      }

      // Obtém diretório temporário
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = '${tempDir.path}/compressed_$timestamp.jpg';

      debugPrint('Comprimindo imagem: ${image.path} -> $targetPath');

      // Comprime a imagem
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        quality: imageQuality,
        minWidth: maxImageWidth,
        minHeight: maxImageHeight,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        throw Exception('Falha ao comprimir imagem');
      }

      // Valida o arquivo comprimido
      final compressedSize = await File(compressedFile!.path).length();
      debugPrint('Tamanho original: ${await image.length()} bytes');
      debugPrint('Tamanho comprimido: $compressedSize bytes');
      debugPrint('Taxa de compressão: ${((1 - compressedSize / await image.length()) * 100).toStringAsFixed(1)}%');

      // Verifica se a compressão reduziu o tamanho
      if (compressedSize >= await image.length()) {
        debugPrint('Aviso: Imagem não foi comprimida efetivamente');
      }

      return File(compressedFile.path);
    } catch (e) {
      throw Exception('Erro ao comprimir imagem: $e');
    }
  }

  /// Faz upload de uma imagem para o Cloudinary com validações de segurança
  /// Retorna a URL pública da imagem ou null em caso de erro
  Future<String?> uploadToCloudinary(File image) async {
    // Validação 1: Cloudinary configurado
    if (!isCloudinaryConfigured) {
      throw Exception(
        'Cloudinary não configurado. Verifique o arquivo cloudinary_config.dart.',
      );
    }

    // Validação 2: Arquivo existe
    if (!await image.exists()) {
      throw Exception('Arquivo não encontrado');
    }

    // Validação 3: Tamanho do arquivo
    if (!await _isFileSizeValid(image)) {
      throw Exception('Arquivo muito grande. Máximo: ${maxFileSizeKb}KB');
    }

    debugPrint('Iniciando upload para Cloudinary...');

    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      debugPrint('Status do upload: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = _parseCloudinaryResponse(responseData);

        // Validação 4: Verifica se a resposta contém URL
        if (jsonResponse == null) {
          debugPrint('Erro: Resposta inválida do Cloudinary');
          debugPrint('Resposta bruta: $responseData');
          return null;
        }

        // Validação 5: URL retornada é segura
        final secureUrl = jsonResponse['secure_url']?.toString() ?? jsonResponse['url']?.toString();

        if (!_isValidCloudinaryUrl(secureUrl)) {
          debugPrint('Erro: URL do Cloudinary não é segura');
          return null;
        }

        debugPrint('Upload bem-sucedido: $secureUrl');

        // Validação 6: URL não está vazia
        if (secureUrl == null || secureUrl.isEmpty) {
          debugPrint('Erro: URL vazia retornada');
          return null;
        }

        return secureUrl;
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint('Erro no upload: Status ${response.statusCode}');
        debugPrint('Corpo do erro: $errorBody');
        throw Exception(
          'Erro no upload: Status ${response.statusCode}. $errorBody',
        );
      }
    } catch (e) {
      debugPrint('Erro ao fazer upload para Cloudinary: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Erro ao fazer upload para Cloudinary: $e');
    }
  }

  /// Processa a resposta JSON do Cloudinary com validações
  Map<String, dynamic>? _parseCloudinaryResponse(String responseBody) {
    try {
      // Remove caracteres inválidos que podem estar no JSON
      final cleanedBody = responseBody.trim();
      if (cleanedBody.isEmpty) {
        debugPrint('Erro: Resposta vazia do Cloudinary');
        return null;
      }

      // Validação: Tamanho máximo da resposta para evitar DoS
      if (cleanedBody.length > 100000) {
        debugPrint('Aviso: Resposta muito grande, possivel ataque DoS');
        return null;
      }

      // Parse JSON manualmente para evitar dependências adicionais
      final Map<String, dynamic> result = {};

      // Procura por secure_url e url na resposta
      final secureUrlRegex = RegExp(r'"secure_url"\s*:\s*"([^"]+)"');
      final urlRegex = RegExp(r'"url"\s*:\s*"([^"]+)"');
      final publicIdRegex = RegExp(r'"public_id"\s*:\s*"([^"]+)"');

      final secureUrlMatch = secureUrlRegex.firstMatch(cleanedBody);
      final urlMatch = urlRegex.firstMatch(cleanedBody);
      final publicIdMatch = publicIdRegex.firstMatch(cleanedBody);

      // Valida se encontrou pelo menos uma URL
      if (secureUrlMatch == null && urlMatch == null) {
        debugPrint('Erro: Nenhuma URL encontrada na resposta');
        return null;
      }

      if (secureUrlMatch != null) {
        final url = secureUrlMatch.group(1);
        if (url != null && _hasDangerousPatterns(url)) {
          debugPrint('Erro: URL contém padrões perigosos');
          return null;
        }
        result['secure_url'] = url ?? '';
      }

      if (urlMatch != null) {
        final url = urlMatch.group(1);
        if (url != null && _hasDangerousPatterns(url)) {
          debugPrint('Erro: URL contém padrões perigosos');
          return null;
        }
        result['url'] = url ?? '';
      }

      if (publicIdMatch != null) {
        final publicId = publicIdMatch.group(1);
        if (publicId != null && _hasDangerousPatterns(publicId)) {
          debugPrint('Erro: public_id contém padrões perigosos');
          return null;
        }
        result['public_id'] = publicId ?? '';
      }

      return result.isNotEmpty ? result : null;
    } catch (e) {
      debugPrint('Erro ao parsear resposta JSON: $e');
      return null;
    }
  }

  /// Verifica se uma string contém padrões perigosos (XSS, SQL injection, etc)
  bool _hasDangerousPatterns(String input) {
    final dangerousPatterns = [
      // Scripts
      RegExp(r'<script[^>]*>'),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w*\s*=', caseSensitive: false),

      // SQL Injection básicos
      RegExp(r"[';]--", caseSensitive: false),
      RegExp(r"[';]drop", caseSensitive: false),
      RegExp(r"[';]insert", caseSensitive: false),
      RegExp(r"[';]union", caseSensitive: false),

      // Path traversal
      RegExp(r'\.\.'),
      RegExp(r'\.\./'),

      // HTML entities
      RegExp(r'&lt;'),
      RegExp(r'&gt;'),
      RegExp(r'&amp;'),
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Gera URL de thumbnail para Cloudinary
  String getThumbnailUrl(String imageUrl, {int width = 200, int height = 200}) {
    if (imageUrl.isEmpty) return imageUrl;

    try {
      final uri = Uri.parse(imageUrl);

      // Validação: URL é segura antes de gerar thumbnail
      if (!_isValidCloudinaryUrl(imageUrl)) {
        debugPrint('Aviso: URL não é segura para gerar thumbnail');
        return imageUrl;
      }

      if (uri.host.contains('cloudinary.com')) {
        final pathParts = uri.pathSegments;
        // Busca pela versão (v1234567890)
        final versionIndex = pathParts.indexWhere((s) => s.startsWith('v'));
        if (versionIndex >= 0 && versionIndex < pathParts.length - 1) {
          final publicId = pathParts.sublist(versionIndex + 1).join('/');
          return 'https://res.cloudinary.com/${uri.host.split('.')[0]}/image/upload/c_fill,w_$width,h_$height/$publicId';
        }
      }
    } catch (e) {
      // Retorna a URL original em caso de erro
      debugPrint('Erro ao gerar thumbnail: $e');
    }

    return imageUrl;
  }

  /// Deleta uma imagem do Cloudinary (requere API key com permissões de delete)
  /// Nota: Esta funcionalidade requer um preset assinado com permissões de deleção
  Future<bool> deleteFromCloudinary(String publicId) async {
    // Esta função requer autenticação completa com API key e secret
    // Para simplificar, estamos usando apenas upload unsigned
    // A deleção deve ser feita através do painel do Cloudinary ou API externa
    throw UnimplementedError(
      'Deleção direta do Cloudinary requer autenticação completa. '
      'Use o painel do Cloudinary para deletar imagens.',
    );
  }

  /// Sincroniza as URLs de imagens com a planilha Google Sheets via Google Apps Script
  /// Valida todas as URLs antes de enviar
  Future<bool> syncToGoogleSheets(String siteId, List<String> imageUrls) async {
    final scriptUrl = CloudinaryConfig.googleAppsScriptUrl;

    // Validação 1: Script configurado
    if (!CloudinaryConfig.isScriptConfigured) {
      debugPrint('Google Apps Script não configurado. URL atual: $scriptUrl');
      return false;
    }

    // Validação 2: Site ID não está vazio
    if (siteId.trim().isEmpty) {
      debugPrint('Erro: site_id vazio');
      return false;
    }

    // Validação 3: Sanitiza o site ID
    final sanitizedSiteId = _sanitizeSiteId(siteId);
    if (sanitizedSiteId != siteId) {
      debugPrint('Site ID sanitizado: $siteId -> $sanitizedSiteId');
    }

    // Validação 4: Número máximo de imagens
    if (imageUrls.length > 5) {
      debugPrint('Erro: Máximo de 5 imagens excedido');
      return false;
    }

    // Validação 5: Sanitiza e valida cada URL antes de enviar
    final sanitizedUrls = <String>[];
    for (final url in imageUrls) {
      if (url.isEmpty) {
        sanitizedUrls.add(url);
        continue;
      }

      if (!_isValidCloudinaryUrl(url)) {
        debugPrint('Erro: URL inválida encontrada: $url');
        return false;
      }

      sanitizedUrls.add(url);
    }

    debugPrint('Sincronizando com Google Apps Script...');
    debugPrint('Site ID: $sanitizedSiteId');
    debugPrint('URL do Script: $scriptUrl');
    debugPrint('Imagens para enviar: $sanitizedUrls');

    try {
      final uri = Uri.parse(scriptUrl);

      // Validação 6: URL do script é HTTPS
      if (uri.scheme != 'https') {
        debugPrint('Aviso: URL do script não usa HTTPS');
        return false;
      }

      final requestBody = jsonEncode({
        'site_id': sanitizedSiteId,
        'imageUrls': sanitizedUrls,
      });

      debugPrint('Body da requisição (sanitizado): $requestBody');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      debugPrint('Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          final success = responseData['success'] ?? false;
          debugPrint('Sucesso da sincronização: $success');

          if (!success) {
            debugPrint('Erro ao sincronizar: ${responseData['message']}');
          }

          return success;
        } catch (jsonError) {
          debugPrint('Erro ao decodificar JSON: $jsonError');
          debugPrint('Response body raw: ${response.body}');
          return false;
        }
      } else {
        debugPrint('Erro ao sincronizar: Status ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao chamar Google Apps Script: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Sanitiza o site_id para evitar injeções
  String _sanitizeSiteId(String siteId) {
    // Remove caracteres especiais e espaços extras
    return siteId
        .trim()
        .replaceAll(RegExp(r'[<>;"\\\\]'), '')
        .substring(0, siteId.length > 50 ? 50 : siteId.length);
  }
}
