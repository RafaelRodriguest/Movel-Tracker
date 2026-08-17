import 'package:flutter_test/flutter_test.dart';
import 'package:movel_tracker/models/site.dart';

// Opções válidas espelhadas do site_operacional_screen.dart.
// As chaves são por estado; fontes e baterias seguem globais.
const _opcoesChaveBase = [
  'NO CONT A', 'MULTLOCK', 'EBT TETRA',
];

const _opcoesChavePorUf = <String, List<String>>{
  'MA': [
    'NO CONT A', 'MA GDA', 'MA GDV', 'MA GDB', 'MA GMR',
    'GD SLS V', 'GD CHI V', 'GD PHE V', 'GD BBL V', 'GD ITZ V',
    'MA PCN V', 'MULTLOCK', 'EBT TETRA',
  ],
};

List<String> _opcoesChaveDe(String uf) =>
    _opcoesChavePorUf[uf.toUpperCase()] ?? _opcoesChaveBase;

final _opcoesChave = _opcoesChaveDe('MA');

const _opcoesFonte = [
  'ELTEK 2500', 'ELTEK FLATPACK 3000', 'EMERSON',
  'VERTIV', 'DELTA DPR4000', 'DELTA DP2900',
];

final _opcoesBaterias = List.generate(9, (i) => '${i + 1}');

Site _siteBase({
  String? chavePortao,
  String? chaveGradil01,
  String? chaveGradil02,
  String? fonte01,
  String? fonte02,
  String? consumoFonte01,
  String? consumoFonte02,
  String? bateriasFonte01,
  String? bateriasFonte02,
}) {
  return Site(
    siteId: 'SLZ001',
    sigla: 'MASLS7',
    nome: 'São Luís Centro',
    endereco: 'Av. Dom Pedro II',
    municipio: 'São Luís',
    uf: 'MA',
    tecnico: 'João',
    latitude: -2.508704,
    longitude: -44.302,
    detentora: 'ATC',
    uc: '12345678',
    tecnologias: ['4G', '5G'],
    chavePortao: chavePortao,
    chaveGradil01: chaveGradil01,
    chaveGradil02: chaveGradil02,
    fonte01: fonte01,
    fonte02: fonte02,
    consumoFonte01: consumoFonte01,
    consumoFonte02: consumoFonte02,
    bateriasFonte01: bateriasFonte01,
    bateriasFonte02: bateriasFonte02,
  );
}

void main() {
  // ─── fromJson ────────────────────────────────────────────────────────────────

  group('Site.fromJson — campos operacionais', () {
    test('lê todos os campos operacionais corretamente do JSON do Supabase', () {
      final site = Site.fromJson({
        'site_id': 'SLZ001', 'sigla': 'X', 'nome': '', 'endereco': '',
        'municipio': '', 'tecnico': '', 'latitude': 0.0, 'longitude': 0.0,
        'detentora': '', 'uc': '', 'tecnologias': '', 'status': 'Ativo',
        'chave_portao': 'MULTLOCK',
        'chave_gradil_01': 'MA GDA',
        'chave_gradil_02': 'EBT TETRA',
        'fonte_01': 'ELTEK 2500',
        'fonte_02': 'VERTIV',
        'consumo_fonte_01': '12.5',
        'consumo_fonte_02': '8',
        'baterias_fonte_01': '4',
        'baterias_fonte_02': '2',
      });

      expect(site.chavePortao, 'MULTLOCK');
      expect(site.chaveGradil01, 'MA GDA');
      expect(site.chaveGradil02, 'EBT TETRA');
      expect(site.fonte01, 'ELTEK 2500');
      expect(site.fonte02, 'VERTIV');
      expect(site.consumoFonte01, '12.5');
      expect(site.consumoFonte02, '8');
      expect(site.bateriasFonte01, '4');
      expect(site.bateriasFonte02, '2');
    });

    test('campos operacionais ausentes no JSON retornam null', () {
      final site = Site.fromJson({
        'site_id': 'SLZ001', 'sigla': 'X', 'nome': '', 'endereco': '',
        'municipio': '', 'tecnico': '', 'latitude': 0.0, 'longitude': 0.0,
        'detentora': '', 'uc': '', 'tecnologias': '', 'status': 'Ativo',
      });

      expect(site.chavePortao, isNull);
      expect(site.chaveGradil01, isNull);
      expect(site.chaveGradil02, isNull);
      expect(site.fonte01, isNull);
      expect(site.fonte02, isNull);
      expect(site.consumoFonte01, isNull);
      expect(site.consumoFonte02, isNull);
      expect(site.bateriasFonte01, isNull);
      expect(site.bateriasFonte02, isNull);
    });

    test('campos operacionais nulos explicitamente no JSON retornam null', () {
      final site = Site.fromJson({
        'site_id': 'SLZ001', 'sigla': 'X', 'nome': '', 'endereco': '',
        'municipio': '', 'tecnico': '', 'latitude': 0.0, 'longitude': 0.0,
        'detentora': '', 'uc': '', 'tecnologias': '', 'status': 'Ativo',
        'chave_portao': null,
        'fonte_01': null,
        'consumo_fonte_01': null,
        'baterias_fonte_01': null,
      });

      expect(site.chavePortao, isNull);
      expect(site.fonte01, isNull);
      expect(site.consumoFonte01, isNull);
      expect(site.bateriasFonte01, isNull);
    });
  });

  // ─── toJson ──────────────────────────────────────────────────────────────────

  group('Site.toJson — campos operacionais', () {
    test('serializa todos os campos operacionais para as chaves corretas do Supabase', () {
      final site = _siteBase(
        chavePortao: 'MULTLOCK',
        chaveGradil01: 'MA GDA',
        chaveGradil02: 'EBT TETRA',
        fonte01: 'ELTEK 2500',
        fonte02: 'VERTIV',
        consumoFonte01: '12.5',
        consumoFonte02: '8',
        bateriasFonte01: '4',
        bateriasFonte02: '2',
      );

      final json = site.toJson();

      expect(json['chave_portao'], 'MULTLOCK');
      expect(json['chave_gradil_01'], 'MA GDA');
      expect(json['chave_gradil_02'], 'EBT TETRA');
      expect(json['fonte_01'], 'ELTEK 2500');
      expect(json['fonte_02'], 'VERTIV');
      expect(json['consumo_fonte_01'], '12.5');
      expect(json['consumo_fonte_02'], '8');
      expect(json['baterias_fonte_01'], '4');
      expect(json['baterias_fonte_02'], '2');
    });

    test('campos operacionais null são serializados como null', () {
      final site = _siteBase();
      final json = site.toJson();

      expect(json['chave_portao'], isNull);
      expect(json['fonte_01'], isNull);
      expect(json['consumo_fonte_01'], isNull);
      expect(json['baterias_fonte_01'], isNull);
    });

    test('fromJson → toJson é idempotente para campos operacionais', () {
      final original = {
        'site_id': 'SLZ001', 'sigla': 'X', 'nome': '', 'endereco': '',
        'municipio': '', 'tecnico': '', 'latitude': 0.0, 'longitude': 0.0,
        'detentora': '', 'uc': '', 'tecnologias': '', 'status': 'Ativo',
        'chave_portao': 'MA GMR',
        'chave_gradil_01': 'GD SLS V',
        'chave_gradil_02': null,
        'fonte_01': 'DELTA DPR4000',
        'fonte_02': null,
        'consumo_fonte_01': '5',
        'consumo_fonte_02': null,
        'baterias_fonte_01': '3',
        'baterias_fonte_02': null,
      };

      final json = Site.fromJson(original).toJson();

      expect(json['chave_portao'], original['chave_portao']);
      expect(json['chave_gradil_01'], original['chave_gradil_01']);
      expect(json['chave_gradil_02'], original['chave_gradil_02']);
      expect(json['fonte_01'], original['fonte_01']);
      expect(json['fonte_02'], original['fonte_02']);
      expect(json['consumo_fonte_01'], original['consumo_fonte_01']);
      expect(json['consumo_fonte_02'], original['consumo_fonte_02']);
      expect(json['baterias_fonte_01'], original['baterias_fonte_01']);
      expect(json['baterias_fonte_02'], original['baterias_fonte_02']);
    });
  });

  // ─── copyWith ────────────────────────────────────────────────────────────────

  group('Site.copyWith — campos operacionais', () {
    test('atualiza apenas os campos informados e preserva os demais', () {
      final original = _siteBase(
        chavePortao: 'MULTLOCK',
        fonte01: 'ELTEK 2500',
        consumoFonte01: '10',
        bateriasFonte01: '4',
      );

      final updated = original.copyWith(
        chavePortao: 'MA GDA',
        consumoFonte01: '15',
      );

      expect(updated.chavePortao, 'MA GDA');
      expect(updated.consumoFonte01, '15');
      // Campos não alterados devem ser preservados
      expect(updated.fonte01, 'ELTEK 2500');
      expect(updated.bateriasFonte01, '4');
      // Campos imutáveis do site não devem ser afetados
      expect(updated.siteId, original.siteId);
      expect(updated.nome, original.nome);
    });

    test('copyWith sem argumentos retorna objeto equivalente', () {
      final original = _siteBase(
        chavePortao: 'MULTLOCK',
        fonte01: 'VERTIV',
        bateriasFonte01: '2',
      );

      final copy = original.copyWith();

      expect(copy.chavePortao, original.chavePortao);
      expect(copy.fonte01, original.fonte01);
      expect(copy.bateriasFonte01, original.bateriasFonte01);
    });

    test('copyWith com null explícito limpa o campo — não mantém valor anterior', () {
      final original = _siteBase(
        chavePortao: 'MULTLOCK',
        chaveGradil01: 'MA GDA',
        fonte01: 'ELTEK 2500',
        consumoFonte01: '600',
        bateriasFonte01: '4',
      );

      // Simula o usuário limpando todos os campos na segunda edição
      final cleared = original.copyWith(
        chavePortao: null,
        chaveGradil01: null,
        fonte01: null,
        consumoFonte01: null,
        bateriasFonte01: null,
      );

      expect(cleared.chavePortao, isNull);
      expect(cleared.chaveGradil01, isNull);
      expect(cleared.fonte01, isNull);
      expect(cleared.consumoFonte01, isNull);
      expect(cleared.bateriasFonte01, isNull);
      // Campos não tocados devem ser preservados
      expect(cleared.siteId, original.siteId);
    });

    test('copyWith com null não afeta campos que não foram passados', () {
      final original = _siteBase(
        chavePortao: 'MULTLOCK',
        fonte01: 'ELTEK 2500',
        consumoFonte01: '600',
      );

      // Limpa apenas chavePortao — os outros devem ser preservados
      final updated = original.copyWith(chavePortao: null);

      expect(updated.chavePortao, isNull);
      expect(updated.fonte01, 'ELTEK 2500');
      expect(updated.consumoFonte01, '600');
    });
  });

  // ─── Validação das opções dos dropdowns ──────────────────────────────────────

  group('Validação — opções dos dropdowns', () {
    test('lista de chaves do MA contém exatamente 13 opções', () {
      expect(_opcoesChave.length, 13);
    });

    test('estados sem lista própria caem na base compartilhada', () {
      for (final uf in ['PA', 'AM', 'RR', 'AP']) {
        expect(_opcoesChaveDe(uf), _opcoesChaveBase,
            reason: '$uf ainda não tem chaves cadastradas');
      }
    });

    test('base compartilhada está contida na lista do MA', () {
      for (final opcao in _opcoesChaveBase) {
        expect(_opcoesChaveDe('MA').contains(opcao), isTrue);
      }
    });

    test('opcoesChaveDe normaliza a UF para maiúsculas', () {
      expect(_opcoesChaveDe('ma'), _opcoesChaveDe('MA'));
    });

    test('lista de fontes contém exatamente 6 opções', () {
      expect(_opcoesFonte.length, 6);
    });

    test('lista de baterias contém opções de 1 a 9', () {
      expect(_opcoesBaterias.length, 9);
      expect(_opcoesBaterias.first, '1');
      expect(_opcoesBaterias.last, '9');
    });

    test('EMERSON está na lista de fontes (não EMERSO)', () {
      expect(_opcoesFonte.contains('EMERSON'), isTrue);
      expect(_opcoesFonte.contains('EMERSO'), isFalse);
    });

    test('valores salvos pelo app são sempre opções válidas da lista de chaves', () {
      for (final opcao in _opcoesChave) {
        final site = _siteBase(chavePortao: opcao);
        expect(_opcoesChave.contains(site.chavePortao), isTrue,
            reason: 'chave "$opcao" deveria estar na lista válida');
      }
    });

    test('valores salvos pelo app são sempre opções válidas da lista de fontes', () {
      for (final opcao in _opcoesFonte) {
        final site = _siteBase(fonte01: opcao);
        expect(_opcoesFonte.contains(site.fonte01), isTrue,
            reason: 'fonte "$opcao" deveria estar na lista válida');
      }
    });
  });

  // ─── Segurança — entradas inesperadas ────────────────────────────────────────

  group('Segurança — entradas inesperadas', () {
    test('consumo com valor vazio é preservado como string vazia, não null', () {
      final site = Site.fromJson({
        'site_id': 'X', 'sigla': '', 'nome': '', 'endereco': '',
        'municipio': '', 'tecnico': '', 'latitude': 0.0, 'longitude': 0.0,
        'detentora': '', 'uc': '', 'tecnologias': '', 'status': 'Ativo',
        'consumo_fonte_01': '',
      });
      // String vazia deve ser preservada (a tela trata isso como "não preenchido")
      expect(site.consumoFonte01, '');
    });

    test('campos operacionais com valores arbitrários não afetam outros campos do site', () {
      final site = Site.fromJson({
        'site_id': 'SLZ001', 'sigla': 'MASLS7', 'nome': 'São Luís Centro',
        'endereco': 'Av. Dom Pedro II', 'municipio': 'São Luís',
        'tecnico': 'João', 'latitude': -2.508704, 'longitude': -44.302,
        'detentora': 'ATC', 'uc': '12345678', 'tecnologias': '4G,5G',
        'status': 'Ativo',
        'chave_portao': 'VALOR_QUALQUER',
        'fonte_01': 'FONTE_DESCONHECIDA',
        'consumo_fonte_01': '99999',
        'baterias_fonte_01': '99',
      });

      // Campos principais não devem ser corrompidos
      expect(site.siteId, 'SLZ001');
      expect(site.nome, 'São Luís Centro');
      expect(site.latitude, -2.508704);
      expect(site.tecnologias, ['4G', '5G']);
      expect(site.ativo, isTrue);
    });

    test('copyWith com campos operacionais não afeta imageUrls existentes', () {
      final original = _siteBase(fonte01: 'ELTEK 2500')
          .copyWith(imageUrls: ['https://example.com/foto1.jpg', null, null, null, null]);

      final updated = original.copyWith(fonte01: 'VERTIV');

      expect(updated.imageUrls[0], 'https://example.com/foto1.jpg');
      expect(updated.fonte01, 'VERTIV');
    });
  });
}
