# Importar o CSV multi-estado no Supabase (Fase 1)

> Passo a passo manual no Dashboard do Supabase para adicionar a coluna `uf` e
> carregar a planilha com os sites de MA, PA, AM, RR e AP.
> Fase 1 do plano em `multi-estado-expansion.md` — o código das Fases 2–7 já está pronto
> e depende **apenas** da coluna `uf` existir e estar preenchida.

## Colunas do CSV

```
site_id, sigla, nome, endereco, municipio, tecnico, latitude, longitude, detentora, uc, status
```

Duas ausências em relação à tabela `sites`, ambas toleradas pelo app:

| Coluna | Situação |
|--------|----------|
| `uf` | **Não existe no CSV** — precisa ser derivada ou adicionada (passo 3) |
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

## Passo 2 — Criar a tabela de staging

Importar direto na `sites` é arriscado: `site_id` é `unique` (re-importar o MA
quebraria) e latitude/longitude podem vir com vírgula decimal. A staging é toda
`text`, aceita qualquer coisa, e permite conferir antes de mesclar.

```sql
create table sites_import (
  site_id   text,
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

## Passo 4 — Definir a `uf` de cada linha

O CSV não traz o estado, então ele precisa sair de algum lugar. **Escolha uma das
opções abaixo** — a A é a mais confiável se a `sigla` seguir o padrão do MA
(`MASLS7`, `MAITZ2`, `MACXS4`: dois primeiros caracteres = UF).

### Opção A — derivar dos 2 primeiros caracteres da `sigla`

Primeiro **confira** o que isso produziria, sem gravar nada:

```sql
select upper(left(sigla, 2)) as uf_derivada, count(*)
from sites_import
group by 1
order by 2 desc;
```

Só siga se o resultado for exatamente `MA / PA / AM / RR / AP`. Qualquer outro
valor (ou `null`) significa que há siglas fora do padrão — trate-as antes.

```sql
alter table sites_import add column uf text;
update sites_import set uf = upper(left(sigla, 2));
```

### Opção B — informar a UF no próprio CSV (mais seguro)

Adicione uma coluna `uf` na planilha, preenchida por linha, antes de importar —
e inclua `uf text` no `create table sites_import` do passo 2. Nada a fazer aqui.

### Opção C — um CSV por estado

Importe um arquivo de cada vez e, entre cada importação, carimbe as linhas novas:

```sql
update sites_import set uf = 'PA' where uf is null;
```

---

## Passo 5 — Validar antes de mesclar

```sql
-- 1. Nenhuma linha sem UF, e só as 5 UFs esperadas
select uf, count(*) from sites_import group by uf order by uf;

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
  coalesce(nullif(status, ''), 'Ativo')
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

## Passo 8 — Habilitar os estados no app

Só depois que o passo 6 fechar. Em `app/lib/screens/state_selection_screen.dart`,
trocar `disponivel: false` por `true` nos estados carregados:

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
