import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:movel_tracker/models/site.dart';
import 'package:movel_tracker/repositories/site_repository.dart';

// O repositório instancia SupabaseService no construtor, que por sua vez lê
// Supabase.instance — sem initialize o construtor lança. A URL aponta para uma
// porta fechada de propósito: todo fetch falha de imediato, exercitando os
// caminhos de fallback (cache → mock) sem depender de rede.
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
  String sigla = '',
}) =>
    Site(
      siteId: siteId,
      sigla: sigla,
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

/// Semeia o cache v2 de um estado com timestamp atual (cache hit garantido).
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _initSupabaseFake();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ─── Mock por estado ─────────────────────────────────────────────────────────

  group('SiteRepository — mock por estado', () {
    test('MA tem sites de exemplo cadastrados', () {
      final sites = SiteRepository().loadMockData('MA');
      expect(sites, isNotEmpty);
      expect(sites.length, 5);
    });

    test('todo site mock do MA carrega uf MA', () {
      final sites = SiteRepository().loadMockData('MA');
      expect(sites.every((s) => s.uf == 'MA'), isTrue);
    });

    test('estados sem mock cadastrado retornam lista vazia, não erro', () {
      final repo = SiteRepository();
      for (final uf in ['PA', 'AM', 'RR', 'AP']) {
        expect(repo.loadMockData(uf), isEmpty, reason: 'uf $uf');
      }
    });

    test('UF desconhecida retorna lista vazia', () {
      expect(SiteRepository().loadMockData('ZZ'), isEmpty);
    });

    test('loadMockData troca o conteúdo em vez de acumular', () {
      final repo = SiteRepository();
      repo.loadMockData('MA');
      expect(repo.getAllSites(), hasLength(5));
      repo.loadMockData('PA');
      expect(repo.getAllSites(), isEmpty);
    });

    test('getAllSites devolve lista não modificável', () {
      final sites = SiteRepository().loadMockData('MA');
      expect(() => sites.add(_site(siteId: 'X', uf: 'MA')),
          throwsUnsupportedError);
    });
  });

  // ─── Carga: cache × Supabase × mock ──────────────────────────────────────────

  group('SiteRepository — loadFromSupabase', () {
    test('cache válido curto-circuita o Supabase', () async {
      await _semearCache('PA', [
        _site(siteId: 'BEL001', uf: 'PA', nome: 'Belém Centro'),
        _site(siteId: 'BEL002', uf: 'PA', nome: 'Belém Norte'),
      ]);

      // Supabase inalcançável — só o cache pode responder aqui
      final sites = await SiteRepository().loadFromSupabase('PA');

      expect(sites, isNotNull);
      expect(sites!.map((s) => s.siteId), ['BEL001', 'BEL002']);
    });

    test('cache hit popula o estado interno do repositório', () async {
      await _semearCache('AM', [_site(siteId: 'MAO001', uf: 'AM')]);

      final repo = SiteRepository();
      await repo.loadFromSupabase('AM');

      expect(repo.getAllSites(), hasLength(1));
      expect(repo.getSiteById('MAO001'), isNotNull);
    });

    test('cache de outro estado não é usado (sem vazamento entre UFs)', () async {
      await _semearCache('MA', [_site(siteId: 'SLZ001', uf: 'MA')]);

      // Pede PA: o cache do MA existe, mas não serve — e o Supabase está morto
      expect(await SiteRepository().loadFromSupabase('PA'), isNull);
    });

    test('sem cache e sem rede retorna null (provider cai no mock)', () async {
      expect(await SiteRepository().loadFromSupabase('MA'), isNull);
    });

    test('clearCache invalida só o estado informado', () async {
      await _semearCache('MA', [_site(siteId: 'SLZ001', uf: 'MA')]);
      await _semearCache('PA', [_site(siteId: 'BEL001', uf: 'PA')]);

      final repo = SiteRepository();
      await repo.clearCache('MA');

      expect(await repo.loadFromSupabase('MA'), isNull);
      expect(await repo.loadFromSupabase('PA'), isNotNull);
    });
  });

  // ─── Busca ───────────────────────────────────────────────────────────────────

  group('SiteRepository — searchSites', () {
    late SiteRepository repo;

    setUp(() async {
      await _semearCache('MA', [
        _site(
            siteId: 'SLZ001',
            uf: 'MA',
            sigla: 'MASLS7',
            nome: 'São Luís Centro',
            municipio: 'São Luís',
            tecnico: 'João Silva'),
        _site(
            siteId: 'ITZ045',
            uf: 'MA',
            sigla: 'MAITZ2',
            nome: 'Imperatriz Matriz',
            municipio: 'Imperatriz',
            tecnico: 'Maria Santos'),
        _site(
            siteId: 'CXS012',
            uf: 'MA',
            sigla: 'MACXS4',
            nome: 'Caxias Norte',
            municipio: 'Caxias',
            tecnico: 'Pedro Costa'),
      ]);
      repo = SiteRepository();
      await repo.loadFromSupabase('MA');
    });

    test('query vazia devolve todos os sites', () {
      expect(repo.searchSites(''), hasLength(3));
    });

    test('busca por site_id', () {
      expect(repo.searchSites('ITZ045').single.siteId, 'ITZ045');
    });

    test('busca por sigla', () {
      expect(repo.searchSites('MACXS4').single.siteId, 'CXS012');
    });

    test('busca por nome', () {
      expect(repo.searchSites('Matriz').single.siteId, 'ITZ045');
    });

    test('busca por município', () {
      expect(repo.searchSites('Caxias').single.siteId, 'CXS012');
    });

    test('busca por técnico', () {
      expect(repo.searchSites('Maria').single.siteId, 'ITZ045');
    });

    test('busca ignora caixa', () {
      expect(repo.searchSites('sÃo LuÍs'), hasLength(1));
    });

    test('busca ignora acentos na query', () {
      expect(repo.searchSites('sao luis').single.siteId, 'SLZ001');
    });

    test('busca ignora espaços nas bordas', () {
      expect(repo.searchSites('  Caxias  ').single.siteId, 'CXS012');
    });

    test('termo sem correspondência devolve lista vazia', () {
      expect(repo.searchSites('Manaus'), isEmpty);
    });

    test('busca parcial casa por substring', () {
      expect(repo.searchSites('SLZ'), hasLength(1));
    });
  });

  // ─── Municípios e filtro ─────────────────────────────────────────────────────

  group('SiteRepository — municípios e filtro', () {
    late SiteRepository repo;

    setUp(() async {
      await _semearCache('MA', [
        _site(siteId: 'A', uf: 'MA', municipio: 'São Luís'),
        _site(siteId: 'B', uf: 'MA', municipio: 'Imperatriz'),
        _site(siteId: 'C', uf: 'MA', municipio: 'São Luís'),
        _site(siteId: 'D', uf: 'MA', municipio: 'Caxias'),
      ]);
      repo = SiteRepository();
      await repo.loadFromSupabase('MA');
    });

    test('getMunicipios remove duplicados', () {
      expect(repo.getMunicipios(), hasLength(3));
    });

    test('getMunicipios vem ordenado alfabeticamente', () {
      expect(repo.getMunicipios(), ['Caxias', 'Imperatriz', 'São Luís']);
    });

    test('filterByMunicipio devolve só os sites do município', () {
      expect(repo.filterByMunicipio('São Luís').map((s) => s.siteId),
          containsAll(['A', 'C']));
    });

    test('filterByMunicipio com "Todos" devolve tudo', () {
      expect(repo.filterByMunicipio('Todos'), hasLength(4));
    });

    test('filterByMunicipio com string vazia devolve tudo', () {
      expect(repo.filterByMunicipio(''), hasLength(4));
    });

    test('filterByMunicipio ignora acentos e caixa', () {
      expect(repo.filterByMunicipio('sao luis'), hasLength(2));
    });

    test('filterByMunicipio exige nome completo (não faz substring)', () {
      expect(repo.filterByMunicipio('São'), isEmpty);
    });

    test('município inexistente devolve lista vazia', () {
      expect(repo.filterByMunicipio('Manaus'), isEmpty);
    });
  });

  // ─── getSiteById ─────────────────────────────────────────────────────────────

  group('SiteRepository — getSiteById', () {
    test('encontra o site carregado', () {
      final repo = SiteRepository();
      repo.loadMockData('MA');
      expect(repo.getSiteById('SLZ001')?.nome, 'São Luís Centro');
    });

    test('retorna null para id inexistente em vez de lançar', () {
      final repo = SiteRepository();
      repo.loadMockData('MA');
      expect(repo.getSiteById('NAO_EXISTE'), isNull);
    });

    test('retorna null quando nada foi carregado', () {
      expect(SiteRepository().getSiteById('SLZ001'), isNull);
    });
  });
}
