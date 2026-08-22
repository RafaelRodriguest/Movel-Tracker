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
  - `flutter_secure_storage: ^9.2.2` / `shared_preferences: ^2.3.0` — sessão segura e cache local
  - `http: ^1.2.2` / `csv: ^6.0.0` — legado Google Sheets (ainda presente mas não é a fonte primária)

## 🏗️ Arquitetura

### Estrutura de Diretórios

```
lib/
├── config/
│   └── env.dart                  # Credenciais: Supabase URL/anonKey, Cloudinary
├── models/
│   ├── site.dart                 # Modelo Site (imutável, copyWith com sentinel)
│   └── user_profile.dart         # Perfil do usuário (id, login, nome, email, role)
├── services/
│   ├── supabase_service.dart     # CRUD sites/fotos/operacional + insertAuditLog
│   ├── cloudinary_service.dart   # Upload de imagem para Cloudinary
│   └── data_service.dart         # Legado: Google Sheets CSV (fallback)
├── repositories/
│   └── site_repository.dart      # Carrega do Supabase; fallback mock local
├── providers/
│   ├── auth_provider.dart        # Sessão Supabase, login, logout, reset de senha
│   └── site_provider.dart        # Lista/filtros de sites; updateSiteImageUrls, updateSiteFields
├── screens/
│   ├── login_screen.dart         # Login com número de login + senha
│   ├── reset_password_screen.dart # Redefinição de senha via deep link
│   ├── home_screen.dart          # Lista, busca e filtro de sites
│   ├── site_detail_screen.dart   # Detalhes do site + gerenciamento de fotos
│   └── site_operacional_screen.dart # Edição de chaves, fontes, consumo e baterias
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
HomeScreen / SiteDetailScreen / SiteOperacionalScreen
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

### Fluxo de Edição Operacional

```
SiteOperacionalScreen (dropdowns + campos de texto)
    ↓
SupabaseService.updateInformacoesOperacionais(siteId, ...)
    + insertAuditLog(siteId, action: 'operacional_update')
    ↓
SiteProvider.updateSiteFields(siteId, updatedSite) — atualiza estado local
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
| `status` | String | `Ativo` ou `Desativado` |
| `foto_1`–`foto_5` | String? | URLs de imagem no Cloudinary |
| `chave_portao` | String? | Chave do portão (dropdown fixo) |
| `chave_gradil_01` / `chave_gradil_02` | String? | Chaves dos gradis |
| `fonte_01` / `fonte_02` | String? | Modelo de fonte (dropdown fixo) |
| `consumo_fonte_01` / `consumo_fonte_02` | String? | Consumo em texto livre |
| `baterias_fonte_01` / `baterias_fonte_02` | String? | Quantidade de baterias (1–9) |

As opções válidas de `chave_*` e `fonte_*` estão definidas como constantes em `site_operacional_screen.dart` e espelhadas em `operacional_test.dart`. Adicionar opções requer atualizar ambos os arquivos.

### Tabelas Supabase

- **`sites`** — dados dos sites (RLS: authenticated lê; cell_owner atualiza)
- **`profiles`** — perfil do usuário (`id`, `login`, `nome`, `email`, `role`)
- **`audit_log`** — registro de ações de foto (`user_id`, `site_id`, `action`, `detail`)

### Perfis de Acesso

| Role | Visualiza | Gerencia fotos | Edita operacional |
|------|:---------:|:--------------:|:-----------------:|
| `cell_owner` | ✅ | ✅ | ✅ |
| `geral` | ✅ | ❌ | ❌ |

Usuários são cadastrados **manualmente pelo admin** no Supabase Dashboard. Não há auto-cadastro no app. Somente domínios `@claro.com.br` e `@stte.com.br` são autorizados.

## 🔧 Configuração (`lib/config/env.dart`)

Credenciais hardcoded (não há `.env` separado):
- `Env.supabaseUrl` / `Env.supabaseAnonKey`
- `Env.cloudinaryCloudName` / `Env.cloudinaryUploadPreset`

## 🧪 Ambiente de desenvolvimento

Existe um projeto Supabase separado (`movel-tracker-dev`, free tier) para não desenvolver/testar direto em produção.

- **Entrypoint dev:** `flutter run -t lib/main_dev.dart` — usa `lib/config/env_dev.dart` (gitignored, mesmo tratamento de `env.dart`) e mostra uma fita "DEV" na tela (`ClaroSitesApp(isDev: true)`) para não confundir com o build de produção.
- **Entrypoint prod:** `flutter run` (usa `lib/main.dart` padrão, `env.dart`, sem fita).
- **Schema:** réplica do schema de produção, versionada em `supabase/migrations/`. Ao alterar o schema de produção, aplique a mesma migration no projeto dev.
- **Dados de teste:** sites fictícios (reaproveitados dos mocks locais) e dois usuários de teste, um por role (`cell_owner` e `geral`), cadastrados manualmente no projeto dev.
- **Cloudinary:** preset dedicado `movel_tracker_preset_dev` (unsigned), separado do preset de produção — mídia de teste não se mistura com a de produção.
- **Free tier do Supabase pausa projetos após 7 dias sem uso.** Se o projeto dev estiver pausado, `flutter run -t lib/main_dev.dart` vai falhar ao buscar do Supabase — o app já cai automaticamente no fallback de dados mock (`SiteRepository`), então continua utilizável para testar UI mesmo com o backend pausado. Para reativar, acesse o dashboard do projeto no Supabase.

## 🚀 Comandos de Desenvolvimento

Execute sempre a partir do diretório `app/`:

```bash
flutter pub get          # Instalar dependências
flutter run              # Rodar no dispositivo/emulador
flutter analyze          # Análise estática
flutter test             # Todos os testes
flutter test test/site_test.dart               # Testa Site.fromJson/toJson/ativo
flutter test test/operacional_test.dart        # Testa campos operacionais e sentinel copyWith
flutter test test/site_provider_test.dart      # Testa filtros e estado de SiteProvider
flutter test test/site_repository_test.dart    # Testa carga do Supabase + fallback mock
flutter test test/cloudinary_service_test.dart # Testa upload para Cloudinary
flutter test test/cache_service_test.dart      # Testa cache local de sites
flutter build apk --debug    # APK de debug
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/  # APK de produção (ofuscado)
flutter pub run flutter_launcher_icons  # Regenerar ícone do app
```

### 🔒 Build de release ofuscado

Todo build de release (`--release`) deve incluir `--obfuscate --split-debug-info=build/debug-info/` — sem isso, nomes de classes/métodos Dart ficam legíveis em `libapp.so` via engenharia reversa do APK. `build/debug-info/` é gerado localmente e não deve ser commitado (já coberto por `build/` no `.gitignore`) — guarde-o fora do repo (ex. artefato de CI) para poder desofuscar stack traces de crash depois:

```bash
flutter symbolize -i crash_report.txt -d build/debug-info/
```

O build de release é assinado com `android/key.properties` + `android/app/movel-tracker-release.jks` (ambos git-ignorados, nunca commitados). Sem esses arquivos localmente, o Gradle cai de volta para a keystore de debug — confira que `android/key.properties` existe antes de gerar um APK para distribuição.

## 🤖 CI

`.github/workflows/ci.yml` roda `flutter analyze` e `flutter test` a cada push/PR para `main`. Objetivo: pegar erro de análise estática ou teste quebrado antes do merge — não existe branch protection habilitada no GitHub (plano free + repo privado), então o CI é só sinal visual (checagem verde/vermelha no PR/commit), não bloqueio automático. Antes de dar merge numa branch, confira se o CI passou.

`.github/workflows/keep-supabase-alive.yml` faz ping periódico nos projetos Supabase (prod e dev) para evitar a pausa automática por 7 dias sem uso do free tier.

## 🗄️ Migrations do Supabase

Toda alteração de **schema** em produção (nova tabela, coluna, índice, policy RLS) deve virar um arquivo versionado em `supabase/migrations/`, nunca só colada direto no SQL Editor do dashboard:

```bash
supabase migration new nome_da_mudanca   # cria supabase/migrations/<timestamp>_nome_da_mudanca.sql
# editar o arquivo gerado com o DDL
supabase db push --linked                # aplica em produção
```

Isso mantém `supabase/migrations/` como fonte da verdade do schema — sem isso, não dá pra saber o que rodou em produção nem replicar a mudança no projeto dev. Ao alterar o schema de produção, aplique a mesma migration no projeto dev (`supabase link` pro projeto dev e `db push` lá também).

**Carga de dados em massa** (ex.: importação de CSV de sites novos) é diferente de mudança de schema — pode continuar sendo feita via SQL Editor ou script, já que não é algo que faz sentido versionar como migration. Mas documente o que foi feito (memória do projeto ou commit) para rastreabilidade.

Para checar se o schema de produção bateu com o último migration versionado: `supabase db dump --linked --schema public -f /tmp/schema_atual.sql` e comparar com o arquivo de migration mais recente.

## Documentação Adicional

- **`DADOS.md`** — onde os dados dos sites ficam armazenados, como o app os busca e como são cacheados no dispositivo.
- **`SKILS.md/`** — notas específicas por tópico: `authentication.md`, `upload-image.md`, `key-sources-consumption.md`, `supabase-migration.md`, `multi-estado-expansion.md`, `import-csv-multi-estado.md`.

## Padrões de Código

### Sentinel em `Site.copyWith`

Os campos operacionais de `Site` usam um sentinel privado (`_omit`) em vez do padrão `T? param` do Dart. Isso permite distinguir "parâmetro não informado" (mantém valor atual) de "null explícito" (limpa o campo no banco):

```dart
// Preserva chavePortao atual — não passa o parâmetro
site.copyWith(fonte01: 'ELTEK 2500');

// Limpa chavePortao no banco — passa null explicitamente
site.copyWith(chavePortao: null);
```

Ao adicionar novos campos nullable a `Site`, use `Object? campo = _omit` no `copyWith`, não `String? campo`.

`copyWith` cobre apenas `imageUrls` e os campos operacionais. Os campos imutáveis do site (siteId, nome, sigla, lat/lng, etc.) não são parâmetros do `copyWith` — para alterá-los, construa um novo `Site(...)` diretamente.

### `updateInformacoesOperacionais` envia todos os campos

`SupabaseService.updateInformacoesOperacionais` sempre envia os 9 campos operacionais no UPDATE, mesmo que apenas um tenha mudado. Isso é intencional — evita lógica de diff e garante consistência. O RLS do Supabase bloqueia silenciosamente UPDATEs sem policy explícita para `cell_owner`.

### `imageUrls` tem tamanho fixo 5

`Site.imageUrls` é sempre uma lista de comprimento 5 (preenchida com `null`). Ao indexar, use `imageUrls[0]`–`imageUrls[4]` diretamente.

## 📂 Avisos Importantes

- **`data_service.dart`** — código legado do Google Sheets. A fonte ativa é o Supabase via `supabase_service.dart`.
- **Deep link** de reset de senha: `com.claro.moveltracker://login-callback/`
- **`SiteProvider.getSiteById`** delega ao `SiteRepository`, que não reflete atualizações feitas via `updateSiteFields`. Para buscar o estado vivo de um site, use `provider.allSites.firstWhere((s) => s.siteId == id)`.

## 🌿 Workflow Git

Branch base: `main` (produção). Nunca commitar diretamente nela.

### Nomenclatura de branches

| Prefixo | Quando usar | Exemplo |
|---------|-------------|---------|
| `feat/` | Nova funcionalidade | `feat/offline-mode` |
| `fix/`  | Correção de bug | `fix/foto-upload-null` |
| `chore/`| Infra, deps, docs, CI | `chore/update-supabase-sdk` |

Sempre kebab-case, sem maiúsculas.

### Fluxo

```bash
git checkout main && git pull          # partir do main atualizado
git checkout -b feat/nome-da-feature   # criar branch

# ... desenvolver, commitar ...

git checkout main
git merge --no-ff feat/nome-da-feature # merge sem fast-forward
git push origin main
git branch -d feat/nome-da-feature     # deletar branch local após merge
```

### Mensagens de commit

Seguir Conventional Commits em português:

```
feat: adicionar filtro por município na home
fix: corrigir upload de foto quando URL é null
chore: remover gradle cache do rastreamento git
test: cobrir casos edge do sentinel copyWith
```

## 🔗 Repositório Remoto

https://github.com/RafaelRodriguest/Movel-Tracker.git
