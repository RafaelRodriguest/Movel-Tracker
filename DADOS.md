# Fonte de Dados — Sites Claro

Este documento descreve onde os dados dos sites ficam armazenados, como o aplicativo os busca e como eles são mantidos em cache no dispositivo.

---

## 📍 Local de Armazenamento

**Supabase (Postgres)** — tabela `sites`. É a única fonte de dados de produção.

Os dados de todos os estados vivem na **mesma tabela**, separados pela coluna `uf`. O app nunca carrega a tabela inteira: a query filtra pelo estado escolhido na tela de seleção (`state_selection_screen.dart`).

Estados habilitados hoje: **MA**, **PA**, **AM**, **RR**, **AP**.

Credenciais em `app/lib/config/env.dart` (`Env.supabaseUrl`, `Env.supabaseAnonKey`).

---

## 📊 Estrutura da Tabela `sites`

### Identificação e localização

| Coluna | Descrição | Exemplo | Tipo |
|--------|-----------|---------|------|
| `site_id` | Identificador único do site | `SLZ001` | text (PK) |
| `sigla` | Sigla/nome técnico do site | `MASLS7` | text |
| `nome` | Nome descritivo | `São Luís Centro` | text |
| `endereco` | Endereço completo | `Av. Dom Pedro II, Centro` | text |
| `municipio` | Município (sem UF) | `São Luís` | text |
| `uf` | Sigla do estado — escopa a busca | `MA` | text |
| `tecnico` | Técnico responsável | `João Silva` | text |
| `latitude` | Coordenada latitude | `-2.5297` | double |
| `longitude` | Coordenada longitude | `-44.3028` | double |
| `detentora` | Proprietário da torre | `ATC` | text |
| `uc` | Unidade Consumidora | `12345678` | text |
| `status` | `Ativo` ou `Desativado` | `Ativo` | text |

### Fotos

| Coluna | Descrição | Tipo |
|--------|-----------|------|
| `foto_1` … `foto_5` | URLs das imagens no Cloudinary | text (nullable) |

### Campos operacionais

Editáveis no app por usuários `cell_owner`, via `site_operacional_screen.dart`.

| Coluna | Descrição | Tipo |
|--------|-----------|------|
| `chave_portao` | Chave do portão (dropdown fixo) | text (nullable) |
| `chave_gradil_01` / `chave_gradil_02` | Chaves dos gradis | text (nullable) |
| `fonte_01` / `fonte_02` | Modelo da fonte (dropdown fixo) | text (nullable) |
| `consumo_fonte_01` / `consumo_fonte_02` | Consumo (texto livre) | text (nullable) |
| `baterias_fonte_01` / `baterias_fonte_02` | Quantidade de baterias (1–9) | text (nullable) |

As opções válidas dos dropdowns são constantes em `site_operacional_screen.dart` e estão espelhadas em `app/test/operacional_test.dart` — adicionar opção exige atualizar os dois arquivos.

### Tabelas de apoio

| Tabela | Conteúdo |
|--------|----------|
| `profiles` | `id`, `login`, `nome`, `email`, `role` (`cell_owner` \| `geral`) |
| `audit_log` | `user_id`, `site_id`, `action`, `detail` — trilha de fotos e edições operacionais |

---

## 📱 Como o Aplicativo Busca os Dados

### Fluxo de carregamento

```
StateSelectionScreen (usuário escolhe a UF)
    ↓
SiteProvider.selectUf(uf)
    ↓
SiteRepository.loadFromSupabase(uf)
    ├── 1. CacheService.loadSites(uf) — cache válido? retorna e não toca no Supabase
    ├── 2. SupabaseService.fetchSites(uf: uf) — cache miss/expirado
    │      └── grava no cache via CacheService.saveSites(uf, sites)
    └── 3. null (rede caiu e cache vazio)
           └── SiteProvider cai em SiteRepository.loadMockData(uf)
```

A carga **não** acontece no construtor do provider — antes da escolha do estado não há o que buscar.

### A query

`app/lib/services/supabase_service.dart:11`

```dart
await _client.from('sites').select().eq('uf', uf).order('nome');
```

O `select()` sem argumentos traduz para `select *`. Por isso o app tolera colunas extras no retorno: o `Site.fromJson` só lê as chaves que conhece e ignora o resto.

### Cache local

`app/lib/services/cache_service.dart` — `shared_preferences`, escopado por estado:

| Aspecto | Valor |
|---------|-------|
| Chaves | `sites_cache_<UF>_v2` e `sites_cache_ts_<UF>_v2` |
| TTL | 30 minutos |
| Serialização | `Site.toJson()` → JSON; parse de volta em isolate (`compute`) |
| Corrupção | parse falha → limpa a chave e força re-fetch |

O sufixo `_v2` marca o cache escopado por UF; o bump invalidou o cache global `v1`, que não tinha o campo `uf`.

**Invalidação:** `SiteProvider.refresh()` (pull-to-refresh) limpa antes de recarregar, e toda escrita no Supabase — `updateSiteImageUrls` e `updateSiteFields` — dispara `clearCache(uf)` em background, para o próximo cold start pegar dados frescos.

### Fallback mock

`SiteRepository._mockPorUf` tem 5 sites de exemplo, todos do MA. É a última linha de defesa quando cache e Supabase falham; estados sem mock cadastrado ficam com lista vazia.

---

## ✍️ Como os Dados Entram no Banco

Não há cadastro de sites pelo app — a carga é feita por SQL no **SQL Editor** do Supabase, a partir do CSV de sites.

O gerador de SQL a partir do CSV e o procedimento completo de importação estão em **`SKILS.md/import-csv-multi-estado.md`**.

Usuários também são cadastrados manualmente pelo admin no Dashboard do Supabase (não há auto-cadastro). Apenas domínios `@claro.com.br` e `@stte.com.br` são autorizados.

---

## 🔒 Segurança

- **RLS ativo** na tabela `sites`: `authenticated` lê; apenas `cell_owner` atualiza.
- As policies de RLS são **globais**, não por estado — o recorte por `uf` é feito na query, não no banco. Ver `SKILS.md/multi-estado-expansion.md`, Fase 1.
- Um `UPDATE` sem policy explícita é **bloqueado silenciosamente** pelo Supabase: retorna sucesso e não grava nada.
- A `anonKey` no cliente é pública por design — o que protege os dados é o RLS, não o segredo da chave.

---

## 🗄️ Legado: Google Sheets

`app/lib/services/data_service.dart` ainda contém o leitor de CSV do Google Sheets usado antes da migração para o Supabase. **Não tem nenhum call site no app** — está no repositório como referência histórica.

Duas ressalvas para quem for reaproveitá-lo:

- A lista de colunas em `_rowToMap` (`data_service.dart:98`) não inclui `uf` — sites vindos desse caminho nascem com `uf: ''` e não aparecem em nenhuma seleção de estado.
- A URL da planilha está hardcoded e aponta para a planilha original do Maranhão.

O histórico da migração Sheets → Supabase está em `SKILS.md/supabase-migration.md`.

---

## 📋 Modelo de Dados (Dart)

`app/lib/models/site.dart` — classe imutável. Além dos campos das tabelas acima:

- **`imageUrls`** — as 5 colunas `foto_*` viram uma lista de tamanho **fixo 5**, preenchida com `null`. Índices `[0]`–`[4]` podem ser usados direto, sem checar comprimento.
- **`copyWith` com sentinel** — os campos operacionais usam `Object? campo = _omit` em vez de `String? campo`, para distinguir "não informado" (mantém o valor atual) de "`null` intencional" (limpa a coluna). Só `imageUrls` e os campos operacionais são parâmetros do `copyWith`; para alterar os campos imutáveis, construa um `Site(...)` novo.
- **Tolerância de parse** — `_parseCoordinate` aceita `double` (Supabase) ou `String` com vírgula ou ponto (CSV); `uf` ausente vira `''`, o que mantém compatibilidade com linhas antigas e com cache `v1`.
