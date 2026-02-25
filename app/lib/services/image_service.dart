import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

/// Serviço para gerenciamento de imagens
/// - Seleção de imagens da câmera ou galeria
/// - Compressão local de imagens
/// - Upload para Cloudinary
class ImageService {
  final ImagePicker _picker = ImagePicker();

  static const int maxImageWidth = 1080;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 80;

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

  /// Seleciona uma imagem da câmera ou galeria
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: maxImageWidth.toDouble(),
        maxHeight: maxImageHeight.toDouble(),
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: $e');
    }
  }

  /// Comprime uma imagem para reduzir tamanho
  Future<File> compressImage(File image) async {
    try {
      // Obtém diretório temporário
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

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

      return File(compressedFile.path);
    } catch (e) {
      throw Exception('Erro ao comprimir imagem: $e');
    }
  }

  /// Faz upload de uma imagem para o Cloudinary
  /// Retorna a URL pública da imagem ou null em caso de erro
  Future<String?> uploadToCloudinary(File image) async {
    if (!isCloudinaryConfigured) {
      throw Exception(
        'Cloudinary não configurado. Verifique o arquivo .env com CLOUDINARY_CLOUD_NAME e CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = _parseCloudinaryResponse(responseData);

        if (jsonResponse != null && jsonResponse['secure_url'] != null) {
          return jsonResponse['secure_url'].toString();
        }

        if (jsonResponse != null && jsonResponse['url'] != null) {
          return jsonResponse['url'].toString();
        }

        return null;
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
          'Erro no upload: Status ${response.statusCode}. $errorBody',
        );
      }
    } catch (e) {
      throw Exception('Erro ao fazer upload para Cloudinary: $e');
    }
  }

  /// Processa a resposta JSON do Cloudinary
  Map<String, dynamic>? _parseCloudinaryResponse(String responseBody) {
    try {
      // Remove caracteres inválidos que podem estar no JSON
      final cleanedBody = responseBody.trim();
      if (cleanedBody.isEmpty) return null;

      // Parse JSON manualmente para evitar dependências adicionais
      final Map<String, dynamic> result = {};

      // Procura por secure_url e url na resposta
      final secureUrlRegex = RegExp(r'"secure_url"\s*:\s*"([^"]+)"');
      final urlRegex = RegExp(r'"url"\s*:\s*"([^"]+)"');
      final publicIdRegex = RegExp(r'"public_id"\s*:\s*"([^"]+)"');

      final secureUrlMatch = secureUrlRegex.firstMatch(cleanedBody);
      final urlMatch = urlRegex.firstMatch(cleanedBody);
      final publicIdMatch = publicIdRegex.firstMatch(cleanedBody);

      if (secureUrlMatch != null) {
        result['secure_url'] = secureUrlMatch.group(1);
      }
      if (urlMatch != null) {
        result['url'] = urlMatch.group(1);
      }
      if (publicIdMatch != null) {
        result['public_id'] = publicIdMatch.group(1);
      }

      return result.isNotEmpty ? result : null;
    } catch (e) {
      return null;
    }
  }

  /// Gera URL de thumbnail para Cloudinary
  String getThumbnailUrl(String imageUrl, {int width = 200, int height = 200}) {
    if (imageUrl.isEmpty) return imageUrl;

    try {
      final uri = Uri.parse(imageUrl);
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
  /// Isso garante que alterações feitas por um técnico sejam visíveis a todos
  Future<bool> syncToGoogleSheets(String siteId, List<String> imageUrls) async {
    final scriptUrl = CloudinaryConfig.googleAppsScriptUrl;

    if (!CloudinaryConfig.isScriptConfigured) {
      print('Google Apps Script não configurado. URL atual: $scriptUrl');
      return false;
    }

    print('Sincronizando com Google Apps Script...');
    print('Site ID: $siteId');
    print('URL do Script: $scriptUrl');
    print('Imagens para enviar: $imageUrls');

    try {
      final uri = Uri.parse(scriptUrl);
      print('URI parseado: $uri');

      final requestBody = jsonEncode({
        'site_id': siteId,
        'imageUrls': imageUrls,
      });
      print('Body da requisição: $requestBody');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      print('Status Code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          final success = responseData['success'] ?? false;
          print('Sucesso: $success');
          if (!success) {
            print('Erro ao sincronizar: ${responseData['message']}');
          }
          return success;
        } catch (jsonError) {
          print('Erro ao decodificar JSON: $jsonError');
          print('Response body raw: ${response.body}');
          return false;
        }
      } else {
        print('Erro ao sincronizar: Status ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao chamar Google Apps Script: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
}
