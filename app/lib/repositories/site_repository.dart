import '../models/site.dart';
import '../services/cache_service.dart';
import '../services/supabase_service.dart';

const _accents = <String, String>{
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

/// Repositório de Sites
/// Carrega dados do Supabase ou usa dados mock local como fallback
class SiteRepository {
  final List<Site> _sites = [];
  final SupabaseService _supabaseService = SupabaseService();
  final CacheService _cache = CacheService();

  /// Carrega os sites mock do estado em `_sites` (fallback quando cache e
  /// Supabase falham). Estados sem mock cadastrado ficam com lista vazia.
  List<Site> loadMockData(String uf) {
    _sites
      ..clear()
      ..addAll(_mockPorUf[uf] ?? const <Site>[]);
    return getAllSites();
  }

  /// Dados mock por estado — hoje só o Maranhão tem sites de exemplo.
  static final Map<String, List<Site>> _mockPorUf = {
    'MA': [
      Site(
        siteId: 'SLZ001',
        sigla: 'MASLS7',
        nome: 'São Luís Centro',
        endereco: 'Av. Dom Pedro II, Centro, São Luís - MA',
        municipio: 'São Luís',
        uf: 'MA',
        tecnico: 'João Silva',
        latitude: -2.5297,
        longitude: -44.3028,
        detentora: 'ATC',
        uc: '12345678',
        status: 'Ativo',
      ),
      Site(
        siteId: 'ITZ045',
        sigla: 'MAITZ2',
        nome: 'Imperatriz Matriz',
        endereco: 'Av. Getúlio Vargas, Centro, Imperatriz - MA',
        municipio: 'Imperatriz',
        uf: 'MA',
        tecnico: 'Maria Santos',
        latitude: -5.5200,
        longitude: -47.4833,
        detentora: 'ATC',
        uc: '87654321',
        status: 'Ativo',
      ),
      Site(
        siteId: 'CXS012',
        sigla: 'MACXS4',
        nome: 'Caxias Norte',
        endereco: 'Rua Monsenhor Soares, Centro, Caxias - MA',
        municipio: 'Caxias',
        uf: 'MA',
        tecnico: 'Pedro Costa',
        latitude: -4.8500,
        longitude: -43.3500,
        detentora: 'ATC',
        uc: '54321678',
        status: 'Desativado',
      ),
      Site(
        siteId: 'SLZ003',
        sigla: 'MASLS9',
        nome: 'São Luís Bacanga',
        endereco: 'Av. dos Franceses, Bacanga, São Luís - MA',
        municipio: 'São Luís',
        uf: 'MA',
        tecnico: 'Ana Oliveira',
        latitude: -2.5550,
        longitude: -44.2650,
        detentora: 'AMX',
        uc: '98765432',
        status: 'Ativo',
      ),
      Site(
        siteId: 'SJO015',
        sigla: 'MASJO2',
        nome: 'São José de Ribamar Centro',
        endereco: 'Rua da Matriz, Centro, São José de Ribamar - MA',
        municipio: 'São José de Ribamar',
        uf: 'MA',
        tecnico: 'Carlos Lima',
        latitude: -2.5400,
        longitude: -44.2650,
        detentora: 'ATC',
        uc: '13579246',
        status: 'Ativo',
      ),
    ],
  };

  /// Carrega sites do cache local ou do Supabase (cache miss/expirado).
  /// Retorna null se ambos falharem — SiteProvider faz fallback para mock.
  Future<List<Site>?> loadFromSupabase(String uf) async {
    // 1. Cache hit: retorna sem tocar no Supabase
    final cached = await _cache.loadSites(uf);
    if (cached != null) {
      _sites.clear();
      _sites.addAll(cached);
      return cached;
    }
    // 2. Cache miss: busca no Supabase e persiste para próxima abertura
    try {
      final sites = await _supabaseService.fetchSites(uf: uf);
      if (sites.isNotEmpty) {
        _sites.clear();
        _sites.addAll(sites);
        await _cache.saveSites(uf, sites);
        return sites;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Invalida o cache do estado — usado por refresh() e após escritas no Supabase.
  Future<void> clearCache(String uf) => _cache.clear(uf);

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

  String _normalizeText(String text) {
    String result = text;
    _accents.forEach((accent, normal) {
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
}
