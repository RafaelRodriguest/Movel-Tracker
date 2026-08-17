import 'package:flutter_test/flutter_test.dart';
import 'package:movel_tracker/models/site.dart';

void main() {
  group('Site.fromJson', () {
    test('aceita double direto do Supabase', () {
      final site = Site.fromJson({
        'site_id': 'SLZ001',
        'sigla': 'MASLS7',
        'nome': 'São Luís Centro',
        'endereco': 'Av. Dom Pedro II',
        'municipio': 'São Luís',
        'uf': 'MA',
        'tecnico': 'João',
        'latitude': -2.508704,
        'longitude': -44.302,
        'detentora': 'ATC',
        'uc': '12345678',
        'status': 'Ativo',
      });

      expect(site.latitude, -2.508704);
      expect(site.longitude, -44.302);
      expect(site.uc, '12345678');
      expect(site.uf, 'MA');
      expect(site.ativo, true);
    });

    test('aceita String com vírgula (fallback CSV)', () {
      final site = Site.fromJson({
        'site_id': 'ITZ045',
        'sigla': 'X',
        'nome': 'Teste',
        'endereco': '',
        'municipio': '',
        'tecnico': '',
        'latitude': '-5,5200',
        'longitude': '-47,4833',
        'detentora': '',
        'uc': '',
        'status': '',
      });

      expect(site.latitude, -5.52);
      expect(site.longitude, -47.4833);
      expect(site.ativo, true); // status vazio → Ativo
    });

    test('status Desativado reconhecido corretamente', () {
      final site = Site.fromJson({
        'site_id': 'X',
        'sigla': '', 'nome': '', 'endereco': '', 'municipio': '',
        'tecnico': '', 'latitude': 0.0, 'longitude': 0.0,
        'detentora': '', 'uc': '','status': 'Desativado',
      });

      expect(site.ativo, false);
    });

    test('URL do Google Maps usa ponto como separador', () {
      final site = Site.fromJson({
        'site_id': 'X', 'sigla': '', 'nome': '', 'endereco': '',
        'municipio': '', 'tecnico': '',
        'latitude': -2.508704, 'longitude': -44.302,
        'detentora': '', 'uc': '','status': 'Ativo',
      });

      expect(site.googleMapsNavigationUrl, contains('-2.508704'));
      expect(site.googleMapsNavigationUrl, contains('-44.302'));
    });
  });

  group('Site.uf', () {
    Map<String, dynamic> base(Map<String, dynamic> extra) => {
          'site_id': 'X', 'sigla': '', 'nome': '', 'endereco': '',
          'municipio': '', 'tecnico': '', 'latitude': 0.0, 'longitude': 0.0,
          'detentora': '', 'uc': '','status': 'Ativo',
          ...extra,
        };

    test('linha antiga sem coluna uf vira string vazia', () {
      expect(Site.fromJson(base({})).uf, '');
    });

    test('uf é normalizado para maiúsculas', () {
      expect(Site.fromJson(base({'uf': 'pa'})).uf, 'PA');
    });

    test('uf sobrevive ao round-trip fromJson → toJson', () {
      final json = Site.fromJson(base({'uf': 'AM'})).toJson();
      expect(json['uf'], 'AM');
      expect(Site.fromJson(json).uf, 'AM');
    });

    test('copyWith preserva a uf', () {
      final site = Site.fromJson(base({'uf': 'RR'}));
      expect(site.copyWith(fonte01: 'VERTIV').uf, 'RR');
    });
  });
}
