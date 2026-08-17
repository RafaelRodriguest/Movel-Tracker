/// Modelo de dados representando um Site da Claro (torre)
class Site {
  final String siteId;
  final String sigla;
  final String nome;
  final String endereco;
  final String municipio;
  /// Sigla do estado (UF) — 'MA' | 'PA' | 'AM' | 'RR' | 'AP'. Escopa os dados por estado.
  final String uf;
  final String tecnico;
  final double latitude;
  final double longitude;
  final String detentora;
  final String uc;
  final String status;
  final List<String?> imageUrls;

  // Campos operacionais — chaves
  final String? chavePortao;
  final String? chaveGradil01;
  final String? chaveGradil02;

  // Campos operacionais — fontes e consumo
  final String? fonte01;
  final String? fonte02;
  final String? consumoFonte01;
  final String? consumoFonte02;

  // Campos operacionais — baterias
  final String? bateriasFonte01;
  final String? bateriasFonte02;

  Site({
    required this.siteId,
    required this.sigla,
    required this.nome,
    required this.endereco,
    required this.municipio,
    required this.uf,
    required this.tecnico,
    required this.latitude,
    required this.longitude,
    required this.detentora,
    required this.uc,
    this.status = 'Ativo',
    List<String?>? imageUrls,
    this.chavePortao,
    this.chaveGradil01,
    this.chaveGradil02,
    this.fonte01,
    this.fonte02,
    this.consumoFonte01,
    this.consumoFonte02,
    this.bateriasFonte01,
    this.bateriasFonte02,
  }) : imageUrls = imageUrls ?? List.filled(5, null);

  /// Cria um Site a partir de um mapa (JSON/CSV)
  factory Site.fromJson(Map<String, dynamic> json) {
    final statusValue = json['status']?.toString();
    final finalStatus = (statusValue == null || statusValue.isEmpty) ? 'Ativo' : statusValue;

    return Site(
      siteId: json['site_id'] ?? '',
      sigla: json['sigla'] ?? '',
      nome: json['nome'] ?? '',
      endereco: json['endereco'] ?? '',
      municipio: json['municipio'] ?? '',
      // Tolerante a linhas antigas (pré-coluna uf) e a cache v1 sem o campo
      uf: json['uf']?.toString().toUpperCase() ?? '',
      tecnico: json['tecnico'] ?? '',
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
      detentora: json['detentora'] ?? '',
      uc: json['uc']?.toString() ?? '',
      status: finalStatus,
      imageUrls: [
        json['foto_1'] as String?,
        json['foto_2'] as String?,
        json['foto_3'] as String?,
        json['foto_4'] as String?,
        json['foto_5'] as String?,
      ],
      chavePortao: json['chave_portao'] as String?,
      chaveGradil01: json['chave_gradil_01'] as String?,
      chaveGradil02: json['chave_gradil_02'] as String?,
      fonte01: json['fonte_01'] as String?,
      fonte02: json['fonte_02'] as String?,
      consumoFonte01: json['consumo_fonte_01'] as String?,
      consumoFonte02: json['consumo_fonte_02'] as String?,
      bateriasFonte01: json['baterias_fonte_01'] as String?,
      bateriasFonte02: json['baterias_fonte_02'] as String?,
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
      'uf': uf,
      'tecnico': tecnico,
      'latitude': latitude,
      'longitude': longitude,
      'detentora': detentora,
      'uc': uc,
      'status': status,
      'foto_1': imageUrls.length > 0 ? imageUrls[0] : null,
      'foto_2': imageUrls.length > 1 ? imageUrls[1] : null,
      'foto_3': imageUrls.length > 2 ? imageUrls[2] : null,
      'foto_4': imageUrls.length > 3 ? imageUrls[3] : null,
      'foto_5': imageUrls.length > 4 ? imageUrls[4] : null,
      'chave_portao': chavePortao,
      'chave_gradil_01': chaveGradil01,
      'chave_gradil_02': chaveGradil02,
      'fonte_01': fonte01,
      'fonte_02': fonte02,
      'consumo_fonte_01': consumoFonte01,
      'consumo_fonte_02': consumoFonte02,
      'baterias_fonte_01': bateriasFonte01,
      'baterias_fonte_02': bateriasFonte02,
    };
  }

  // Sentinel: distingue "parâmetro não informado" de "null intencional" no copyWith
  static const _omit = Object();

  Site copyWith({
    List<String?>? imageUrls,
    Object? chavePortao = _omit,
    Object? chaveGradil01 = _omit,
    Object? chaveGradil02 = _omit,
    Object? fonte01 = _omit,
    Object? fonte02 = _omit,
    Object? consumoFonte01 = _omit,
    Object? consumoFonte02 = _omit,
    Object? bateriasFonte01 = _omit,
    Object? bateriasFonte02 = _omit,
  }) {
    return Site(
      siteId: siteId,
      sigla: sigla,
      nome: nome,
      endereco: endereco,
      municipio: municipio,
      uf: uf,
      tecnico: tecnico,
      latitude: latitude,
      longitude: longitude,
      detentora: detentora,
      uc: uc,
      status: status,
      imageUrls: imageUrls ?? this.imageUrls,
      chavePortao:     chavePortao     == _omit ? this.chavePortao     : chavePortao     as String?,
      chaveGradil01:   chaveGradil01   == _omit ? this.chaveGradil01   : chaveGradil01   as String?,
      chaveGradil02:   chaveGradil02   == _omit ? this.chaveGradil02   : chaveGradil02   as String?,
      fonte01:         fonte01         == _omit ? this.fonte01         : fonte01         as String?,
      fonte02:         fonte02         == _omit ? this.fonte02         : fonte02         as String?,
      consumoFonte01:  consumoFonte01  == _omit ? this.consumoFonte01  : consumoFonte01  as String?,
      consumoFonte02:  consumoFonte02  == _omit ? this.consumoFonte02  : consumoFonte02  as String?,
      bateriasFonte01: bateriasFonte01 == _omit ? this.bateriasFonte01 : bateriasFonte01 as String?,
      bateriasFonte02: bateriasFonte02 == _omit ? this.bateriasFonte02 : bateriasFonte02 as String?,
    );
  }

  /// Retorna true se o site estiver ativo
  bool get ativo {
    final s = status.trim().toLowerCase();
    return s.isEmpty || s == 'ativo' || s == 'active' || s == 'enabled';
  }

  /// Parser de coordenadas — aceita double (Supabase) ou String com vírgula/ponto (CSV)
  static double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final normalized = value.toString().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  /// Formata coordenadas para exibição
  String get coordenadasFormatadas => '$latitude, $longitude';

  /// Verifica se as coordenadas são válidas
  bool get hasValidCoordinates => latitude != 0.0 || longitude != 0.0;

  String get latStr => latitude.toStringAsFixed(6);
  String get lngStr => longitude.toStringAsFixed(6);

  /// Intent do Google Maps para navegação turn-by-turn
  String get googleMapsNavIntent =>
      'google.navigation:q=$latStr,$lngStr&mode=d';

  /// URL de navegação para Google Maps (fallback web)
  String get googleMapsNavigationUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$latStr,$lngStr&navigate=yes';

  /// URL de visualização do mapa
  String get googleMapsViewUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latStr,$lngStr';

  @override
  String toString() => 'Site(siteId: $siteId, nome: $nome, municipio: $municipio)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Site && runtimeType == other.runtimeType && siteId == other.siteId;

  @override
  int get hashCode => siteId.hashCode;
}
