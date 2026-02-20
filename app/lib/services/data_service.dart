import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import '../models/site.dart';

/// Serviço para buscar dados dos sites do Google Sheets (CSV)
class DataService {
  /// URL do Google Sheets CSV
  /// Substitua {PLANILHA_ID} pelo ID real da sua planilha
  /// Exemplo: 'https://docs.google.com/spreadsheets/d/1A2B3C4D5E6F7G8H9I0J/export?format=csv'
  static const String _csvUrl =
      'https://docs.google.com/spreadsheets/d/1nyRakcId5Zg4zal-eJps0aX-WIaMnPIN4wBuaif0UAc/export?format=csv&gid=1019904228';

  /// Busca os sites do Google Sheets e retorna uma lista de Site
  Future<List<Site>> fetchSites() async {
    try {
      final response = await http.get(
        Uri.parse(_csvUrl),
        headers: {'Accept-Charset': 'UTF-8'},
      );

      if (response.statusCode == 200) {
        // Decodificar explicitamente como UTF-8
        String body;
        try {
          body = utf8.decode(response.bodyBytes);
        } catch (e) {
          // Fallback para o body original se a decodificação falhar
          body = response.body;
        }
        return _parseCsv(body);
      } else {
        throw Exception(
          'Erro ao buscar dados: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Falha ao conectar: $e');
    }
  }

  /// Faz parse do CSV e converte para lista de Site
  List<Site> _parseCsv(String csvData) {
    // Remove BOM (Byte Order Mark) se presente - UTF-8 BOM
    if (csvData.startsWith('\uFEFF')) {
      csvData = csvData.substring(1);
    }

    // Remove carriage returns extra (Windows line endings)
    csvData = csvData.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Converte CSV para lista de listas
    final List<List<dynamic>> rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
      allowInvalid: false,
    ).convert(csvData);

    if (rows.isEmpty) {
      return [];
    }

    // Primeira linha contém os cabeçalhos
    final headers = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();

    // Mapeia índice das colunas
    final Map<String, int> columnIndex = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndex[headers[i]] = i;
    }

    // Converte as linhas de dados em objetos Site
    final List<Site> sites = [];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      try {
        final site = Site.fromJson(_rowToMap(row, columnIndex));
        sites.add(site);
      } catch (e) {
        // Ignora linhas com erro de parse
        continue;
      }
    }

    return sites;
  }

  /// Converte uma linha do CSV para Map usando os cabeçalhos
  Map<String, dynamic> _rowToMap(
    List<dynamic> row,
    Map<String, int> columnIndex,
  ) {
    final Map<String, dynamic> map = {};

    // Colunas esperadas conforme DADOS.md
    final columns = [
      'site_id',
      'sigla',
      'nome',
      'endereco',
      'municipio',
      'tecnico',
      'latitude',
      'longitude',
      'detentora',
      'uc',
      'tecnologias',
      'status',
    ];

    for (final col in columns) {
      final index = columnIndex[col];
      if (index != null && index < row.length) {
        // Remove espaços extras e converte para string
        var value = row[index]?.toString() ?? '';
        map[col] = value.trim();
      } else {
        map[col] = '';
      }
    }

    return map;
  }

  /// Atualiza a URL do Google Sheets
  /// Use este método para configurar o ID da planilha em runtime
  static String getCsvUrl({String? planilhaId}) {
    if (planilhaId != null && planilhaId.isNotEmpty) {
      return 'https://docs.google.com/spreadsheets/d/$planilhaId/export?format=csv';
    }
    return _csvUrl;
  }

  /// Testa se a URL está configurada corretamente
  bool isUrlConfigured() {
    return !_csvUrl.contains('SEU_ID_AQUI');
  }
}
