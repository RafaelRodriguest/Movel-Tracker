import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/models/site.dart';
import 'package:movel_tracker/providers/site_provider.dart';

// Supabase inalcançável de propósito (porta fechada): o fetch falha na hora e
// o provider exercita cache → mock, que é o que dá para testar sem rede.
Future<void> _initSupabaseFake() => Supabase.initialize(
      url: 'http://localhost:1/',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );

Site _site({
  required String siteId,
  required String uf,
  String nome = 'Site',
  String municipio = 'Município',
  String tecnico = '',
}) =>
    Site(
      siteId: siteId,
      sigla: '',
      nome: nome,
      endereco: '',
      municipio: municipio,
      uf: uf,
      tecnico: tecnico,
      latitude: -1.0,
      longitude: -2.0,
      detentora: '',
      uc: '',
    );

Future<void> _semearCache(String uf, List<Site> sites) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    'sites_cache_prod_${uf}_v3',
    jsonEncode(sites.map((s) => s.toJson()).toList()),
  );
  await prefs.setInt(
    'sites_cache_ts_prod_${uf}_v3',
    DateTime.now().millisecondsSinceEpoch,
  );
}

Future<bool> _cacheExiste(String uf) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  return prefs.getString('sites_cache_prod_${uf}_v3') != null;
}

/// Dá tempo para a invalidação de cache disparada em background (`.ignore()`).
Future<void> _drenarBackground() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

List<Site> _sitesMA() => [
      _site(siteId: 'SLZ001', uf: 'MA', nome: 'São Luís Centro', municipio: 'São Luís', tecnico: 'João Silva'),
      _site(siteId: 'ITZ045', uf: 'MA', nome: 'Imperatriz Matriz', municipio: 'Imperatriz', tecnico: 'Maria Santos'),
      _site(siteId: 'SLZ003', uf: 'MA', nome: 'São Luís Bacanga', municipio: 'São Luís', tecnico: 'Ana Oliveira'),
    ];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _initSupabaseFake();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ─── Estado inicial ──────────────────────────────────────────────────────────

  group('SiteProvider — estado inicial', () {
    test('não carrega nada antes da seleção de estado', () {
      final provider = SiteProvider();
      expect(provider.selectedUf, isNull);
      expect(provider.allSites, isEmpty);
      expect(provider.filteredSites, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.siteCount, 0);
    });

    test('filtros começam neutros', () {
      final provider = SiteProvider();
      expect(provider.searchQuery, '');
      expect(provider.selectedMunicipio, 'Todos');
    });
  });

  // ─── selectUf ────────────────────────────────────────────────────────────────

  group('SiteProvider — selectUf', () {
    test('carrega do cache do estado escolhido', () async {
      await _semearCache('PA', [_site(siteId: 'BEL001', uf: 'PA')]);

      final provider = SiteProvider();
      await provider.selectUf('PA');

      expect(provider.selectedUf, 'PA');
      expect(provider.allSites.single.siteId, 'BEL001');
      expect(provider.filteredSites, hasLength(1));
      expect(provider.isLoading, isFalse);
    });

    test('sem cache e sem rede cai no mock do estado', () async {
      final provider = SiteProvider();
      await provider.selectUf('MA');

      expect(provider.allSites, hasLength(5)); // mock do MA
      expect(provider.allSites.every((s) => s.uf == 'MA'), isTrue);
    });

    test('estado sem mock e sem cache termina vazio, sem erro', () async {
      final provider = SiteProvider();
      await provider.selectUf('RR');

      expect(provider.selectedUf, 'RR');
      expect(provider.allSites, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('trocar de estado substitui a lista', () async {
      await _semearCache('MA', _sitesMA());
      await _semearCache('AM', [_site(siteId: 'MAO001', uf: 'AM')]);

      final provider = SiteProvider();
      await provider.selectUf('MA');
      expect(provider.allSites, hasLength(3));

      await provider.selectUf('AM');
      expect(provider.allSites.single.siteId, 'MAO001');
      expect(provider.selectedUf, 'AM');
    });

    test('trocar de estado limpa busca e filtro de município', () async {
      await _semearCache('MA', _sitesMA());
      await _semearCache('AM', [_site(siteId: 'MAO001', uf: 'AM')]);

      final provider = SiteProvider();
      await provider.selectUf('MA');
      provider.updateSearch('Imperatriz');
      provider.updateMunicipioFilter('Imperatriz');

      await provider.selectUf('AM');

      expect(provider.searchQuery, '');
      expect(provider.selectedMunicipio, 'Todos');
      expect(provider.filteredSites, hasLength(1));
    });

    test('reselecionar o mesmo estado limpa filtros sem recarregar', () async {
      await _semearCache('MA', _sitesMA());

      final provider = SiteProvider();
      await provider.selectUf('MA');
      provider.updateSearch('Bacanga');
      expect(provider.filteredSites, hasLength(1));

      // Cache apagado: se houvesse refetch, a lista viraria mock ou vazio
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sites_cache_prod_MA_v3');

      await provider.selectUf('MA');

      expect(provider.allSites, hasLength(3));
      expect(provider.searchQuery, '');
      expect(provider.filteredSites, hasLength(3));
    });

    test('notifica listeners ao carregar', () async {
      await _semearCache('MA', _sitesMA());

      final provider = SiteProvider();
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      await provider.selectUf('MA');

      expect(notificacoes, greaterThan(0));
    });
  });

  // ─── Busca e filtros ─────────────────────────────────────────────────────────

  group('SiteProvider — busca e filtros', () {
    late SiteProvider provider;

    setUp(() async {
      await _semearCache('MA', _sitesMA());
      provider = SiteProvider();
      await provider.selectUf('MA');
    });

    test('municipios inclui "Todos" na frente', () {
      expect(provider.municipios.first, 'Todos');
      expect(provider.municipios, ['Todos', 'Imperatriz', 'São Luís']);
    });

    test('updateSearch filtra por nome', () {
      provider.updateSearch('Bacanga');
      expect(provider.filteredSites.single.siteId, 'SLZ003');
      expect(provider.siteCount, 1);
    });

    test('updateSearch é insensível a acento e caixa', () {
      provider.updateSearch('sao luis');
      expect(provider.filteredSites, hasLength(2));
    });

    test('updateSearch casa por técnico', () {
      provider.updateSearch('Ana');
      expect(provider.filteredSites.single.siteId, 'SLZ003');
    });

    test('updateMunicipioFilter restringe ao município', () {
      provider.updateMunicipioFilter('São Luís');
      expect(provider.filteredSites, hasLength(2));
    });

    test('busca e filtro de município se combinam', () {
      provider.updateMunicipioFilter('São Luís');
      provider.updateSearch('Bacanga');
      expect(provider.filteredSites.single.siteId, 'SLZ003');
    });

    test('combinação sem interseção devolve vazio', () {
      provider.updateMunicipioFilter('Imperatriz');
      provider.updateSearch('Bacanga');
      expect(provider.filteredSites, isEmpty);
    });

    test('clearFilters restaura a lista completa', () {
      provider.updateMunicipioFilter('Imperatriz');
      provider.updateSearch('Matriz');
      provider.clearFilters();

      expect(provider.searchQuery, '');
      expect(provider.selectedMunicipio, 'Todos');
      expect(provider.filteredSites, hasLength(3));
    });

    test('busca vazia volta a exibir tudo', () {
      provider.updateSearch('Bacanga');
      provider.updateSearch('');
      expect(provider.filteredSites, hasLength(3));
    });
  });

  // ─── Atualizações locais ─────────────────────────────────────────────────────

  group('SiteProvider — atualizações locais', () {
    late SiteProvider provider;

    setUp(() async {
      await _semearCache('MA', _sitesMA());
      provider = SiteProvider();
      await provider.selectUf('MA');
    });

    test('updateSiteImageUrls reflete no site em memória', () async {
      provider.updateSiteImageUrls('SLZ001', [
        'https://res.cloudinary.com/demo/foto1.jpg',
        null,
        null,
        null,
        null,
      ]);

      final site = provider.allSites.firstWhere((s) => s.siteId == 'SLZ001');
      expect(site.imageUrls[0], contains('foto1.jpg'));
      expect(site.imageUrls.length, 5);
    });

    test('updateSiteImageUrls invalida o cache do estado', () async {
      expect(await _cacheExiste('MA'), isTrue);

      provider.updateSiteImageUrls('SLZ001', List.filled(5, null));
      await _drenarBackground();

      expect(await _cacheExiste('MA'), isFalse);
    });

    test('updateSiteFields troca os campos operacionais em memória', () {
      final original = provider.allSites.firstWhere((s) => s.siteId == 'ITZ045');
      provider.updateSiteFields(
        'ITZ045',
        original.copyWith(fonte01: 'VERTIV', bateriasFonte01: '4'),
      );

      final site = provider.allSites.firstWhere((s) => s.siteId == 'ITZ045');
      expect(site.fonte01, 'VERTIV');
      expect(site.bateriasFonte01, '4');
    });

    test('updateSiteFields invalida o cache do estado', () async {
      final original = provider.allSites.first;
      provider.updateSiteFields('SLZ001', original.copyWith(fonte01: 'EMERSON'));
      await _drenarBackground();

      expect(await _cacheExiste('MA'), isFalse);
    });

    test('update em site inexistente é no-op', () {
      provider.updateSiteImageUrls('NAO_EXISTE', List.filled(5, null));
      expect(provider.allSites, hasLength(3));
    });

    test('update preserva o filtro ativo', () {
      provider.updateMunicipioFilter('São Luís');
      expect(provider.filteredSites, hasLength(2));

      provider.updateSiteImageUrls('SLZ001', List.filled(5, null));

      expect(provider.filteredSites, hasLength(2));
      expect(provider.selectedMunicipio, 'São Luís');
    });

    test('update notifica listeners', () {
      var notificacoes = 0;
      provider.addListener(() => notificacoes++);

      provider.updateSiteImageUrls('SLZ001', List.filled(5, null));

      expect(notificacoes, 1);
    });

    // Comportamento documentado em CLAUDE.md: getSiteById delega ao repositório,
    // que não vê as atualizações feitas via updateSiteFields. Para o estado vivo
    // use allSites. O teste existe para flagrar se isso mudar.
    test('getSiteById NÃO reflete updateSiteFields (usar allSites)', () {
      final original = provider.allSites.firstWhere((s) => s.siteId == 'SLZ001');
      provider.updateSiteFields('SLZ001', original.copyWith(fonte01: 'VERTIV'));

      expect(provider.getSiteById('SLZ001')?.fonte01, isNull);
      expect(
        provider.allSites.firstWhere((s) => s.siteId == 'SLZ001').fonte01,
        'VERTIV',
      );
    });
  });

  // ─── refresh ─────────────────────────────────────────────────────────────────

  group('SiteProvider — refresh', () {
    test('refresh sem estado selecionado é no-op', () async {
      final provider = SiteProvider();
      await provider.refresh();
      expect(provider.allSites, isEmpty);
    });

    test('refresh ignora o cache e recarrega (cai no mock sem rede)', () async {
      await _semearCache('MA', _sitesMA());

      final provider = SiteProvider();
      await provider.selectUf('MA');
      expect(provider.allSites, hasLength(3)); // veio do cache

      await provider.refresh();

      // Cache descartado + Supabase inalcançável → mock do MA
      expect(provider.allSites, hasLength(5));
      expect(await _cacheExiste('MA'), isFalse);
    });

    test('refresh preserva a UF selecionada', () async {
      await _semearCache('PA', [_site(siteId: 'BEL001', uf: 'PA')]);

      final provider = SiteProvider();
      await provider.selectUf('PA');
      await provider.refresh();

      expect(provider.selectedUf, 'PA');
    });
  });
}
