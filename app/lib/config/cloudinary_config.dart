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

  /// Verifica se o script está configurado
  static bool get isScriptConfigured =>
      googleAppsScriptUrl.isNotEmpty && !googleAppsScriptUrl.contains('SUBSTITUA');
}
