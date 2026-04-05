/// Modelo de dados representando um Site da Claro (torre)
class Site {
  final String siteId;
  final String sigla;
  final String nome;
  final String endereco;
  final String municipio;
  final String tecnico;
  final double latitude;
  final double longitude;
  final String detentora;
  final String uc;
  final List<String> tecnologias;
  final String status;
  final List<String?> imageUrls;

  Site({
    required this.siteId,
    required this.sigla,
    required this.nome,
    required this.endereco,
    required this.municipio,
    required this.tecnico,
    required this.latitude,
    required this.longitude,
    required this.detentora,
    required this.uc,
    required this.tecnologias,
    this.status = 'Ativo',
    List<String?>? imageUrls,
  }) : imageUrls = imageUrls ?? List.filled(5, null);

  /// Cria um Site a partir de um mapa (JSON/CSV)
  factory Site.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status']?.toString();
    // Se status for null ou vazio, assume 'Ativo' como padrão
    final finalStatus = (statusValue == null || statusValue.isEmpty) ? 'Ativo' : statusValue;

    return Site(
      siteId: json['site_id'] ?? '',
      sigla: json['sigla'] ?? '',
      nome: json['nome'] ?? '',
      endereco: json['endereco'] ?? '',
      municipio: json['municipio'] ?? '',
      tecnico: json['tecnico'] ?? '',
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
      detentora: json['detentora'] ?? '',
      uc: json['uc']?.toString() ?? '',
      tecnologias: _parseTecnologias(json['tecnologias']?.toString()),
      status: finalStatus,
      imageUrls: [
        json['foto_1'] as String?,
        json['foto_2'] as String?,
        json['foto_3'] as String?,
        json['foto_4'] as String?,
        json['foto_5'] as String?,
      ],
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
      'tecnico': tecnico,
      'latitude': latitude,
      'longitude': longitude,
      'detentora': detentora,
      'uc': uc,
      'tecnologias': tecnologias.join(','),
      'status': status,
      'foto_1': imageUrls.length > 0 ? imageUrls[0] : null,
      'foto_2': imageUrls.length > 1 ? imageUrls[1] : null,
      'foto_3': imageUrls.length > 2 ? imageUrls[2] : null,
      'foto_4': imageUrls.length > 3 ? imageUrls[3] : null,
      'foto_5': imageUrls.length > 4 ? imageUrls[4] : null,
    };
  }

  Site copyWith({List<String?>? imageUrls}) {
    return Site(
      siteId: siteId,
      sigla: sigla,
      nome: nome,
      endereco: endereco,
      municipio: municipio,
      tecnico: tecnico,
      latitude: latitude,
      longitude: longitude,
      detentora: detentora,
      uc: uc,
      tecnologias: tecnologias,
      status: status,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  /// Retorna true se o site estiver ativo (para compatibilidade)
  bool get ativo {
    final s = status.trim().toLowerCase();
    return s.isEmpty || s == 'ativo' || s == 'active' || s == 'enabled';
  }

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

  /// Parser de coordenadas — aceita double (Supabase) ou String com vírgula/ponto (CSV)
  static double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final normalized = value.toString().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
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
