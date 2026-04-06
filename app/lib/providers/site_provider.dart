import 'package:flutter/foundation.dart';
import '../models/site.dart';
import '../repositories/site_repository.dart';

/// Provider para gerenciar o estado dos Sites
/// Gerencia lista de sites, busca e filtros
class SiteProvider with ChangeNotifier {
  final SiteRepository _repository = SiteRepository();

  // Estado
  List<Site> _allSites = [];
  List<Site> _filteredSites = [];
  String _searchQuery = '';
  String _selectedMunicipio = 'Todos';
  bool _isLoading = false;

  // Getters
  List<Site> get filteredSites => _filteredSites;
  List<Site> get allSites => _allSites;
  String get searchQuery => _searchQuery;
  String get selectedMunicipio => _selectedMunicipio;
  bool get isLoading => _isLoading;

  // Lista de municípios disponíveis (com opção "Todos")
  List<String> get municipios => ['Todos', ..._repository.getMunicipios()];

  // Contagem de sites encontrados
  int get siteCount => _filteredSites.length;

  SiteProvider() {
    _loadSites();
  }

  /// Carrega os sites inicialmente
  Future<void> _loadSites() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tenta carregar do Supabase
      final sheetsSites = await _repository.loadFromSupabase();

      if (sheetsSites != null && sheetsSites.isNotEmpty) {
        _allSites = sheetsSites;
      } else {
        // Fallback para dados mock locais
        _allSites = _repository.getAllSites();
      }
    } catch (e) {
      // Em caso de erro, usa dados mock
      _allSites = _repository.getAllSites();
    }

    _filteredSites = List.from(_allSites);
    _isLoading = false;
    notifyListeners();
  }

  /// Atualiza a busca com o texto informado
  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Atualiza o filtro de município
  void updateMunicipioFilter(String municipio) {
    _selectedMunicipio = municipio;
    _applyFilters();
    notifyListeners();
  }

  /// Limpa todos os filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedMunicipio = 'Todos';
    _filteredSites = List.from(_allSites);
    notifyListeners();
  }

  /// Normaliza o texto removendo acentos e cedilha para busca
  String _normalizeText(String text) {
    // Mapeamento de caracteres acentuados para equivalentes sem acento
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

  /// Aplica filtros de busca e município
  void _applyFilters() {
    List<Site> result = _allSites;

    // Filtro por município — usa _allSites para refletir estado mais recente (ex: fotos atualizadas)
    if (_selectedMunicipio != 'Todos') {
      result = _allSites.where((s) => s.municipio == _selectedMunicipio).toList();
    }

    // Filtro por busca de texto (case-insensitive e acent-insensitive)
    if (_searchQuery.isNotEmpty) {
      final normalizedQuery = _normalizeText(_searchQuery);
      result = result.where((site) {
        return _normalizeText(site.siteId).contains(normalizedQuery) ||
               _normalizeText(site.sigla).contains(normalizedQuery) ||
               _normalizeText(site.nome).contains(normalizedQuery) ||
               _normalizeText(site.municipio).contains(normalizedQuery) ||
               _normalizeText(site.tecnico).contains(normalizedQuery);
      }).toList();
    }

    _filteredSites = result;
  }

  /// Atualiza as URLs de foto de um site no estado local
  void updateSiteImageUrls(String siteId, List<String?> urls) {
    final index = _allSites.indexWhere((s) => s.siteId == siteId);
    if (index == -1) return;
    _allSites[index] = _allSites[index].copyWith(imageUrls: urls);
    _applyFilters();
    notifyListeners();
  }

  /// Retorna um site específico por ID
  Site? getSiteById(String siteId) {
    return _repository.getSiteById(siteId);
  }

  /// Recarrega os dados
  Future<void> refresh() async {
    await _loadSites();
  }
}
