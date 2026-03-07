# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Movel Tracker

Aplicativo Android para técnicos de campo da Claro no Maranhão. Permite buscar informações técnicas de sites (torres) e navegar via GPS até eles.

**Working directory:** todos os comandos Flutter devem ser executados em `app/`.

## Tecnologias

- **Framework:** Flutter (exclusivamente Android)
- **Estado:** Provider (ChangeNotifier)
- **Dados:** Google Sheets consumido via CSV/HTTP
- **Design:** Material Design 3 (Vermelho Claro #EE1105, fundo #F8F6F5)

Dependências principais: `provider`, `http`, `csv`, `url_launcher`, `flutter_map`, `latlong2`

## Arquitetura

### Fluxo de dados
```
Google Sheets (CSV)
  → DataService (HTTP + CSV parsing)
  → SiteRepository (fallback mock + busca insensível a acentos)
  → SiteProvider (estado + filtros)
  → Screens
```

### Pontos-chave de design
- **Busca:** `SiteRepository.searchSites()` normaliza acentos manualmente (tabela de substituição em `_normalizeText`). Busca por Site ID, Sigla, Nome, Município e Técnico.
- **Coordenadas:** `Site._parseCoordinate()` aceita vírgula ou ponto decimal (formato brasileiro).
- **Fallback:** Se o Google Sheets falhar, `SiteRepository` mantém 5 sites mock em memória (definidos em `_loadMockData()`).
- **Planilha ativa:** ID `1nyRakcId5Zg4zal-eJps0aX-WIaMnPIN4wBuaif0UAc` em `data_service.dart`. Para trocar, edite `_csvUrl` ou use `DataService.getCsvUrl(planilhaId: 'NOVO_ID')`.
- **Refresh:** Use `SiteProvider.refresh()` para recarregar dados da planilha em runtime.

### Colunas esperadas na planilha
`site_id`, `sigla`, `nome`, `endereco`, `municipio`, `tecnico`, `latitude`, `longitude`, `detentora`, `uc`, `tecnologias` (separadas por vírgula), `status`

## Comandos

```bash
# Instalar dependências
flutter pub get

# Rodar no dispositivo
flutter run

# Build
flutter build apk --debug    # APK de teste
flutter build apk --release  # APK de produção

# Qualidade
flutter analyze
flutter test
flutter test test/models/site_test.dart  # teste específico
flutter test --coverage

# Ícone do app (a partir de assets/icon/app_icon.png)
flutter pub run flutter_launcher_icons
```

## Avisos importantes

- **Nunca edite** `app/android/lib/` — é cópia legada de `app/lib/`, deve ser ignorada. Sempre trabalhe em `app/lib/`.
- Repositório remoto: https://github.com/RafaelRodriguest/Movel-Tracker.git
