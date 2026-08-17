# Importar o CSV multi-estado no Supabase (Fase 1)

> Passo a passo manual no Dashboard do Supabase para adicionar a coluna `uf` e
> carregar a planilha com os sites de MA, PA, AM, RR e AP.
> Fase 1 do plano em `multi-estado-expansion.md` — o código das Fases 2–7 já está pronto
> e depende **apenas** da coluna `uf` existir e estar preenchida.

## Colunas do CSV

```
site_id, uf, sigla, nome, endereco, municipio, tecnico, latitude, longitude, detentora, uc, status
```

A `uf` é a **coluna B** da planilha. A posição não importa para o importador do
Supabase (ele casa pelo **nome do cabeçalho**), mas o cabeçalho precisa ser
exatamente `uf`, minúsculo.

Uma ausência em relação à tabela `sites`, tolerada pelo app:

| Coluna | Situação |
|--------|----------|
| `tecnologias` | Não existe no CSV — fica `null`; `Site.fromJson` converte para lista vazia |

---

## Passo 1 — Adicionar a coluna `uf` e fazer o backfill do MA

**Dashboard → SQL Editor → New query:**

```sql
alter table sites add column if not exists uf text;

-- Todo o dado que já existe hoje é do Maranhão
update sites set uf = 'MA' where uf is null;

-- Busca do app é sempre .eq('uf', ...) — o índice evita full scan
create index if not exists sites_uf_idx on sites (uf);
```

Conferir:

```sql
select uf, count(*) from sites group by uf;
```

Deve retornar uma linha só: `MA | <total atual>`.

---

> **Atalho — foi assim que AM/PA/RR/AP entraram (2026-08-17).** Em vez dos passos
> 2–7, o CSV foi convertido offline em arquivos `.sql` com os `insert ... on
> conflict` prontos, colados direto no SQL Editor. Some a staging, o `\copy`, a
> connection string e os problemas de encoding/separador — a conversão trata
> ISO-8859-1, `;`, vírgula decimal e `status` minúsculo de uma vez, e aborta em
> `site_id` duplicado, UF inesperada ou coordenada não numérica. Só o passo 1
> continua obrigatório. Divida em arquivos de ~500 linhas: acima disso o editor
> do navegador engasga. Os passos 2–7 abaixo seguem válidos como alternativa.

## Passo 2 — Criar a tabela de staging

Importar direto na `sites` é arriscado: `site_id` é `unique` (re-importar o MA
quebraria) e latitude/longitude podem vir com vírgula decimal. A staging é toda
`text`, aceita qualquer coisa, e permite conferir antes de mesclar.

```sql
create table sites_import (
  site_id   text,
  uf        text,
  sigla     text,
  nome      text,
  endereco  text,
  municipio text,
  tecnico   text,
  latitude  text,
  longitude text,
  detentora text,
  uc        text,
  status    text
);

alter table sites_import enable row level security;  -- sem policy: invisível ao app
```

---

## Passo 3 — Importar o CSV

**Dashboard → Table Editor → `sites_import` → Insert → Import data from CSV.**

O importador casa as colunas pelo **nome do cabeçalho** — mantenha o cabeçalho do
CSV exatamente como listado acima (minúsculas, sem acento).

> Se o Excel salvou com `;` como separador, reexporte como "CSV UTF-8 (delimitado
> por vírgula)". Acentos errados na prévia = arquivo não está em UTF-8.

Conferir a contagem:

```sql
select count(*) from sites_import;
```

---

## Passo 4 — Normalizar e conferir a `uf`

A UF vem do próprio CSV, então aqui não há derivação — só limpeza e conferência.

```sql
update sites_import set uf = upper(trim(uf));
```

Ver o que entrou:

```sql
select uf, count(*) from sites_import group by uf order by uf;
```

Só siga se o resultado for exatamente `MA / PA / AM / RR / AP`. Sobra típica:
célula vazia (vira `''`, não `null`), UF com espaço ou minúscula (resolvidas pelo
`update` acima) e siglas de estados que ainda não estão no app.

Cruzamento opcional — se a `sigla` seguir o padrão do MA (`MASLS7`, `MAITZ2`:
dois primeiros caracteres = UF), esta query aponta divergências entre a coluna
nova e a sigla, que costumam ser erro de digitação na planilha:

```sql
select site_id, sigla, uf, upper(left(sigla, 2)) as uf_da_sigla
from sites_import
where uf is distinct from upper(left(sigla, 2));
```

Corrigir uma linha específica, se for o caso:

```sql
update sites_import set uf = 'PA' where site_id = 'XXX000';
```

---

## Passo 5 — Validar antes de mesclar

```sql
-- 1. Nenhuma linha sem UF (null ou vazia) nem com UF fora das 5 esperadas
select site_id, sigla, uf from sites_import
where coalesce(uf, '') not in ('MA', 'PA', 'AM', 'RR', 'AP');

-- 2. site_id duplicado dentro do próprio CSV
select site_id, count(*) from sites_import group by site_id having count(*) > 1;

-- 3. Coordenadas que não convertem para número (vírgula decimal, vazio, texto)
select site_id, latitude, longitude from sites_import
where replace(coalesce(latitude,  ''), ',', '.') !~ '^-?[0-9]+\.?[0-9]*$'
   or replace(coalesce(longitude, ''), ',', '.') !~ '^-?[0-9]+\.?[0-9]*$';

-- 4. site_id que já existe na tabela sites (serão atualizados, não inseridos)
select i.site_id from sites_import i join sites s using (site_id);
```

A query 3 pode retornar linhas legitimamente vazias — o `nullif` do passo 6
transforma essas em `null`, e o app trata como coordenada `0.0`.

---

## Passo 6 — Mesclar na tabela `sites`

O `replace(...,',','.')` cobre vírgula decimal; o `on conflict` atualiza o site em
vez de falhar, e **não sobrescreve as fotos nem os campos operacionais** (esses
não aparecem no `update set`).

```sql
insert into sites (
  site_id, sigla, nome, endereco, municipio, uf,
  tecnico, latitude, longitude, detentora, uc, status
)
select
  site_id,
  sigla,
  nome,
  endereco,
  municipio,
  upper(uf),
  tecnico,
  nullif(replace(latitude,  ',', '.'), '')::double precision,
  nullif(replace(longitude, ',', '.'), '')::double precision,
  detentora,
  uc,
  initcap(coalesce(nullif(status, ''), 'Ativo'))
from sites_import
on conflict (site_id) do update set
  sigla     = excluded.sigla,
  nome      = excluded.nome,
  endereco  = excluded.endereco,
  municipio = excluded.municipio,
  uf        = excluded.uf,
  tecnico   = excluded.tecnico,
  latitude  = excluded.latitude,
  longitude = excluded.longitude,
  detentora = excluded.detentora,
  uc        = excluded.uc,
  status    = excluded.status;
```

Conferir:

```sql
select uf, count(*) from sites group by uf order by uf;
select count(*) from sites where uf is null;  -- precisa ser 0
```

---

## Passo 7 — Limpar

```sql
drop table sites_import;
```

---

## Passo 8 — Habilitar os estados no app ✅ feito

Só depois que o passo 6 fechar. Em `app/lib/screens/state_selection_screen.dart`,
trocar `disponivel: false` por `true` nos estados carregados — os cinco já estão
habilitados desde a carga de 2026-08-17 (1481 sites: AM 448, PA 849, RR 83, AP 101):

```dart
const _ufs = <_UF>[
  _UF(sigla: 'MA', nome: 'Maranhão', disponivel: true),
  _UF(sigla: 'PA', nome: 'Pará', disponivel: true),
  _UF(sigla: 'AM', nome: 'Amazonas', disponivel: true),
  _UF(sigla: 'RR', nome: 'Roraima', disponivel: true),
  _UF(sigla: 'AP', nome: 'Amapá', disponivel: true),
];
```

E, quando as chaves físicas de cada estado forem levantadas, preencher
`_opcoesChavePorUf` em `app/lib/screens/site_operacional_screen.dart` (hoje só o
MA tem lista própria; os demais caem em `_opcoesChaveBase`) — espelhando em
`app/test/operacional_test.dart`, como exige o CLAUDE.md.

---

## Observações

- **RLS:** as policies da `sites` continuam globais — `cell_owner` edita qualquer
  estado, `geral` só lê. Nada muda com a coluna `uf`.
- **Cache:** o app usa `sites_cache_<UF>_v2`. O bump de versão já invalida o cache
  global antigo, então nenhum aparelho vai abrir com dados pré-`uf`.
- **`tecnologias` vazio:** os sites importados não exibirão chips de tecnologia até
  a coluna ser preenchida. Para carregar depois, um `update ... from` com um
  segundo CSV resolve.
