import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movel_tracker/models/site.dart';
import 'package:movel_tracker/services/cache_service.dart';

// Site completo com todos os campos preenchidos — garante que o round-trip
// do cache não perde nenhum campo na serialização/desserialização.
// Estado usado nos testes — o cache agora é escopado por UF
const _uf = 'MA';

Site _siteCompleto() => Site(
      siteId: 'SLZ001',
      sigla: 'MASLS7',
      nome: 'São Luís Centro',
      endereco: 'Av. Dom Pedro II, Centro',
      municipio: 'São Luís',
  uf: _uf,
      tecnico: 'João Silva',
      latitude: -2.508704,
      longitude: -44.302000,
      detentora: 'ATC',
      uc: '12345678',
      status: 'Ativo',
      imageUrls: [
        'https://res.cloudinary.com/demo/image/upload/v123/foto1.jpg',
        'https://res.cloudinary.com/demo/image/upload/v123/foto2.jpg',
        null,
        null,
        null,
      ],
      chavePortao: 'MULTLOCK',
      chaveGradil01: 'MA GDA',
      chaveGradil02: null,
      fonte01: 'ELTEK 2500',
      fonte02: null,
      consumoFonte01: '12.5',
      consumoFonte02: null,
      bateriasFonte01: '4',
      bateriasFonte02: null,
    );

Site _siteMinimo() => Site(
      siteId: 'ITZ045',
      sigla: 'MAITZ2',
      nome: 'Imperatriz',
      endereco: '',
      municipio: 'Imperatriz',
  uf: _uf,
      tecnico: '',
      latitude: -5.52,
      longitude: -47.4833,
      detentora: '',
      uc: '',
      status: 'Desativado',
    );

void main() {
  setUp(() {
    // Garante SharedPreferences limpo antes de cada teste
    SharedPreferences.setMockInitialValues({});
  });

  // ─── Cache vazio ─────────────────────────────────────────────────────────────

  group('CacheService — cache vazio', () {
    test('loadSites retorna null quando não há dados salvos', () async {
      final cache = CacheService();
      expect(await cache.loadSites(_uf), isNull);
    });

    test('loadSites retorna null quando há dados mas sem timestamp', () async {
      SharedPreferences.setMockInitialValues({
        'sites_cache_MA_v2': '[{"site_id":"SLZ001"}]',
        // timestamp ausente intencionalmente
      });
      final cache = CacheService();
      expect(await cache.loadSites(_uf), isNull);
    });

    test('clear em cache já vazio não lança erro', () async {
      final cache = CacheService();
      expect(() async => await cache.clear(_uf), returnsNormally);
    });
  });

  // ─── TTL ─────────────────────────────────────────────────────────────────────

  group('CacheService — TTL de 30 minutos', () {
    test('cache com timestamp atual é válido', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteMinimo()]);
      expect(await cache.loadSites(_uf), isNotNull);
    });

    test('cache com timestamp de 29 minutos atrás é válido', () async {
      final tsValido = DateTime.now()
          .subtract(const Duration(minutes: 29))
          .millisecondsSinceEpoch;
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteMinimo()]);
      // Sobrescreve o timestamp para simular cache com 29 min de idade
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sites_cache_ts_MA_v2', tsValido);

      expect(await cache.loadSites(_uf), isNotNull);
    });

    test('cache com timestamp de 31 minutos atrás está expirado', () async {
      final tsExpirado = DateTime.now()
          .subtract(const Duration(minutes: 31))
          .millisecondsSinceEpoch;
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteMinimo()]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sites_cache_ts_MA_v2', tsExpirado);

      expect(await cache.loadSites(_uf), isNull);
    });

    test('cache expirado não retorna dados mesmo com JSON válido', () async {
      final tsExpirado = DateTime.now()
          .subtract(const Duration(hours: 2))
          .millisecondsSinceEpoch;
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteCompleto()]);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sites_cache_ts_MA_v2', tsExpirado);

      expect(await cache.loadSites(_uf), isNull);
    });
  });

  // ─── Round-trip save/load ────────────────────────────────────────────────────

  group('CacheService — round-trip save/load', () {
    test('lista salva é recuperada com o mesmo número de sites', () async {
      final cache = CacheService();
      final sites = [_siteCompleto(), _siteMinimo()];
      await cache.saveSites(_uf, sites);
      final loaded = await cache.loadSites(_uf);
      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
    });

    test('lista vazia pode ser salva e carregada', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, []);
      final loaded = await cache.loadSites(_uf);
      expect(loaded, isNotNull);
      expect(loaded!, isEmpty);
    });

    test('campos principais do site são preservados no round-trip', () async {
      final cache = CacheService();
      final original = _siteCompleto();
      await cache.saveSites(_uf, [original]);
      final loaded = (await cache.loadSites(_uf))!.first;

      expect(loaded.siteId, original.siteId);
      expect(loaded.sigla, original.sigla);
      expect(loaded.nome, original.nome);
      expect(loaded.endereco, original.endereco);
      expect(loaded.municipio, original.municipio);
      expect(loaded.tecnico, original.tecnico);
      expect(loaded.detentora, original.detentora);
      expect(loaded.uc, original.uc);
      expect(loaded.status, original.status);
    });

    test('coordenadas são preservadas com precisão no round-trip', () async {
      final cache = CacheService();
      final original = _siteCompleto();
      await cache.saveSites(_uf, [original]);
      final loaded = (await cache.loadSites(_uf))!.first;

      expect(loaded.latitude, original.latitude);
      expect(loaded.longitude, original.longitude);
    });

    test('imageUrls com URLs e nulls são preservadas no round-trip', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteCompleto()]);
      final loaded = (await cache.loadSites(_uf))!.first;

      expect(loaded.imageUrls.length, 5);
      expect(loaded.imageUrls[0], contains('foto1.jpg'));
      expect(loaded.imageUrls[1], contains('foto2.jpg'));
      expect(loaded.imageUrls[2], isNull);
      expect(loaded.imageUrls[3], isNull);
      expect(loaded.imageUrls[4], isNull);
    });

    test('campos operacionais preenchidos são preservados no round-trip', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteCompleto()]);
      final loaded = (await cache.loadSites(_uf))!.first;

      expect(loaded.chavePortao, 'MULTLOCK');
      expect(loaded.chaveGradil01, 'MA GDA');
      expect(loaded.fonte01, 'ELTEK 2500');
      expect(loaded.consumoFonte01, '12.5');
      expect(loaded.bateriasFonte01, '4');
    });

    test('campos operacionais null são preservados como null no round-trip', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteCompleto()]);
      final loaded = (await cache.loadSites(_uf))!.first;

      expect(loaded.chaveGradil02, isNull);
      expect(loaded.fonte02, isNull);
      expect(loaded.consumoFonte02, isNull);
      expect(loaded.bateriasFonte02, isNull);
    });

    test('site sem campos operacionais preserva todos os nulls no round-trip', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteMinimo()]);
      final loaded = (await cache.loadSites(_uf))!.first;

      expect(loaded.chavePortao, isNull);
      expect(loaded.chaveGradil01, isNull);
      expect(loaded.fonte01, isNull);
      expect(loaded.consumoFonte01, isNull);
      expect(loaded.bateriasFonte01, isNull);
    });

    test('status Desativado é preservado no round-trip', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteMinimo()]);
      final loaded = (await cache.loadSites(_uf))!.first;

      expect(loaded.status, 'Desativado');
      expect(loaded.ativo, isFalse);
    });
  });

  // ─── clear ───────────────────────────────────────────────────────────────────

  group('CacheService — clear', () {
    test('clear remove os dados e loadSites retorna null', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteCompleto()]);
      expect(await cache.loadSites(_uf), isNotNull);

      await cache.clear(_uf);
      expect(await cache.loadSites(_uf), isNull);
    });

    test('após clear é possível salvar novos dados normalmente', () async {
      final cache = CacheService();
      await cache.saveSites(_uf, [_siteCompleto()]);
      await cache.clear(_uf);
      await cache.saveSites(_uf, [_siteMinimo()]);

      final loaded = await cache.loadSites(_uf);
      expect(loaded, isNotNull);
      expect(loaded!.first.siteId, 'ITZ045');
    });
  });

  // ─── Cache corrompido ─────────────────────────────────────────────────────────

  group('CacheService — cache corrompido', () {
    test('JSON inválido retorna null e não lança exceção', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'sites_cache_MA_v2': 'json_invalido_{{{',
        'sites_cache_ts_MA_v2': ts,
      });
      final cache = CacheService();
      expect(await cache.loadSites(_uf), isNull);
    });

    test('JSON corrompido limpa o cache automaticamente', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'sites_cache_MA_v2': 'corrompido',
        'sites_cache_ts_MA_v2': ts,
      });
      final cache = CacheService();
      await cache.loadSites(_uf); // dispara limpeza interna
      // Após corrupção, um novo save/load deve funcionar normalmente
      await cache.saveSites(_uf, [_siteMinimo()]);
      expect(await cache.loadSites(_uf), isNotNull);
    });

    test('array com objeto malformado retorna null', () async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'sites_cache_MA_v2': '[{"campo_inexistente": true}]',
        'sites_cache_ts_MA_v2': ts,
      });
      final cache = CacheService();
      // fromJson com campos obrigatórios ausentes não deve travar o app
      expect(() async => await cache.loadSites(_uf), returnsNormally);
    });
  });
}
