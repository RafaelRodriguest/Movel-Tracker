import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/env.dart';

class CloudinaryService {
  static const _baseUrl = 'https://api.cloudinary.com/v1_1';

  Future<String> upload(File imageFile) async {
    final uri = Uri.parse(
      '$_baseUrl/${Env.cloudinaryCloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = Env.cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Falha no upload: ${response.statusCode} $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  /// URL otimizada para exibição em thumbnail (slots de foto 96×96 px).
  static String thumbnailUrl(String url) =>
      _withTransform(url, 'w_200,h_200,c_fill,q_auto,f_auto');

  /// URL otimizada para visualização em tela cheia.
  static String fullViewUrl(String url) =>
      _withTransform(url, 'w_1200,q_auto,f_auto');

  static String _withTransform(String url, String transform) {
    const marker = '/upload/';
    final i = url.indexOf(marker);
    if (i == -1) return url;
    return '${url.substring(0, i + marker.length)}$transform/${url.substring(i + marker.length)}';
  }

  /// Extrai o public_id de uma URL do Cloudinary.
  /// Formato: https://res.cloudinary.com/{cloud}/image/upload/v{version}/{public_id}.{ext}
  /// Retorna null se a URL não for do Cloudinary ou estiver malformada.
  static String? extractPublicId(String? url) {
    if (url == null || url.isEmpty) return null;
    const uploadMarker = '/upload/';
    final uploadIndex = url.indexOf(uploadMarker);
    if (uploadIndex == -1) return null;
    var path = url.substring(uploadIndex + uploadMarker.length);
    // Remove transformation prefix (e.g. w_200,h_200,c_fill,q_auto,f_auto/)
    path = path.replaceFirst(RegExp(r'^[a-z]{1,3}_[^/]+(,[a-z]{1,3}_[^/]+)*/'), '');
    // Remove version prefix (v1234567890/)
    path = path.replaceFirst(RegExp(r'^v\d+/'), '');
    // Remove file extension
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex != -1) path = path.substring(0, dotIndex);
    return path.isEmpty ? null : path;
  }
}
