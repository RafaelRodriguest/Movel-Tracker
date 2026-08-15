# Expansão multi-estado (MA → PA, AM, RR, AP)

> Plano de implementação da branch `feat/Adic-others-UFs`.
> Replica todas as funcionalidades hoje disponíveis para o Maranhão (busca, fotos,
> edição operacional, mapas) para os estados PA, AM, RR e AP, escopando os dados por estado.

## Contexto

Hoje o Movel Tracker atende **apenas o Maranhão**. Toda a lógica já funciona, mas os
sites são **globais**: não existe campo de estado no model `Site`, na tabela `sites`
do Supabase, nem no cache. A tela de seleção de estado (`state_selection_screen.dart`)
já existe com 5 cards (MA ativo; PA/AM/RR/AP "em breve"), mas ainda não filtra por estado.

O objetivo é fazer cada card levar à mesma tela de pesquisa, agora escopada por estado.

### Decisões confirmadas

- **Escopo de dados:** nova coluna `uf` na tabela `sites` + campo no model.
- **Permissões:** mantidas globais (`cell_owner` edita qualquer estado; `geral` só vê).
- **Chaves operacionais:** listas orientadas a dados, por estado (preencher PA/AM/RR/AP depois).

### Estado atual (acoplamento MA já mapeado)

- Sem campo `uf`: `app/lib/models/site.dart`
- Fetch/cache globais: `app/lib/services/supabase_service.dart:7`, `app/lib/services/cache_service.dart:12`
- MA hardcoded: `app/lib/screens/home_screen.dart:350` (`', MA'`),
  `app/lib/screens/site_operacional_screen.dart:10-24` (opções de chave),
  mock em `app/lib/repositories/site_repository.dart:35-108`

---

## Fase 1 — Banco de dados (Supabase)

Executado manualmente pelo admin no Dashboard (convenção do projeto).

1. `ALTER TABLE sites ADD COLUMN uf text;`
2. Backfill: `UPDATE sites SET uf = 'MA' WHERE uf IS NULL;`
3. (Opcional) `CREATE INDEX idx_sites_uf ON sites(uf);`
4. RLS: **nenhuma mudança** — policies continuam globais. O filtro por `uf` é feito na query.
5. Convenção de valores: `'MA' | 'PA' | 'AM' | 'RR' | 'AP'` (sigla UF, maiúscula).

**Entregável:** coluna `uf` populada; sites MA marcados. Dados dos outros estados entram depois.

---

## Fase 2 — Model `Site`

Arquivo: `app/lib/models/site.dart`

- Adicionar campo **imutável** `final String uf;` (junto de `municipio`; **não** entra no `copyWith`).
- `fromJson`: `uf: json['uf'] ?? ''` (tolerante a linhas antigas).
- `toJson`: incluir `'uf': uf`.
- Construtor: `required this.uf` — atualizar os call sites (mock + testes) para explicitar o estado.

---

## Fase 3 — Camada de dados (fetch + cache por estado)

**`app/lib/services/supabase_service.dart`**
- `fetchSites({required String uf})` → `.from('sites').select().eq('uf', uf).order('nome')`.

**`app/lib/services/cache_service.dart`**
- Chave por estado: `_keyData(uf) => 'sites_cache_${uf}_v2'` e timestamp análogo
  (bump `v2` invalida o cache global antigo `sites_cache_v1`).
- `loadSites(uf)`, `saveSites(uf, sites)`, `clear(uf)` recebem `uf`.
- Reaproveitar o `compute(_parseSitesJson, raw)` já existente (fix de skipped frames).

**`app/lib/repositories/site_repository.dart`**
- `loadFromSupabase(uf)` — cache-first por estado, depois Supabase filtrado.
- `clearCache(uf)`.
- Mock: manter os 5 sites MA (com `uf: 'MA'`); demais estados retornam lista vazia no fallback.

---

## Fase 4 — `SiteProvider` (estado selecionado)

Arquivo: `app/lib/providers/site_provider.dart`

- Adicionar `String? _selectedUf;` + getter.
- **Remover o auto-load do construtor** (`Future.microtask(_loadSites)`): só carrega ao escolher estado.
- Novo `Future<void> selectUf(String uf)`: seta `_selectedUf`, limpa filtros, chama `_loadSites()`.
- `_loadSites()` passa `_selectedUf` ao repositório e ao mock.
- `refresh()` e `updateSiteImageUrls`/`updateSiteFields` invalidam o cache **do estado atual**.

---

## Fase 5 — Wiring da UI

**`app/lib/screens/state_selection_screen.dart`**
- No `onTap` do card: `context.read<SiteProvider>().selectUf(uf.sigla)` **antes** de `Navigator.push(... HomeScreen())`.
- Passar sigla/nome do estado para a `HomeScreen` (ex: `HomeScreen({required this.uf, required this.nomeEstado})`).
- Habilitar PA/AM/RR/AP (`disponivel: true`) conforme os dados forem carregados.

**`app/lib/screens/home_screen.dart`**
- Linha 350: trocar `'${site.municipio}, MA'` por `'${site.municipio}, ${site.uf}'`.
- Header: exibir o estado selecionado (ex: "Sites — Pará").

---

## Fase 6 — Opções operacionais por estado (data-driven)

Arquivos: `app/lib/screens/site_operacional_screen.dart` + `app/test/operacional_test.dart`

- Converter `_opcoesChave` em mapa por estado: `Map<String, List<String>> _opcoesChavePorUf`.
  MA mantém as opções atuais (`'MA GDA'`, `'MA GDV'`, ... + compartilhadas). Demais estados
  iniciam com a base compartilhada (`'NO CONT A'`, `'MULTLOCK'`, `'EBT TETRA'`...), a completar depois.
- A tela seleciona a lista pelo `site.uf`.
- `_opcoesFonte` e `_opcoesBaterias` permanecem globais.
- **Atualizar `operacional_test.dart`** (CLAUDE.md exige manter os dois arquivos em sincronia).

---

## Fase 7 — Testes e mock

- `app/test/site_test.dart`: cobrir `uf` em `fromJson`/`toJson`.
- `app/test/operacional_test.dart`: ajustar às opções por estado.
- Garantir que o mock MA tem `uf: 'MA'`.

---

## Arquivos-chave

| Camada | Arquivo |
|--------|---------|
| Model | `app/lib/models/site.dart` |
| Serviço | `app/lib/services/supabase_service.dart`, `app/lib/services/cache_service.dart` |
| Repositório | `app/lib/repositories/site_repository.dart` |
| Provider | `app/lib/providers/site_provider.dart` |
| Telas | `app/lib/screens/state_selection_screen.dart`, `app/lib/screens/home_screen.dart`, `app/lib/screens/site_operacional_screen.dart` |
| Testes | `app/test/site_test.dart`, `app/test/operacional_test.dart` |
| Banco | Supabase Dashboard (coluna `uf` + backfill) |

---

## Verificação (end-to-end)

1. `cd app && flutter analyze` — sem erros novos.
2. `flutter test` — `site_test.dart` e `operacional_test.dart` passam com `uf`.
3. `flutter run -d ZF523FT92Z` (debug):
   - Login → seleção → **MA** → lista só sites MA; label ", MA".
   - Busca e filtro por município funcionam dentro do MA.
   - Site → editar operacional → opções de chave do MA; salvar persiste.
   - Voltar → outro estado → lista do respectivo estado (ou "Nenhum site encontrado"), sem vazar sites.
4. Cache por estado isolado (`sites_cache_MA_v2` etc.).
5. `flutter run --release` — abertura rápida (sem regressão dos skipped frames).

---

## Fora de escopo

- Permissões por estado (mantidas globais).
- Carga real dos dados de PA/AM/RR/AP (via Dashboard, depois).
- Opções de chave específicas de PA/AM/RR/AP (estrutura pronta; valores a preencher).

---

## Progresso

- [ ] Fase 1 — Banco (coluna `uf` + backfill)
- [ ] Fase 2 — Model `Site`
- [ ] Fase 3 — Camada de dados (fetch + cache por estado)
- [ ] Fase 4 — `SiteProvider`
- [ ] Fase 5 — Wiring da UI
- [ ] Fase 6 — Opções operacionais por estado
- [ ] Fase 7 — Testes e mock
