import 'package:flutter_test/flutter_test.dart';
import 'package:claro_sites_ma/models/site.dart';

void main() {
  group('Site Model Tests', () {
    test('Deve criar um Site com todos os campos', () {
      final site = Site(
        siteId: 'SLZ001',
        sigla: 'MASLS7',
        nome: 'São Luís Centro',
        endereco: 'Av. Dom Pedro II, Centro',
        municipio: 'São Luís',
        tecnico: 'João Silva',
        latitude: -2.5297,
        longitude: -44.3028,
        detentora: 'ATC',
        uc: '12345678',
        status: 'Ativo',
      );

      expect(site.siteId, 'SLZ001');
      expect(site.sigla, 'MASLS7');
      expect(site.nome, 'São Luís Centro');
      expect(site.endereco, 'Av. Dom Pedro II, Centro');
      expect(site.municipio, 'São Luís');
      expect(site.tecnico, 'João Silva');
      expect(site.latitude, -2.5297);
      expect(site.longitude, -44.3028);
      expect(site.detentora, 'ATC');
      expect(site.uc, '12345678');
      expect(site.status, 'Ativo');
    });

    test('Deve ter status padrão como Ativo', () {
      final site = Site(
        siteId: 'SLZ001',
        sigla: 'MASLS7',
        nome: 'Test',
        endereco: 'Test',
        municipio: 'Test',
        tecnico: 'Test',
        latitude: -2.0,
        longitude: -44.0,
        detentora: 'ATC',
        uc: '123',
      );

      expect(site.status, 'Ativo');
    });

    group('fromJson', () {
      test('Deve criar Site a partir de JSON válido', () {
        final json = {
          'site_id': 'SLZ001',
          'sigla': 'MASLS7',
          'nome': 'São Luís Centro',
          'endereco': 'Av. Dom Pedro II',
          'municipio': 'São Luís',
          'tecnico': 'João Silva',
          'latitude': '-2.5297',
          'longitude': '-44.3028',
          'detentora': 'ATC',
          'uc': '12345678',
          'status': 'Ativo',
        };

        final site = Site.fromJson(json);

        expect(site.siteId, 'SLZ001');
        expect(site.sigla, 'MASLS7');
        expect(site.nome, 'São Luís Centro');
        expect(site.tecnico, 'João Silva');
        expect(site.latitude, -2.5297);
        expect(site.longitude, -44.3028);
        expect(site.status, 'Ativo');
      });

      test('Deve usar valores padrão quando campos estão ausentes', () {
        final json = {
          'site_id': 'SLZ001',
          'sigla': 'MASLS7',
          'nome': 'Test',
          'endereco': 'Test',
          'municipio': 'Test',
          'tecnico': '',
          'latitude': '-2.5',
          'longitude': '-44.5',
          'detentora': 'ATC',
          'uc': '',
          'status': '',
        };

        final site = Site.fromJson(json);

        expect(site.siteId, 'SLZ001');
        expect(site.uc, '');
        expect(site.status, 'Ativo'); // Status vazio deve usar padrão
      });

      test('Deve parsear coordenadas com vírgula (formato brasileiro)', () {
        final json = {
          'site_id': 'SLZ001',
          'sigla': 'MASLS7',
          'nome': 'Test',
          'endereco': 'Test',
          'municipio': 'Test',
          'tecnico': '',
          'latitude': '-2,508704',
          'longitude': '-44,263011',
          'detentora': 'ATC',
          'uc': '',
          'status': '',
        };

        final site = Site.fromJson(json);

        expect(site.latitude, -2.508704);
        expect(site.longitude, -44.263011);
      });

      test('Deve lidar com latitude/longitude inválidos', () {
        final json = {
          'site_id': 'SLZ001',
          'sigla': 'MASLS7',
          'nome': 'Test',
          'endereco': 'Test',
          'municipio': 'Test',
          'tecnico': '',
          'latitude': 'invalido',
          'longitude': 'invalido',
          'detentora': 'ATC',
          'uc': '',
          'status': '',
        };

        final site = Site.fromJson(json);

        expect(site.latitude, 0.0);
        expect(site.longitude, 0.0);
      });
    });

    group('toJson', () {
      test('Deve converter Site para JSON', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'São Luís Centro',
          endereco: 'Av. Dom Pedro II',
          municipio: 'São Luís',
          tecnico: 'João Silva',
          latitude: -2.5297,
          longitude: -44.3028,
          detentora: 'ATC',
          uc: '12345678',
          status: 'Ativo',
        );

        final json = site.toJson();

        expect(json['site_id'], 'SLZ001');
        expect(json['sigla'], 'MASLS7');
        expect(json['nome'], 'São Luís Centro');
        expect(json['tecnico'], 'João Silva');
        expect(json['status'], 'Ativo');
      });
    });

    group('ativo getter', () {
      test('Deve retornar true quando status é "ativo"', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'ativo',
        );

        expect(site.ativo, isTrue);
      });

      test('Deve retornar true quando status é "Ativo"', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'Ativo',
        );

        expect(site.ativo, isTrue);
      });

      test('Deve retornar true quando status é "ATIVO"', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'ATIVO',
        );

        expect(site.ativo, isTrue);
      });

      test('Deve retornar true quando status é "active"', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'active',
        );

        expect(site.ativo, isTrue);
      });

      test('Deve retornar true quando status é vazio', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: '',
        );

        expect(site.ativo, isTrue);
      });

      test('Deve retornar false quando status é "inativo"', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'inativo',
        );

        expect(site.ativo, isFalse);
      });

      test('Deve retornar false quando status é "Desativado"', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'Desativado',
        );

        expect(site.ativo, isFalse);
      });
    });

    group('Equality', () {
      test('Deve ser igual quando siteId é o mesmo', () {
        final site1 = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test1',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'Ativo',
        );

        final site2 = Site(
          siteId: 'SLZ001',
          sigla: 'OUTRO',
          nome: 'Test2',
          endereco: 'Outro',
          municipio: 'Outro',
          tecnico: 'Outro',
          latitude: -3.0,
          longitude: -45.0,
          detentora: 'OUTRO',
          uc: '456',
          status: 'Inativo',
        );

        expect(site1, equals(site2));
      });

      test('Deve ser diferente quando siteId é diferente', () {
        final site1 = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'Ativo',
        );

        final site2 = Site(
          siteId: 'SLZ002',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.0,
          longitude: -44.0,
          detentora: 'ATC',
          uc: '123',
          status: 'Ativo',
        );

        expect(site1, isNot(equals(site2)));
      });
    });

    group('URLs do Google Maps', () {
      test('Deve gerar URL de navegação corretamente', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.5297,
          longitude: -44.3028,
          detentora: 'ATC',
          uc: '123',
          status: 'Ativo',
        );

        expect(
          site.googleMapsNavigationUrl,
          'https://www.google.com/maps/dir/?api=1&destination=-2.5297,-44.3028&navigate=yes',
        );
      });

      test('Deve gerar URL de visualização corretamente', () {
        final site = Site(
          siteId: 'SLZ001',
          sigla: 'MASLS7',
          nome: 'Test',
          endereco: 'Test',
          municipio: 'Test',
          tecnico: 'Test',
          latitude: -2.5297,
          longitude: -44.3028,
          detentora: 'ATC',
          uc: '123',
          status: 'Ativo',
        );

        expect(
          site.googleMapsViewUrl,
          'https://www.google.com/maps/search/?api=1&query=-2.5297,-44.3028',
        );
      });
    });
  });
}
