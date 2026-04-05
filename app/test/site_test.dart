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
        'tecnico': 'João',
        'latitude': -2.508704,
        'longitude': -44.302,
        'detentora': 'ATC',
        'uc': '12345678',
        'tecnologias': '4G,5G',
        'status': 'Ativo',
      });

      expect(site.latitude, -2.508704);
      expect(site.longitude, -44.302);
      expect(site.uc, '12345678');
      expect(site.tecnologias, ['4G', '5G']);
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
        'tecnologias': '',
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
        'detentora': '', 'uc': '', 'tecnologias': '', 'status': 'Desativado',
      });

      expect(site.ativo, false);
    });

    test('URL do Google Maps usa ponto como separador', () {
      final site = Site.fromJson({
        'site_id': 'X', 'sigla': '', 'nome': '', 'endereco': '',
        'municipio': '', 'tecnico': '',
        'latitude': -2.508704, 'longitude': -44.302,
        'detentora': '', 'uc': '', 'tecnologias': '', 'status': 'Ativo',
      });

      expect(site.googleMapsNavigationUrl, contains('-2.508704'));
      expect(site.googleMapsNavigationUrl, contains('-44.302'));
    });
  });
}
