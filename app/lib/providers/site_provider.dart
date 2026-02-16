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

    // Simula um delay para parecer que está carregando
    await Future.delayed(const Duration(milliseconds: 500));

    _allSites = _repository.getAllSites();
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

  /// Aplica filtros de busca e município
  void _applyFilters() {
    List<Site> result = _allSites;

    // Filtro por município
    if (_selectedMunicipio != 'Todos') {
      result = _repository.filterByMunicipio(_selectedMunicipio);
    }

    // Filtro por busca de texto
    if (_searchQuery.isNotEmpty) {
      result = result.where((site) {
        final lowerQuery = _searchQuery.toLowerCase();
        return site.siteId.toLowerCase().contains(lowerQuery) ||
               site.sigla.toLowerCase().contains(lowerQuery) ||
               site.nome.toLowerCase().contains(lowerQuery) ||
               site.municipio.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    _filteredSites = result;
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
