# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Contexto do Projeto: Movel Tracker

Aplicativo Android "Movel Tracker" para técnicos de campo da Claro no Maranhão. Permite consultar informações técnicas de sites (torres), navegar via GPS e gerenciar fotos dos sites.

**Working directory:** Todos os comandos Flutter devem ser executados a partir do subdiretório `app/`.

## 🛠 Tecnologias e Dependências

- **Framework:** Flutter (Android only)
- **Estado:** Provider (ChangeNotifier)
- **Backend:** Supabase (Postgres + Auth + Row Level Security)
- **Imagens:** Cloudinary (upload) + `cached_network_image` (exibição)
- **Dependências principais:**
  - `supabase_flutter: ^2.8.4` — DB, Auth, RLS
  - `provider: ^6.1.2` — gerenciamento de estado
  - `image_picker: ^1.1.2` — seleção de fotos
  - `cached_network_image: ^3.4.1` — cache de imagens
  - `url_launcher: ^6.3.0` — Google Maps
  - `flutter_map: ^8.0.0` — mapa OpenStreetMap
  - `http: ^1.2.2` / `csv: ^6.0.0` — legado Google Sheets (ainda presente mas não é a fonte primária)

## 🏗️ Arquitetura

### Estrutura de Diretórios

```
lib/
├── config/
│   └── env.dart                  # Credenciais: Supabase URL/anonKey, Cloudinary
├── models/
│   ├── site.dart                 # Modelo Site (+ imageUrls, consumoAtual, padraoChave)
│   └── user_profile.dart         # Perfil do usuário (id, login, nome, email, role)
├── services/
│   ├── supabase_service.dart     # CRUD sites/fotos + insertAuditLog
│   ├── cloudinary_service.dart   # Upload de imagem para Cloudinary
│   └── data_service.dart         # Legado: Google Sheets CSV (fallback)
├── repositories/
│   └── site_repository.dart      # Carrega do Supabase; fallback mock local
├── providers/
│   ├── auth_provider.dart        # Sessão Supabase, login, logout, reset de senha
│   └── site_provider.dart        # Lista/filtros de sites, atualiza imageUrls localmente
├── screens/
│   ├── login_screen.dart         # Login com número de login + senha
│   ├── reset_password_screen.dart # Redefinição de senha via deep link
│   ├── home_screen.dart          # Lista, busca e filtro de sites
│   └── site_detail_screen.dart   # Detalhes do site + gerenciamento de fotos
└── theme/
    └── app_colors.dart           # Cores Claro: vermelho #EE1105, branco, cinza
```

### Fluxo de Dados

```
Supabase (tabela sites)
    ↓
SupabaseService.fetchSites()
    ↓
SiteRepository.loadFromSupabase() — fallback: mock local
    ↓
SiteProvider (estado + filtros)
    ↓
HomeScreen / SiteDetailScreen
```

### Fluxo de Autenticação

```
main.dart → _AppEntry
    ├── auth.isPasswordRecovery → ResetPasswordScreen
    ├── auth.isLoggedIn         → HomeScreen
    └── (nenhum)                → LoginScreen

Login: login (número) → RPC get_email_by_login → signInWithPassword
Reset de senha: e-mail → deep link com token → getSessionFromUrl → ResetPasswordScreen
```

`AuthProvider` escuta `onAuthStateChange` e deep links via `app_links`. Sessão é persistida automaticamente pelo `supabase_flutter`.

### Fluxo de Upload de Foto

```
image_picker → CloudinaryService.upload(file) → URL Cloudinary
    ↓
SupabaseService.updateFoto(siteId, index, url)
    + insertAuditLog(siteId, action: 'foto_add'/'foto_update')
    ↓
SiteProvider.updateSiteImageUrls(siteId, urls) — atualiza estado local
```

## 📊 Modelos de Dados

### Site (campos Supabase)

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `site_id` | String | ID único (ex: `SLZ001`) |
| `sigla` | String | Sigla técnica (ex: `MASLS7`) |
| `nome` | String | Nome descritivo |
| `endereco` | String | Endereço completo |
| `municipio` | String | Município (ex: `São Luís`) |
| `tecnico` | String | Técnico responsável |
| `latitude` / `longitude` | double | Coordenadas |
| `detentora` | String | Proprietário da torre |
| `uc` | String | Unidade Consumidora |
| `tecnologias` | String | CSV separado por vírgula (`4G,5G`) |
| `status` | String | `Ativo` ou `Desativado` |
| `foto_1`–`foto_5` | String? | URLs de imagem no Cloudinary |
| `consumo_atual` | String? | Consumo atual do site |
| `padrao_chave` | String? | Padrão de chave do site |

### Tabelas Supabase

- **`sites`** — dados dos sites (RLS: authenticated lê; cell_owner atualiza)
- **`profiles`** — perfil do usuário (`id`, `login`, `nome`, `email`, `role`)
- **`audit_log`** — registro de ações de foto (`user_id`, `site_id`, `action`, `detail`)

### Perfis de Acesso

| Role | Visualiza | Gerencia fotos |
|------|:---------:|:--------------:|
| `cell_owner` | ✅ | ✅ |
| `geral` | ✅ | ❌ |

Usuários são cadastrados **manualmente pelo admin** no Supabase Dashboard. Não há auto-cadastro no app. Somente domínios `@claro.com.br` e `@stte.com.br` são autorizados.

## 🔧 Configuração (`lib/config/env.dart`)

Credenciais hardcoded (não há `.env` separado):
- `Env.supabaseUrl` / `Env.supabaseAnonKey`
- `Env.cloudinaryCloudName` / `Env.cloudinaryUploadPreset`

## 🚀 Comandos de Desenvolvimento

Execute sempre a partir do diretório `app/`:

```bash
flutter pub get          # Instalar dependências
flutter run              # Rodar no dispositivo/emulador
flutter analyze          # Análise estática
flutter test             # Todos os testes (apenas app/test/site_test.dart atualmente)
flutter test test/site_test.dart  # Teste específico
flutter build apk --debug    # APK de debug
flutter build apk --release  # APK de produção
flutter pub run flutter_launcher_icons  # Regenerar ícone do app
```

## 📂 Avisos Importantes

- **`app/android/lib/`** — cópia redundante de `app/lib/`, ignorar. Trabalhe sempre em `app/lib/`.
- **`data_service.dart`** — código legado do Google Sheets. A fonte ativa é o Supabase via `supabase_service.dart`.
- **Deep link** de reset de senha: `com.claro.moveltracker://login-callback/`

## 🔗 Repositório Remoto

https://github.com/RafaelRodriguest/Movel-Tracker.git
