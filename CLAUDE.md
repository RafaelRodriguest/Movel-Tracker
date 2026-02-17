# Contexto do Projeto: Localizador de Sites Claro (Maranhão)

Aplicativo Android focado em produtividade para técnicos de campo da Claro no Maranhão. O objetivo é buscar informações técnicas de sites (torres) e facilitar a navegação GPS.

## 🛠 Tecnologias e Arquitetura

- **Framework:** Flutter (Foco exclusivo em Android).
- **Gerenciamento de Estado:** Provider (Padrão ChangeNotifier).
- **Fonte de Dados:** Google Sheets (Consumido via CSV/HTTP) - Custo Zero.
- **Dependências:**
  - `provider: ^6.1.2` - Gerenciamento de estado
  - `url_launcher: ^6.3.0` - Integração com Google Maps
  - `flutter_map: ^8.0.0` - Visualização de mapa (OpenStreetMap)
  - `latlong2: ^0.9.1` - Coordenadas geográficas
  - `http: ^1.2.2` - Requisições HTTP
  - `csv: ^6.0.0` - Parsing de CSV do Google Sheets
- **Design:** Material Design 3 (Identidade Visual Claro: Vermelho #EE1105, Branco, Cinza).

## 🏗️ Arquitetura do Código

```
lib/
├── main.dart                 # Entry point da aplicação
├── theme/
│   └── app_colors.dart      # Definição de cores e temas
├── models/
│   └── site.dart            # Modelo de dados do Site
├── services/
│   └── data_service.dart    # Integração com Google Sheets (CSV)
├── repositories/
│   └── site_repository.dart  # Camada de dados com fallback mock
├── providers/
│   └── site_provider.dart   # Gerenciador de estado (Provider)
└── screens/
    ├── home_screen.dart      # Tela principal com lista e busca
    └── site_detail_screen.dart # Tela de detalhes do site
```

## 📋 Requisitos de Negócio

- **Busca Offline-First:** O app carrega dados da planilha uma vez e permite busca local.
- **Pesquisa Inteligente:** Filtrar por Site ID, Sigla, Nome do Site ou Município.
- **Informações Obrigatórias:** Nome, Endereço, Coordenadas (Lat/Long), Município, Detentora, UC e Tecnologias (2G, 3G, 4G, 5G).
- **Integração de GPS:** Botão direto para abrir a rota no Google Maps nativo do Android.

## 🎨 Especificações de UI/UX

- **Tela de Busca:** Barra de pesquisa persistente no topo, lista de cards informativos abaixo.
- **Cores:** Fundo claro (#F8F6F5), cards brancos com elevação suave, botões de ação em Vermelho Claro (#EE1105).
- **Interação:** Ao clicar no card, transição suave para a tela de detalhes.

## 📊 Estrutura de Dados

### Modelo Site

```dart
class Site {
  final String siteId;        // Ex: SLZ001
  final String sigla;         // Ex: MASLS7
  final String nome;           // Ex: São Luís Centro
  final String endereco;       // Endereço completo
  final String municipio;      // Ex: São Luís
  final double latitude;       // Coordenada latitude
  final double longitude;      // Coordenada longitude
  final String detentora;     // Ex: ATC
  final String uc;            // UC do site
  final List<String> tecnologias; // ['4G', '5G']
  final String status;         // 'Ativo' ou 'Desativado'
}
```

### Colunas da Planilha Google Sheets

| Coluna | Descrição | Exemplo |
|--------|-----------|---------|
| `site_id` | Identificador único do site | `SLZ001` |
| `sigla` | Sigla/Nome técnico do site | `MASLS7` |
| `nome` | Nome descritivo do site | `São Luís Centro` |
| `endereco` | Endereço completo | `Av. Dom Pedro II, Centro` |
| `municipio` | Município/UF | `São Luís, MA` |
| `latitude` | Coordenada latitude | `-2.529` |
| `longitude` | Coordenada longitude | `-44.302` |
| `detentora` | Proprietário da torre | `ATC` |
| `uc` | UC do site | `12345678` |
| `tecnologias` | Tecnologias disponíveis | `4G,5G` |
| `status` | Status do site | `Ativo` |

## 🔗 Integração com Google Sheets

### Configuração da Planilha

1. Criar planilha no Google Sheets com as colunas acima
2. Compartilhar como "Qualquer pessoa com o link" (Visualizador)
3. Obter o ID da URL: `https://docs.google.com/spreadsheets/d/{ID}/edit`
4. Inserir o ID em `lib/services/data_service.dart`:
   ```dart
   static const String _csvUrl =
       'https://docs.google.com/spreadsheets/d/SEU_ID_AQUI/export?format=csv';
   ```

### Fluxo de Carregamento

1. **Inicialização:** SiteProvider tenta carregar do Google Sheets
2. **Fallback:** Se falhar, usa dados mock locais
3. **Cache:** Dados são mantidos em memória para busca rápida
4. **Pesquisa:** Busca local (Site ID, Sigla, Nome, Município)

### URL de Navegação Google Maps

A navegação usa URL web para compatibilidade:
```
https://www.google.com/maps/dir/?api=1&destination={latitude},{longitude}&navigate=yes
```

## 🚀 Comandos de Desenvolvimento

- `flutter pub get` - Instalar dependências.
- `flutter run` - Iniciar o app no emulador/dispositivo.
- `flutter build apk --debug` - Gerar APK de teste (mais rápido).
- `flutter build apk --release` - Gerar APK de produção.

## 📝 Histórico de Commits

| Commit | Descrição |
|--------|-----------|
| `f939d47` | Add Google Sheets integration and fix Google Maps navigation |
| `28b19ee` | Implement Flutter app structure with all features |
| `8cd8ed6` | Initial commit: add AGENT.md |

## 🔗 Documentação Relacionada

- **DADOS.md** - Documentação completa da fonte de dados e configuração do Google Sheets.
