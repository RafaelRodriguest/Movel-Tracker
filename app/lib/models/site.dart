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
  final String status;
  final List<String> imageUrls;

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
    this.status = 'Ativo',
    this.imageUrls = const [],
  });

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
      latitude: _parseCoordinate(json['latitude']?.toString()),
      longitude: _parseCoordinate(json['longitude']?.toString()),
      detentora: json['detentora'] ?? '',
      uc: json['uc']?.toString() ?? '',
      status: finalStatus,
      imageUrls: _parseImageUrls(
        json['foto_1'], json['foto_2'], json['foto_3'], json['foto_4'], json['foto_5'],
      ),
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
      'status': status,
      'foto_1': imageUrls.isNotEmpty ? imageUrls[0] : '',
      'foto_2': imageUrls.length > 1 ? imageUrls[1] : '',
      'foto_3': imageUrls.length > 2 ? imageUrls[2] : '',
      'foto_4': imageUrls.length > 3 ? imageUrls[3] : '',
      'foto_5': imageUrls.length > 4 ? imageUrls[4] : '',
    };
  }

  /// Retorna true se o site estiver ativo (para compatibilidade)
  bool get ativo {
    final s = status.trim().toLowerCase();
    return s.isEmpty || s == 'ativo' || s == 'active' || s == 'enabled';
  }

  /// Parser de coordenadas que aceita vírgula ou ponto como separador decimal
  static double _parseCoordinate(String? value) {
    if (value == null || value.isEmpty) {
      return 0.0;
    }
    // Substitui vírgula por ponto para parsing correto (formato brasileiro)
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  /// Formata coordenadas para exibição
  String get coordenadasFormatadas => '$latitude, $longitude';

  /// Gera URL de navegação para Google Maps (usando esquema geo universal)
  String get googleMapsNavigationUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&navigate=yes';

  /// Gera URL de visualização do mapa
  String get googleMapsViewUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  /// Parse das URLs de imagens das colunas foto_1 a foto_5
  static List<String> _parseImageUrls(
    dynamic f1, dynamic f2, dynamic f3, dynamic f4, dynamic f5,
  ) {
    return [f1, f2, f3, f4, f5]
        .where((url) => url != null && url.toString().trim().isNotEmpty)
        .map((url) => url.toString().trim())
        .toList();
  }

  /// Gera URL de thumbnail para Cloudinary (200x200)
  String getThumbnailUrl(String imageUrl, {int width = 200, int height = 200}) {
    if (imageUrl.isEmpty) return imageUrl;

    // Se for uma URL do Cloudinary, adiciona transformação de tamanho
    if (imageUrl.contains('cloudinary.com')) {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final versionIndex = segments.indexWhere((s) => s.startsWith('v'));
        if (versionIndex >= 0 && versionIndex < segments.length - 1) {
          final publicId = segments.sublist(versionIndex + 1).join('/');
          return 'https://res.cloudinary.com/${uri.host.split('.')[0]}/image/upload/c_fill,w_$width,h_$height/$publicId';
        }
      }
    }

    return imageUrl;
  }

  @override
  String toString() {
    return 'Site(siteId: $siteId, nome: $nome, municipio: $municipio)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Site &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          imageUrls.toString() == other.imageUrls.toString();

  @override
  int get hashCode => siteId.hashCode ^ imageUrls.hashCode;
}
