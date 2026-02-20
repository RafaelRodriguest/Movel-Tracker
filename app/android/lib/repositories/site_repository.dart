import '../models/site.dart';

class SiteRepository {
  final List<Site> _sites = [];

  SiteRepository() {
    _loadMockData();
  }

  void _loadMockData() {
    _sites.addAll([
      Site(
        siteId: 'SLZ001',
        sigla: 'MASLS7',
        nome: 'São Luís Centro',
        endereco: 'Av. Dom Pedro II, Centro, São Luís - MA',
        municipio: 'São Luís',
        latitude: -2.5297,
        longitude: -44.3028,
        detentora: 'ATC',
        uc: '12345678',
        tecnologias: ['4G', '5G', 'IOT'],
        ativo: true,
      ),
      Site(
        siteId: 'ITZ045',
        sigla: 'MAITZ2',
        nome: 'Imperatriz Matriz',
        endereco: 'Av. Getúlio Vargas, Centro, Imperatriz - MA',
        municipio: 'Imperatriz',
        latitude: -5.5200,
        longitude: -47.4833,
        detentora: 'ATC',
        uc: '87654321',
        tecnologias: ['4G'],
        ativo: true,
      ),
      Site(
        siteId: 'CXS012',
        sigla: 'MACXS4',
        nome: 'Caxias Norte',
        endereco: 'Rua Monsenhor Soares, Centro, Caxias - MA',
        municipio: 'Caxias',
        latitude: -4.8500,
        longitude: -43.3500,
        detentora: 'ATC',
        uc: '54321678',
        tecnologias: ['4G', '5G'],
        ativo: false,
      ),
    ]);
  }

  List<Site> getAllSites() => List.unmodifiable(_sites);

  List<String> getMunicipios() {
    final municipios = _sites.map((s) => s.municipio).toSet().toList();
    municipios.sort();
    return municipios;
  }

  List<Site> searchSites(String query) {
    if (query.isEmpty) return getAllSites();

    final lowerQuery = query.toLowerCase();

    return _sites.where((site) {
      return site.siteId.toLowerCase().contains(lowerQuery) ||
             site.sigla.toLowerCase().contains(lowerQuery) ||
             site.nome.toLowerCase().contains(lowerQuery) ||
             site.municipio.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Site> filterByMunicipio(String municipio) {
    if (municipio.isEmpty) return getAllSites();
    return _sites.where((s) => s.municipio == municipio).toList();
  }

  Site? getSiteById(String siteId) {
    try {
      return _sites.firstWhere((s) => s.siteId == siteId);
    } catch (_) {
      return null;
    }
  }

  List<Site> filterByTecnologia(String tecnologia) {
    return _sites.where((s) => s.hasTecnologia(tecnologia)).toList();
  }
}
