import '../models/site.dart';
import '../services/supabase_service.dart';

/// Repositório de Sites
/// Carrega dados do Supabase ou usa dados mock local como fallback
class SiteRepository {
  final List<Site> _sites = [];
  final SupabaseService _supabaseService = SupabaseService();

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
        tecnico: 'João Silva',
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
        tecnico: 'Maria Santos',
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
        tecnico: 'Pedro Costa',
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
        tecnico: 'Ana Oliveira',
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
        tecnico: 'Carlos Lima',
        latitude: -2.5400,
        longitude: -44.2650,
        detentora: 'ATC',
        uc: '13579246',
        tecnologias: ['4G'],
        status: 'Ativo',
      ),
    ]);
  }

  /// Carrega sites do Supabase
  /// Retorna a lista de sites carregados ou null se falhar
  Future<List<Site>?> loadFromSupabase() async {
    try {
      final sites = await _supabaseService.fetchSites();
      if (sites.isNotEmpty) {
        _sites.clear();
        _sites.addAll(sites);
        return sites;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Retorna todos os sites
  List<Site> getAllSites() => List.unmodifiable(_sites);

  /// Retorna lista de municípios únicos
  List<String> getMunicipios() {
    final municipios = _sites.map((s) => s.municipio).toSet().toList();
    municipios.sort();
    return municipios;
  }

  /// Busca sites por termo (pesquisa inteligente com normalização de acentos)
  /// Busca em: Site ID, Nome, Município, Técnico
  List<Site> searchSites(String query) {
    if (query.isEmpty) return getAllSites();

    final normalizedQuery = _normalizeText(query);

    return _sites.where((site) {
      return _normalizeText(site.siteId).contains(normalizedQuery) ||
             _normalizeText(site.sigla).contains(normalizedQuery) ||
             _normalizeText(site.nome).contains(normalizedQuery) ||
             _normalizeText(site.municipio).contains(normalizedQuery) ||
             _normalizeText(site.tecnico).contains(normalizedQuery);
    }).toList();
  }

  /// Normaliza o texto removendo acentos e cedilha para busca
  String _normalizeText(String text) {
    final accents = {
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O', 'Ø': 'O',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'Ç': 'C',
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
      'Ñ': 'N', 'ñ': 'n',
      'Ý': 'Y', 'ý': 'y', 'ÿ': 'y',
    };

    String result = text;
    accents.forEach((accent, normal) {
      result = result.replaceAll(accent, normal);
    });
    return result.toLowerCase().trim();
  }

  /// Filtra sites por município
  List<Site> filterByMunicipio(String municipio) {
    if (municipio.isEmpty || municipio == 'Todos') return getAllSites();
    return _sites.where((s) => _normalizeText(s.municipio) == _normalizeText(municipio)).toList();
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
