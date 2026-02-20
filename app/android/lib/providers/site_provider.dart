import 'package:flutter/foundation.dart';
import '../models/site.dart';
import '../repositories/site_repository.dart';

class SiteProvider with ChangeNotifier {
  final SiteRepository _repository = SiteRepository();

  List<Site> _allSites = [];
  List<Site> _filteredSites = [];
  String _searchQuery = '';
  String _selectedMunicipio = 'Todos';
  bool _isLoading = false;

  List<Site> get filteredSites => _filteredSites;
  List<Site> get allSites => _allSites;
  String get searchQuery => _searchQuery;
  String get selectedMunicipio => _selectedMunicipio;
  bool get isLoading => _isLoading;

  List<String> get municipios => ['Todos', ..._repository.getMunicipios()];
  int get siteCount => _filteredSites.length;

  SiteProvider() {
    _loadSites();
  }

  Future<void> _loadSites() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _allSites = _repository.getAllSites();
    _filteredSites = List.from(_allSites);
    _isLoading = false;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void updateMunicipioFilter(String municipio) {
    _selectedMunicipio = municipio;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedMunicipio = 'Todos';
    _filteredSites = List.from(_allSites);
    notifyListeners();
  }

  void _applyFilters() {
    List<Site> result = _allSites;

    if (_selectedMunicipio != 'Todos') {
      result = _repository.filterByMunicipio(_selectedMunicipio);
    }

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

  Site? getSiteById(String siteId) {
    return _repository.getSiteById(siteId);
  }

  Future<void> refresh() async {
    await _loadSites();
  }
}
