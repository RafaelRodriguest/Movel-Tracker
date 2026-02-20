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
  final bool ativo;

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
    this.ativo = true,
  });

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
    );
  }

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
    };
  }

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

  bool hasTecnologia(String tecnologia) {
    return tecnologias.any((t) => t.toUpperCase() == tecnologia.toUpperCase());
  }

  String get coordenadasFormatadas => '$latitude, $longitude';

  String get googleMapsNavigationUrl =>
      'google.navigation:q=$latitude,$longitude';

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
