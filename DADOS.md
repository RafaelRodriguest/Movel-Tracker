# Fonte de Dados - Sites Claro Maranhão

Este documento descreve onde os dados dos sites são armazenados e como o aplicativo busca essas informações.

---

## 📍 Local de Armazenamento

### Google Sheets (Planilha)

Os dados dos sites são armazenados em uma planilha do Google Sheets que será pública para leitura, em uma conta google que criarei para armazenar essa planilha.

**Nome da Planilha:** `Sites Claro - Maranhão`

**Acesso Público:** A planilha deve ser compartilhada com link público (qualquer pessoa com o link pode visualizar).

---

## 📊 Estrutura das Colunas

| Coluna | Descrição | Exemplo | Tipo |
|--------|-----------|---------|------|
| `site_id` | Identificador único do site | `SLZ001` | String |
| `sigla` | Sigla/Nome técnico do site | `MASLS7` | String |
| `nome` | Nome descritivo do site | `São Luís Centro` | String |
| `endereco` | Endereço completo | `Av. Dom Pedro II, Centro` | String |
| `municipio` | Município/UF | `São Luís, MA` | String |
| `latitude` | Coordenada latitude | `-2.529` | Double |
| `longitude` | Coordenada longitude | `-44.302` | Double |
| `detentora` | Proprietário da torre | `ATC` | String |
| `uc` | UC do site | `12345678` | String |
| `tecnologias` | Tecnologias disponíveis | `4G,5G` | String |
| `status` | Status do site | `Ativo` | String |

---

## 🔗 Acesso aos Dados

### URL do Google Sheets (CSV)

Para acessar os dados em formato CSV diretamente da planilha:

```
https://docs.google.com/spreadsheets/d/{PLANILHA_ID}/export?format=csv
```

**Substitua `{PLANILHA_ID}` pelo ID da sua planilha.**

### Como encontrar o PLANILHA_ID

1. Abra sua planilha no Google Sheets
2. A URL tem o formato: `https://docs.google.com/spreadsheets/d/1A2B3C4D5E6F7G8H9I0J/edit#gid=0`
3. O ID é: `1A2B3C4D5E6F7G8H9I0J`

---

## 📱 Como o Aplicativo Busca os Dados

### Fluxo de Carregamento

1. **Inicialização:** Ao abrir o app, verifica se há dados armazenados localmente
2. **Busca (se necessário):** Faz requisição HTTP para a URL do CSV
3. **Parse:** Converte o CSV em uma lista de objetos `Site`
4. **Armazenamento Local:** Salva os dados para uso offline
5. **Busca:** Os usuários pesquisam usando os dados locais

### Endpoint no Código Dart

No arquivo `lib/services/data_service.dart`:

```dart
class DataService {
  // URL do Google Sheets CSV
  static const String _csvUrl = 'https://docs.google.com/spreadsheets/d/{PLANILHA_ID}/export?format=csv';

  Future<List<Site>> fetchSites() async {
    final response = await http.get(Uri.parse(_csvUrl));
    if (response.statusCode == 200) {
      return parseCsv(response.body);
    }
    throw Exception('Falha ao carregar dados');
  }
}
```

---

## 📝 Exemplo de Linha da Planilha (CSV)

```csv
site_id,sigla,nome,endereco,municipio,latitude,longitude,detentora,uc,tecnologias,status
SLZ001,MASLS7,São Luís Centro,Av. Dom Pedro II, Centro,São Luís, MA,-2.529,-44.302,ATC,12345678,4G,5G,Ativo
ITZ045,MAITZ2,Imperatriz Matriz,Rua Grande, Centro,Imperatriz, MA,-5.528,-47.477,American Tower,87654321,4G,Ativo
CXS012,MACXS4,Caxias Norte,Av. Floriano, Caxias,Caxias, MA,-4.850,-43.357,TorreBrasil,54321678,4G,5G,Ativo
```

---

## ⚠️ Configuração Necessária

### Para tornar a planilha acessível via CSV:

1. Abra a planilha no Google Sheets
2. Clique em **Compartilhar**
3. Mude para: **"Qualquer pessoa com o link"** e dê acesso de **Visualizador**
4. Copie o ID da URL e insira no código em `lib/services/data_service.dart`

### Para atualizar o ID no código:

Edite o arquivo `app/lib/services/data_service.dart` e altere a linha:

```dart
static const String _csvUrl = 'https://docs.google.com/spreadsheets/d/SEU_ID_AQUI/export?format=csv';
```

---

## 🔒 Segurança

- A planilha é **somente leitura** para o aplicativo
- Não há autenticação necessária para leitura (URL pública)
- Dados são públicos apenas para visualização
- Edição deve ser feita manualmente via interface do Google Sheets

---

## 📊 Modelo de Dados (Dart)

```dart
class Site {
  final String siteId;
  final String sigla;
  final String nome;
  final String endereco;
  final String municipio;
  final double latitude;
  final double longitude;
  final String detentora;
  final String uc;
  final List<String> tecnologias;
  final String status;

  Site({
    required this.siteId,
    required this.sigla,
    required this.nome,
    required this.endereco,
    required this.municipio,
    required this.latitude,
    required this.longitude,
    required this.detentora,
    required this.uc,
    required this.tecnologias,
    required this.status,
  });
}
```
