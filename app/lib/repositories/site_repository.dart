import '../models/site.dart';
import '../services/data_service.dart';

/// Repositório de Sites
/// Pode carregar dados do Google Sheets ou usar dados mock local
class SiteRepository {
  final List<Site> _sites = [];
  final DataService _dataService = DataService();

  SiteRepository() {
    // Dados mock são carregados apenas como fallback
    _loadMockData();
  }

  /// Carrega dados mock para testes (usado como fallback)
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
        status: 'Ativo',
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
        status: 'Ativo',
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
        status: 'Desativado',
      ),
      Site(
        siteId: 'SLZ003',
        sigla: 'MASLS9',
        nome: 'São Luís Bacanga',
        endereco: 'Av. dos Franceses, Bacanga, São Luís - MA',
        municipio: 'São Luís',
        latitude: -2.5550,
        longitude: -44.2650,
        detentora: 'AMX',
        uc: '98765432',
        tecnologias: ['4G', '5G'],
        status: 'Ativo',
      ),
      Site(
        siteId: 'SJO015',
        sigla: 'MASJO2',
        nome: 'São José de Ribamar Centro',
        endereco: 'Rua da Matriz, Centro, São José de Ribamar - MA',
        municipio: 'São José de Ribamar',
        latitude: -2.5400,
        longitude: -44.2650,
        detentora: 'ATC',
        uc: '13579246',
        tecnologias: ['4G'],
        status: 'Ativo',
      ),
    ]);
  }

  /// Carrega sites do Google Sheets
  /// Retorna a lista de sites carregados ou null se falhar
  Future<List<Site>?> loadFromGoogleSheets({String? planilhaId}) async {
    try {
      final sites = await _dataService.fetchSites();
      if (sites.isNotEmpty) {
        _sites.clear();
        _sites.addAll(sites);
        return sites;
      }
      return null;
    } catch (e) {
      // Em caso de erro, retorna null (mantém os dados mock)
      return null;
    }
  }

  /// Verifica se a URL do Google Sheets está configurada
  bool isGoogleSheetsConfigured() {
    return _dataService.isUrlConfigured();
  }

  /// Retorna todos os sites
  List<Site> getAllSites() => List.unmodifiable(_sites);

  /// Retorna lista de municípios únicos
  List<String> getMunicipios() {
    final municipios = _sites.map((s) => s.municipio).toSet().toList();
    municipios.sort();
    return municipios;
  }

  /// Busca sites por termo (pesquisa inteligente)
  /// Busca em: Site ID, Nome, Município
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

  /// Filtra sites por município
  List<Site> filterByMunicipio(String municipio) {
    if (municipio.isEmpty) return getAllSites();
    return _sites.where((s) => s.municipio == municipio).toList();
  }

  /// Busca site por ID
  Site? getSiteById(String siteId) {
    try {
      return _sites.firstWhere((s) => s.siteId == siteId);
    } catch (_) {
      return null;
    }
  }

  /// Filtra por tecnologia
  List<Site> filterByTecnologia(String tecnologia) {
    return _sites.where((s) => s.hasTecnologia(tecnologia)).toList();
  }
}
