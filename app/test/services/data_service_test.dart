import 'package:flutter_test/flutter_test.dart';
import 'package:movel_tracker/services/data_service.dart';

void main() {
  group('DataService Tests', () {
    late DataService dataService;

    setUp(() {
      dataService = DataService();
    });

    group('getCsvUrl', () {
      test('Deve retornar URL padrão quando planilhaId é nulo', () {
        final url = DataService.getCsvUrl();

        expect(url, contains('1nyRakcId5Zg4zal-eJps0aX-WIaMnPIN4wBuaif0UAc'));
        expect(url, contains('export?format=csv'));
      });

      test('Deve retornar URL com planilhaId fornecido', () {
        final url = DataService.getCsvUrl(planilhaId: 'NOVO_ID_123');

        expect(url, 'https://docs.google.com/spreadsheets/d/NOVO_ID_123/export?format=csv');
      });

      test('Deve retornar URL padrão quando planilhaId é vazio', () {
        final url = DataService.getCsvUrl(planilhaId: '');

        expect(url, contains('1nyRakcId5Zg4zal-eJps0aX-WIaMnPIN4wBuaif0UAc'));
      });
    });

    group('isUrlConfigured', () {
      test('Deve retornar true quando URL não contém placeholder', () {
        expect(dataService.isUrlConfigured(), isTrue);
      });
    });

    group('Integração com Google Sheets', () {
      test('Deve ter URL configurada corretamente', () {
        final url = DataService.getCsvUrl();

        expect(url, startsWith('https://docs.google.com/spreadsheets/d/'));
        expect(url, contains('export?format=csv'));
      });

      test('Deve ter ID da planilha na URL', () {
        final url = DataService.getCsvUrl();

        expect(url, contains(RegExp(r'/[A-Za-z0-9_-]+/export')));
      });
    });

    group('Validações', () {
      test('URL padrão deve ser válida', () {
        final url = DataService.getCsvUrl();

        // Deve ser um HTTPS válido
        expect(url, startsWith('https://'));
        expect(url, contains('docs.google.com'));

        // Deve conter os parâmetros corretos
        expect(url, contains('export'));
        expect(url, contains('format=csv'));
      });

      test('URL customizada deve ser válida', () {
        final url = DataService.getCsvUrl(planilhaId: 'ABC123');

        expect(url, 'https://docs.google.com/spreadsheets/d/ABC123/export?format=csv');
      });
    });
  });
}
