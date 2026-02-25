import 'package:flutter_test/flutter_test.dart';
import 'package:claro_sites_ma/repositories/site_repository.dart';
import 'package:claro_sites_ma/models/site.dart';

void main() {
  group('SiteRepository Tests', () {
    late SiteRepository repository;

    setUp(() {
      repository = SiteRepository();
    });

    group('Mock Data', () {
      test('Deve carregar dados mock inicialmente', () {
        final sites = repository.getAllSites();

        expect(sites, isNotEmpty);
        expect(sites.length, greaterThan(0));
      });

      test('Deve ter municipios unicos', () {
        final municipios = repository.getMunicipios();

        expect(municipios, isNotEmpty);
        expect(municipios, isNot(contains('Todos')));
      });

      test('Deve ter sites com status Ativo', () {
        final sites = repository.getAllSites();

        final ativos = sites.where((s) => s.ativo).toList();
        expect(ativos, isNotEmpty);
      });
    });

    group('getAllSites', () {
      test('Deve retornar lista de sites', () {
        final sites = repository.getAllSites();

        expect(sites, isList);
        expect(sites, isNotEmpty);
      });

      test('Deve retornar lista nao modificavel', () {
        final sites = repository.getAllSites();

        expect(() {
          sites.add(Site(
            siteId: 'TEST',
            sigla: 'TEST',
            nome: 'Test',
            endereco: 'Test',
            municipio: 'Test',
            tecnico: 'Test',
            latitude: 0.0,
            longitude: 0.0,
            detentora: 'ATC',
            uc: '123',
            tecnologias: ['4G'],
          ));
        }, throwsUnsupportedError);
      });
    });

    group('getMunicipios', () {
      test('Deve retornar lista de municipios unicos', () {
        final municipios = repository.getMunicipios();

        expect(municipios, isNotEmpty);

        final uniqueMunicipios = municipios.toSet().toList();
        expect(municipios.length, uniqueMunicipios.length);
      });

      test('Deve retornar municipios ordenados', () {
        final municipios = repository.getMunicipios();

        final sorted = List.from(municipios)..sort();

        expect(municipios, equals(sorted));
      });
    });

    group('searchSites', () {
      test('Deve buscar por siteId', () {
        final sites = repository.searchSites('SLZ001');

        expect(sites, isNotEmpty);
        expect(sites.every((s) => s.siteId.contains('SLZ001')), isTrue);
      });

      test('Deve buscar por nome do site', () {
        final sites = repository.searchSites('Centro');

        expect(sites, isNotEmpty);
        expect(sites.every((s) => s.nome.toLowerCase().contains('centro')), isTrue);
      });

      test('Deve buscar por municipio', () {
        final sites = repository.searchSites('Sao Luis');

        expect(sites, isNotEmpty);
        expect(sites.every((s) => s.municipio.toLowerCase().contains('sao luis')), isTrue);
      });

      test('Deve buscar por sigla', () {
        final sites = repository.searchSites('MASLS');

        expect(sites, isNotEmpty);
        expect(sites.every((s) => s.sigla.toLowerCase().contains('masls')), isTrue);
      });

      test('Deve ser case-insensitive', () {
        final sites1 = repository.searchSites('Sao Luis');
        final sites2 = repository.searchSites('SAO LUIS');

        expect(sites1.length, equals(sites2.length));
      });

      test('Deve retornar todos os sites quando query e vazia', () {
        final allSites = repository.getAllSites();
        final searchResults = repository.searchSites('');

        expect(searchResults.length, equals(allSites.length));
      });

      test('Deve retornar vazio quando nao ha resultados', () {
        final sites = repository.searchSites('INEXISTENTE_999');

        expect(sites, isEmpty);
      });
    });

    group('filterByMunicipio', () {
      test('Deve filtrar sites por municipio', () {
        final sites = repository.filterByMunicipio('Sao Luis');

        expect(sites, isNotEmpty);
        expect(sites.every((s) => s.municipio == 'Sao Luis'), isTrue);
      });

      test('Deve retornar todos os sites quando municipio e vazio', () {
        final allSites = repository.getAllSites();
        final filteredSites = repository.filterByMunicipio('');

        expect(filteredSites.length, equals(allSites.length));
      });

      test('Deve retornar vazio quando municipio nao existe', () {
        final sites = repository.filterByMunicipio('CidadeInexistente');

        expect(sites, isEmpty);
      });
    });

    group('filterByTecnologia', () {
      test('Deve filtrar sites por tecnologia', () {
        final sites = repository.filterByTecnologia('4G');

        expect(sites, isNotEmpty);
        expect(sites.every((s) => s.hasTecnologia('4G')), isTrue);
      });

      test('Deve ser case-insensitive', () {
        final sites1 = repository.filterByTecnologia('4g');
        final sites2 = repository.filterByTecnologia('4G');

        expect(sites1.length, equals(sites2.length));
      });

      test('Deve retornar vazio quando tecnologia nao existe', () {
        final sites = repository.filterByTecnologia('6G');

        expect(sites, isEmpty);
      });
    });

    group('getSiteById', () {
      test('Deve retornar site quando ID existe', () {
        final sites = repository.getAllSites();
        if (sites.isEmpty) return;

        final firstSiteId = sites.first.siteId;
        final site = repository.getSiteById(firstSiteId);

        expect(site, isNotNull);
        expect(site!.siteId, equals(firstSiteId));
      });

      test('Deve retornar null quando ID nao existe', () {
        final site = repository.getSiteById('INEXISTENTE_999');

        expect(site, isNull);
      });
    });

    group('isGoogleSheetsConfigured', () {
      test('Deve retornar true quando URL esta configurada', () {
        final isConfigured = repository.isGoogleSheetsConfigured();

        expect(isConfigured, isTrue);
      });
    });

    group('Validacoes de campos obrigatorios', () {
      test('Todos os sites mock devem ter siteId', () {
        final sites = repository.getAllSites();

        expect(sites.every((s) => s.siteId.isNotEmpty), isTrue);
      });

      test('Todos os sites mock devem ter nome', () {
        final sites = repository.getAllSites();

        expect(sites.every((s) => s.nome.isNotEmpty), isTrue);
      });
    });
  });
}
