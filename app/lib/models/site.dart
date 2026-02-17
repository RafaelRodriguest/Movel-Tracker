/// Modelo de dados representando um Site da Claro (torre)
class Site {
  final String siteId;
  final String sigla;
  final String nome;
  final String endereco;
  final String municipio;
  final double latitude;
  final double longitude;
  final String detentora;
  final String uc;
  final List<String> tecnologias;
  final String status;

  Site({
    required this.siteId,
    required this.sigla,
    required this.nome,
    required this.endereco,
    required this.municipio,
    required this.latitude,
    required this.longitude,
    required this.detentora,
    required this.uc,
    required this.tecnologias,
    this.status = 'Ativo',
  });

  /// Cria um Site a partir de um mapa (JSON/CSV)
  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      siteId: json['site_id'] ?? '',
      sigla: json['sigla'] ?? '',
      nome: json['nome'] ?? '',
      endereco: json['endereco'] ?? '',
      municipio: json['municipio'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      detentora: json['detentora'] ?? '',
      uc: json['uc']?.toString() ?? '',
      tecnologias: _parseTecnologias(json['tecnologias']?.toString()),
      status: json['status']?.toString() ?? 'Ativo',
    );
  }

  /// Converte Site para mapa (JSON)
  Map<String, dynamic> toJson() {
    return {
      'site_id': siteId,
      'sigla': sigla,
      'nome': nome,
      'endereco': endereco,
      'municipio': municipio,
      'latitude': latitude,
      'longitude': longitude,
      'detentora': detentora,
      'uc': uc,
      'tecnologias': tecnologias.join(','),
      'status': status,
    };
  }

  /// Retorna true se o site estiver ativo (para compatibilidade)
  bool get ativo => status.toLowerCase() == 'ativo';

  /// Parser de tecnologias (pode vir como string separada por vírgula)
  static List<String> _parseTecnologias(String? tecnologias) {
    if (tecnologias == null || tecnologias.isEmpty) {
      return [];
    }
    return tecnologias
        .split(',')
        .map((t) => t.trim().toUpperCase())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Verifica se possui determinada tecnologia
  bool hasTecnologia(String tecnologia) {
    return tecnologias.any((t) => t.toUpperCase() == tecnologia.toUpperCase());
  }

  /// Formata coordenadas para exibição
  String get coordenadasFormatadas => '$latitude, $longitude';

  /// Gera URL de navegação para Google Maps (usando esquema geo universal)
  String get googleMapsNavigationUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&navigate=yes';

  /// Gera URL de visualização do mapa
  String get googleMapsViewUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  @override
  String toString() {
    return 'Site(siteId: $siteId, nome: $nome, municipio: $municipio)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Site && runtimeType == other.runtimeType && siteId == other.siteId;

  @override
  int get hashCode => siteId.hashCode;
}
