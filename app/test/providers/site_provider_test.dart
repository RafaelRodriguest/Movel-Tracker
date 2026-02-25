import 'package:flutter_test/flutter_test.dart';
import 'package:movel_tracker/providers/site_provider.dart';

void main() {
  group('SiteProvider Tests', () {
    late SiteProvider provider;

    setUp(() {
      provider = SiteProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Estado inicial', () {
      test('Deve ter siteCount igual a filteredSites.length', () {
        expect(provider.siteCount, equals(provider.filteredSites.length));
      });

      test('Deve ter searchQuery vazio inicialmente', () {
        expect(provider.searchQuery, '');
      });

      test('Deve ter selectedMunicipio como "Todos"', () {
        expect(provider.selectedMunicipio, 'Todos');
      });

      test('Deve ter municipios começando com "Todos"', () {
        expect(provider.municipios.first, 'Todos');
      });
    });

    group('updateSearch', () {
      test('Deve atualizar searchQuery', () {
        provider.updateSearch('São Luís');

        expect(provider.searchQuery, 'São Luís');
      });

      test('Deve notificar listeners quando search muda', () {
        var notified = false;
        provider.addListener(() {
          notified = true;
        });

        provider.updateSearch('teste');

        expect(notified, isTrue);
      });
    });

    group('updateMunicipioFilter', () {
      test('Deve atualizar selectedMunicipio', () {
        provider.updateMunicipioFilter('São Luís');

        expect(provider.selectedMunicipio, 'São Luís');
      });

      test('Deve notificar listeners quando filtro muda', () {
        var notified = false;
        provider.addListener(() {
          notified = true;
        });

        provider.updateMunicipioFilter('São Luís');

        expect(notified, isTrue);
      });
    });

    group('clearFilters', () {
      test('Deve limpar searchQuery', () {
        provider.updateSearch('teste');
        provider.clearFilters();

        expect(provider.searchQuery, '');
      });

      test('Deve limpar selectedMunicipio', () {
        provider.updateMunicipioFilter('São Luís');
        provider.clearFilters();

        expect(provider.selectedMunicipio, 'Todos');
      });
    });

    group('getSiteById', () {
      test('Deve retornar null quando ID não existe', () {
        final site = provider.getSiteById('INEXISTENTE_999');

        expect(site, isNull);
      });

      test('Deve retornar null quando ID é vazio', () {
        final site = provider.getSiteById('');

        expect(site, isNull);
      });
    });

    group('Casos de borda', () {
      test('Deve lidar com busca especial', () {
        // Não deve quebrar
        provider.updateSearch('!@#\$%');

        expect(provider.searchQuery, '!@#\$%');
      });

      test('Deve lidar com busca com espaços', () {
        provider.updateSearch('  São Luís  ');

        expect(provider.searchQuery, '  São Luís  ');
      });
    });

    group('Municípios', () {
      test('Deve sempre ter "Todos" como primeira opção', () {
        expect(provider.municipios.first, 'Todos');
      });

      test('Deve ter municípios únicos', () {
        final municipios = provider.municipios.skip(1).toList(); // Pular "Todos"
        final uniqueMunicipios = municipios.toSet().toList();

        expect(municipios.length, equals(uniqueMunicipios.length));
      });
    });
  });
}
