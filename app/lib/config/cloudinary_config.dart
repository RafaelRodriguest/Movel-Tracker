import 'package:flutter/foundation.dart';

/// Configuração do Cloudinary
/// Substitua com suas credenciais
class CloudinaryConfig {
  /// Nome da nuvem do Cloudinary
  /// Encontrado em: https://cloudinary.com/console -> Settings -> Cloud name
  static const String cloudName = 'dz9mdzht8';

  /// Preset de upload unsigned (sem API key)
  /// Criado em: https://cloudinary.com/console -> Settings -> Upload -> Upload presets
  static const String uploadPreset = 'movel_tracker_preset';

  /// URL do Google Apps Script para escrita na planilha
  /// Substitua após implantar o script em https://script.google.com/
  /// A URL será algo como: https://script.google.com/macros/s/XXXXXXXXXXXXXXXX/exec
  static const String googleAppsScriptUrl = 'https://script.google.com/macros/s/AKfycbzzedQ-R9YFp7hjBP19xOw0DPwPSgyMYLlE_NTYnFDRx7Vxak3VtMoCtCshczF2M0cyKg/exec';

  /// Verifica se o Cloudinary está configurado
  static bool get isConfigured => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  /// Verifica se o Cloudinary está configurado corretamente
  static bool get isCloudinaryConfigured {
    if (cloudName.isEmpty) {
      debugPrint('Aviso: Cloud name vazio');
      return false;
    }

    if (uploadPreset.isEmpty) {
      debugPrint('Aviso: Upload preset vazio');
      return false;
    }

    // Valida se o cloud name não é o placeholder
    if (_isPlaceholder(cloudName)) {
      debugPrint('Aviso: Cloud name não configurado (usando placeholder)');
      return false;
    }

    return true;
  }

  /// Verifica se o script está configurado e é válido
  static bool get isScriptConfigured {
    if (googleAppsScriptUrl.isEmpty) {
      debugPrint('Aviso: Script URL vazia');
      return false;
    }

    if (!_isValidScriptUrl(googleAppsScriptUrl)) {
      debugPrint('Aviso: Script URL inválida');
      return false;
    }

    return true;
  }

  /// Verifica se uma string é um placeholder
  static bool _isPlaceholder(String value) {
    final placeholders = [
      'SEU_CLOUD_NAME',
      'SEU_UPLOAD_PRESET',
      'SUBSTITUA',
      'YOUR_',
      'XXXXXX',
      'seu_nome',
    ];

    final lowerValue = value.toLowerCase();
    for (final placeholder in placeholders) {
      if (lowerValue.contains(placeholder.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// Valida se a URL do Google Apps Script é válida
  static bool _isValidScriptUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Valida 1: Deve ser HTTPS
      if (uri.scheme != 'https') {
        debugPrint('Erro: Script URL não usa HTTPS: ${uri.scheme}');
        return false;
      }

      // Valida 2: Deve ser do domínio script.google.com ou apps.googleusercontent.com
      final allowedHosts = [
        'script.google.com',
        'script.googleusercontent.com',
        'apps.googleusercontent.com',
      ];

      if (!allowedHosts.contains(uri.host)) {
        debugPrint('Erro: Script URL de domínio não permitido: ${uri.host}');
        return false;
      }

      // Valida 3: Deve conter /macros/s/ ou /exec
      final path = uri.path.toLowerCase();
      if (!path.contains('/macros/') && !path.contains('/exec')) {
        debugPrint('Aviso: Script URL pode estar incorreta: $path');
      }

      // Valida 4: Não conter placeholders óbvios
      if (_isPlaceholder(url)) {
        debugPrint('Erro: Script URL contém placeholder');
        return false;
      }

      // Valida 5: Tamanho razoável da URL (evitar DoS)
      if (url.length > 500) {
        debugPrint('Erro: Script URL muito longa');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao validar URL do script: $e');
      return false;
    }
  }

  /// Valida todas as configurações antes do uso
  static String? validateConfiguration() {
    final issues = <String>[];

    // Valida Cloudinary
    if (!isCloudinaryConfigured) {
      issues.add('Cloudinary não configurado (cloudName ou uploadPreset vazios)');
    }

    // Valida Google Apps Script
    if (!isScriptConfigured) {
      issues.add('Google Apps Script não configurado');
    }

    if (!_isValidScriptUrl(googleAppsScriptUrl)) {
      issues.add('URL do Google Apps Script inválida');
    }

    if (issues.isNotEmpty) {
      final message = 'Erros de configuração:\n' + issues.map((e) => '• $e').join('\n');
      debugPrint(message);
      return message;
    }

    debugPrint('Configuração válida');
    return null;
  }

  /// URL base do Cloudinary (para uso interno)
  static String get cloudinaryBaseUrl => 'https://api.cloudinary.com/v1_1/$cloudName';

  /// URL base do Google Apps Script (para uso interno)
  static String get scriptBaseUrl => googleAppsScriptUrl.split('/macros/')[0];
}
