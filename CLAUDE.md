# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Contexto do Projeto: Movel Tracker

Aplicativo Android "Movel Tracker" focado em produtividade para técnicos de campo da Claro no Maranhão. O objetivo é buscar informações técnicas de sites (torres) e facilitar a navegação GPS.

**Working directory:** Todos os comandos Flutter devem ser executados a partir do subdiretório `app/`.

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
  - `image_picker: ^1.1.2` - Seleção de imagens da câmera/galeria
  - `flutter_image_compress: ^2.3.0` - Compressão de imagens
  - `cached_network_image: ^3.4.1` - Cache de imagens da rede
  - `path_provider: ^2.1.4` - Acesso a diretórios do sistema
  - `flutter_dotenv: ^5.1.0` - Variáveis de ambiente
- **Design:** Material Design 3 (Identidade Visual Claro: Vermelho #EE1105, Branco, Cinza).

## 🏗️ Arquitetura do Código

### Estrutura de Diretórios
```
lib/
├── main.dart                 # Entry point da aplicação
├── theme/
│   └── app_colors.dart      # Definição de cores e temas
├── models/
│   └── site.dart            # Modelo de dados do Site (inclui imageUrls)
├── services/
│   ├── data_service.dart    # Integração com Google Sheets (CSV)
│   └── image_service.dart   # Upload/gerenciamento de imagens (Cloudinary)
├── repositories/
│   └── site_repository.dart  # Camada de dados com fallback mock
├── providers/
│   ├── site_provider.dart    # Gerenciador de estado (Provider)
│   └── image_provider.dart   # Gerenciador de estado de imagens
├── config/
│   └── cloudinary_config.dart # Configuração do Cloudinary e Google Apps Script
├── widgets/
│   └── image_picker_dialog.dart # Dialog para seleção de imagem
└── screens/
    ├── home_screen.dart      # Tela principal com lista e busca
    ├── site_detail_screen.dart # Tela de detalhes do site
    └── image_viewer_screen.dart # Visualizador de imagens
test/
├── models/
│   └── site_test.dart       # Testes do modelo Site
├── services/
│   └── data_service_test.dart # Testes do DataService
├── repositories/
│   └── site_repository_test.dart # Testes do SiteRepository
├── providers/
│   └── site_provider_test.dart # Testes do SiteProvider
└── widgets/
    ├── home_screen_test.dart    # Testes da tela principal
    └── site_detail_screen_test.dart # Testes da tela de detalhes
```

### Fluxo de Dados
```
Google Sheets (CSV)
    ↓
DataService (HTTP + CSV parsing)
    ↓
SiteRepository (Google Sheets + mock fallback + busca insensível a acentos)
    ↓
SiteProvider (estado + filtros de busca/município)
    ↓
Screens (UI com Material Design 3)

Fluxo de Upload de Imagem:
Camera/Galeria (image_picker)
    ↓
Compressão (flutter_image_compress)
    ↓
Upload para Cloudinary
    ↓
Sincronização com Google Sheets (Google Apps Script)
    ↓
ImageProvider (estado das imagens)
    ↓
Site (imageUrls atualizado)
```

## 📋 Requisitos de Negócio

- **Busca Offline-First:** O app carrega dados da planilha uma vez e permite busca local.
- **Pesquisa Inteligente:** Filtrar por Site ID, Sigla, Nome do Site, Município ou Técnico (busca insensível a acentos e maiúsculas/minúsculas).
- **Informações Obrigatórias:** Nome, Endereço, Coordenadas (Lat/Long), Município, Técnico, Detentora e UC.
- **Integração de GPS:** Botão direto para abrir a rota no Google Maps nativo do Android.
- **Gestão de Imagens:** Até 5 fotos por site, upload via Cloudinary, compressão automática, sincronização com Google Sheets.

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
  final String tecnico;        // Técnico responsável
  final double latitude;       // Coordenada latitude (aceita vírgula)
  final double longitude;      // Coordenada longitude (aceita vírgula)
  final String detentora;     // Ex: ATC
  final String uc;            // UC do site
  final String status;         // 'Ativo' ou 'Desativado'
  final List<String> imageUrls; // Lista de URLs das fotos (max 5)

  // Métodos úteis:
  bool get ativo;                        // Verifica se status == 'ativo'
  String get googleMapsNavigationUrl;    // URL de navegação
  String get googleMapsViewUrl;          // URL de visualização do mapa
  String getThumbnailUrl(String imageUrl) // Gera URL de thumbnail
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
| `tecnico` | Técnico responsável (usado na busca) | `João Silva` |
| `latitude` | Coordenada latitude (vírgula ou ponto) | `-2,529` |
| `longitude` | Coordenada longitude (vírgula ou ponto) | `-44,302` |
| `detentora` | Proprietário da torre | `ATC` |
| `uc` | UC do site | `12345678` |
| `status` | Status do site | `Ativo` |
| `foto_1` | URL da primeira foto (Cloudinary) | `https://res.cloudinary.com/...` |
| `foto_2` | URL da segunda foto | `https://res.cloudinary.com/...` |
| `foto_3` | URL da terceira foto | `https://res.cloudinary.com/...` |
| `foto_4` | URL da quarta foto | `https://res.cloudinary.com/...` |
| `foto_5` | URL da quinta foto | `https://res.cloudinary.com/...` |

## 🔗 Integração com Google Sheets

### Configuração da Planilha

1. Criar planilha no Google Sheets com as colunas acima
2. Compartilhar como "Qualquer pessoa com o link" (Visualizador)
3. Obter o ID da URL: `https://docs.google.com/spreadsheets/d/{ID}/edit`
4. Inserir o ID em `lib/services/data_service.dart`:
   ```dart
   static const String _csvUrl =
       'https://docs.google.com/spreadsheets/d/SEU_ID_AQUI/export?format=csv&gid=GID_AQUI';
   ```

**Nota:** A URL atual já está configurada com um ID de planilha real (`1nyRakcId5Zg4zal-eJps0aX-WIaMnPIN4wBuaif0UAc`). Para trocar, edite `_csvUrl` em `data_service.dart` ou use `DataService.getCsvUrl(planilhaId: 'NOVO_ID')`.

### Fluxo de Carregamento

1. **Inicialização:** SiteProvider tenta carregar do Google Sheets
2. **Fallback:** Se falhar, usa dados mock locais (definidos em `site_repository.dart`)
3. **Cache:** Dados são mantidos em memória para busca rápida
4. **Pesquisa:** Busca local insensível a acentos e maiúsculas/minúsculas (Site ID, Sigla, Nome, Município, Técnico)
5. **Refresh:** Use `SiteProvider.refresh()` para recarregar dados da planilha

### Dados Mock (Fallback)

O app inclui dados mock de 5 sites no `site_repository.dart` que são usados quando:
- A conexão com Google Sheets falha
- Durante desenvolvimento/teste sem acesso à planilha
- Para garantir que o app seja funcional mesmo offline

Os dados mock podem ser editados diretamente em `site_repository.dart` no método `_loadMockData()`.

### URL de Navegação Google Maps

A navegação usa URL web para compatibilidade:
```
https://www.google.com/maps/dir/?api=1&destination={latitude},{longitude}&navigate=yes
```

## 📸 Funcionalidade de Upload de Imagens

### Configuração do Cloudinary

O app usa Cloudinary para armazenamento de imagens. Configure em `lib/config/cloudinary_config.dart`:

```dart
class CloudinaryConfig {
  static const String cloudName = 'SEU_CLOUD_NAME';
  static const String uploadPreset = 'SEU_UPLOAD_PRESET';
  static const String googleAppsScriptUrl = 'URL_DO_GOOGLE_APPS_SCRIPT';
}
```

**Para configurar o Cloudinary:**
1. Criar conta em https://cloudinary.com
2. Obter o Cloud Name em Settings → Cloud name
3. Criar um Upload Preset em Settings → Upload → Upload presets (modo unsigned)
4. Copiar o nome do preset para `uploadPreset`

**Para configurar o Google Apps Script:**
1. Criar um Google Apps Script que receba POST com `{site_id, imageUrls}`
2. Implantar como aplicativo web (Executar como "Eu", Quem tem acesso "Qualquer pessoa")
3. Copiar a URL para `googleAppsScriptUrl`

### Fluxo de Upload de Imagens

```
1. Usuário seleciona imagem (câmera ou galeria)
2. ImagePicker captura o arquivo
3. ImageService valida (tamanho, extensão)
4. FlutterImageCompress comprime a imagem
5. Upload para Cloudinary via API unsigned
6. ImageService valida URL retornada
7. Sincronização com Google Sheets via Google Apps Script
8. ImageProvider atualiza estado local
9. UI mostra imagem carregada
```

### Limites e Validações

- **Máximo de 5 imagens** por site
- **Tamanho máximo de arquivo:** 25MB
- **Formatos suportados:** JPG, JPEG, PNG, WEBP, HEIC
- **Dimensões máximas:** 1920x2560 (HD)
- **Qualidade de compressão:** 85%
- **Rate limiting:** 2 segundos entre operações
- **Upload timeout:** 30 segundos

### Segurança

Todas as operações de upload incluem validações:
- Validação de HTTPS nas URLs do Cloudinary
- Sanitização de nomes de arquivo
- Proteção contra path traversal
- Detecção de padrões perigosos (XSS, SQL injection)
- Validação de domínio do Cloudinary
- Sanitização do site_id antes de enviar para Google Sheets

### ImageProvider

Gerencia o estado das imagens de um site:

```dart
// Carrega imagens de um site
await imageProvider.loadSiteImages(site);

// Adiciona nova imagem
await imageProvider.addImage(imageFile);

// Substitui imagem existente
await imageProvider.replaceImage(index, newImageFile);

// Remove imagem
await imageProvider.deleteImage(index);

// Limpa estado
imageProvider.clearImages();
```

**Propriedades:**
- `imageUrls` - Lista de URLs das imagens
- `canAddImage` - Verifica se pode adicionar mais
- `imageCount` - Quantidade de imagens
- `isLoading` - Estado de carregamento
- `error` - Mensagem de erro (se houver)

## 🚀 Comandos de Desenvolvimento

**Nota:** Executar sempre no diretório `app/` (ou usar `cd app` primeiro)

### Comandos Principais
- `flutter pub get` - Instalar dependências.
- `flutter run` - Iniciar o app no emulador/dispositivo.
- `flutter build apk --debug` - Gerar APK de teste (mais rápido).
- `flutter build apk --release` - Gerar APK de produção.
- `flutter analyze` - Analisar código para problemas.

### Testes
- `flutter test` - Executar todos os testes unitários e de widgets.
- `flutter test test/models/site_test.dart` - Executar testes de um arquivo específico.
- `flutter test --coverage` - Executar testes e gerar relatório de cobertura.

### App Icon
- `flutter pub run flutter_launcher_icons` - Gerar ícones do app a partir de `assets/icon/app_icon.png`.

## 📂 Estrutura de Pastas

- **`app/lib/`** - Código principal do Flutter (sempre use este diretório)
- **`app/android/lib/`** - Duplicação do lib principal (ignorar, legado - NÃO editar)
- **`app/test/`** - Testes unitários e de widgets
- **`app/assets/icon/`** - Ícone do app (app_icon.png)
- **`app/build/`** - Arquivos de build (gerados automaticamente)

**IMPORTANTE:** O diretório `app/android/lib/` é uma cópia redundante de `app/lib/` que deve ser ignorada. Sempre trabalhe em `app/lib/` para evitar inconsistências.

## 📝 Histórico de Commits

| Commit | Descrição |
|--------|-----------|
| `5aeef3f` | security: Add protections and validations to image upload feature |
| `10705ac` | test: Fix test files to match current codebase |
| `3fdb964` | fix: Update Google Apps Script with better error handling and debugging |
| `811d499` | feat: Add image upload and viewing functionality |
| `b4ab26c` | Update CLAUDE.md - Versão 01: Documentação completa com comandos de teste e arquitetura aprimorada |
| `8c7acf5` | Release v1.0.0 - Movel Tracker stable version |
| `91b6d79` | Update header title to Movel Tracker |
| `a76b5d5` | Update app name to Movel Tracker, add app icon, and fix search with accent-insensitive filtering |
| `24f74d7` | Add test dependencies for unit tests |
| `3ec9828` | Add tecnico field, fix coordinate parsing, and status handling |
| `f939d47` | Add Google Sheets integration and fix Google Maps navigation |
| `28b19ee` | Implement Flutter app structure with all features |
| `8cd8ed6` | Initial commit: add AGENT.md |

## 🔗 Documentação Relacionada

- **DADOS.md** - Documentação completa da fonte de dados e configuração do Google Sheets.

repositório remoto do projeto no github: https://github.com/RafaelRodriguest/Movel-Tracker.git