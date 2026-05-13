# Plano de Otimização — Movel Tracker

Foco nos 20% de ações que entregam 80% do resultado.
Sem otimizações prematuras, sem risco de quebrar o que já funciona.

---

## O que já está correto e não deve ser tocado

- `imageQuality: 65, maxWidth/Height: 800` antes do upload — compressão adequada para campo
- Delete-on-replace via Edge Function — evita arquivos órfãos no Cloudinary
- `CachedNetworkImage` — cache local de imagens já ativo
- Sentinel pattern em `Site.copyWith` — não alterar
- `updateInformacoesOperacionais` enviando os 9 campos — comportamento intencional documentado
- Fallback mock local em `SiteRepository` — proteção de campo, manter

---

## Ação 1 — Transformações de URL no Cloudinary
**Impacto: alto | Esforço: ~2h | Risco: zero**

### Problema
O slot de 96×96 px em `SiteDetailScreen` carrega a imagem original (até 800×800 px).
`_viewPhoto()` também carrega sem limite de resolução.
Resultado: banda desperdiçada no dispositivo e nos créditos do Cloudinary a cada visualização.

### Solução
Adicionar dois métodos estáticos em `CloudinaryService` que inserem parâmetros de
transformação na URL antes de `/upload/` — sem tocar em nenhuma outra lógica do app.

```dart
// cloudinary_service.dart — adicionar abaixo de extractPublicId()

static String thumbnailUrl(String url) =>
    _withTransform(url, 'w_200,h_200,c_fill,q_auto,f_auto');

static String fullViewUrl(String url) =>
    _withTransform(url, 'w_1200,q_auto,f_auto');

static String _withTransform(String url, String transform) {
  const marker = '/upload/';
  final i = url.indexOf(marker);
  if (i == -1) return url;
  return '${url.substring(0, i + marker.length)}$transform/${url.substring(i + marker.length)}';
}
```

### Onde aplicar
- `site_detail_screen.dart:998` — `_buildPhotoSlot()`: usar `CloudinaryService.thumbnailUrl(url)`
- `site_detail_screen.dart:234` — `_viewPhoto()`: usar `CloudinaryService.fullViewUrl(url)`

### Por que não quebra nada
- `extractPublicId()` já ignora prefixos de versão/transformação — continua funcionando
- URL fora do Cloudinary: `_withTransform` retorna original sem falhar
- Nenhum modelo, provider ou serviço é alterado

### Impacto esperado
| | Antes | Depois |
|---|---|---|
| Thumbnail (slot 96px) | ~400–800 KB por imagem | ~15–30 KB por imagem |
| Visualização full | ~400–800 KB | ~100–200 KB |
| Formato | JPEG/PNG | WebP (Android) via `f_auto` |

---

## Ação 2 — Anti-pausa: keep-alive semanal via GitHub Actions
**Impacto: crítico | Esforço: 20 min | Risco: zero (externo ao app)**

### Problema
O plano gratuito do Supabase **pausa o projeto automaticamente após 7 dias sem requisições**.
Se os técnicos ficarem sem usar o app por mais de uma semana (férias, feriado prolongado,
período sem campo), o banco dorme. Na primeira abertura após a pausa, o app leva ~20–30s
para "acordar" — e parece quebrado para o usuário.

**Este é o maior risco operacional do plano gratuito — não o storage.**

> O banco armazena apenas texto (URLs, nomes, coordenadas). As imagens ficam no Cloudinary.
> Com ~100–500 sites e equipe pequena, o banco mal chegaria a 10 MB em anos de uso.
> Storage não é o risco real aqui.

### Solução
Criar um workflow no GitHub Actions que faz um ping simples no Supabase toda semana.

**Criar `.github/workflows/supabase-keepalive.yml`:**

```yaml
name: Supabase Keep-Alive

on:
  schedule:
    - cron: '0 8 * * 1'  # toda segunda-feira às 8h UTC
  workflow_dispatch:       # permite rodar manualmente se necessário

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Supabase
        run: |
          curl -s -o /dev/null -w "%{http_code}" \
            "${{ secrets.SUPABASE_URL }}/rest/v1/sites?select=site_id&limit=1" \
            -H "apikey: ${{ secrets.SUPABASE_ANON_KEY }}" \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}"
```

**Configurar secrets no GitHub:** Settings → Secrets → Actions → New repository secret
- `SUPABASE_URL` → valor de `Env.supabaseUrl` (`lib/config/env.dart`)
- `SUPABASE_ANON_KEY` → valor de `Env.supabaseAnonKey` (`lib/config/env.dart`)

### Por que não quebra nada
Completamente externo ao app — não altera código, modelos ou telas.
A query `select=site_id&limit=1` é a leitura mais leve possível: 1 campo, 1 linha.

---

## Ação 3 — Limpeza automática do audit_log
**Impacto: preventivo | Esforço: 15 min | Risco: zero (sem código no app)**

### Problema
`insertAuditLog()` é chamado em toda operação de foto e update operacional.
Com ~10 operações/dia a tabela acumula ~3.600 linhas/ano. Não é urgente hoje,
mas sem nenhuma limpeza cresce indefinidamente — melhor resolver antes de virar problema.

### Solução
Executar no **SQL Editor do Supabase Dashboard** uma única vez:

```sql
-- Habilitar extensão se necessário: Database → Extensions → pg_cron → Enable

select cron.schedule(
  'cleanup-audit-log',
  '0 3 * * 0',  -- todo domingo às 3h
  $$
    delete from audit_log
    where created_at < now() - interval '90 days';
  $$
);
```

### Por que não quebra nada
Operação exclusivamente no banco — zero alterações no código do app.
90 dias de histórico é suficiente para qualquer auditoria operacional.

---

## Ação 4 — Cache local de sites com TTL
**Impacto: alto | Esforço: ~4h | Risco: baixo (com fallback preservado)**

### Problema
`SiteRepository.loadFromSupabase()` vai ao banco a cada abertura do app, sem cache.
Técnicos de campo abrem o app várias vezes ao dia — os dados de sites mudam raramente.
Cada abertura gera uma leitura completa da tabela desnecessariamente.

### Solução
Salvar o resultado de `fetchSites()` localmente com `shared_preferences` e um timestamp.
Na próxima abertura, usar o cache se tiver menos de 30 minutos.

**Fluxo:**
```
loadFromSupabase() chamado
  ├─ cache existe e tem < 30 min → retorna do cache (zero requisição ao Supabase)
  └─ cache vencido ou ausente    → busca Supabase → salva cache com timestamp → retorna
```

**Pontos críticos de implementação:**
- Fallback mock deve continuar funcionando: cache miss + Supabase offline = mock local
- Serializar com `jsonEncode(sites.map((s) => s.toJson()).toList())` — `toJson()` já existe em `Site`
- `SiteProvider.refresh()` deve invalidar o cache antes de re-fetch
- TTL de 30 min é conservador; pode aumentar para 2h na prática

**Dependência a adicionar:** `shared_preferences: ^2.3.x` em `pubspec.yaml`

---

## Ordem de execução recomendada

| # | Ação | Esforço | Impacto |
|:---:|---|:---:|---|
| 1 | **Ação 2** — Keep-alive Supabase | 20 min | Crítico — evita pausa inesperada do banco |
| 2 | **Ação 3** — Limpeza audit_log | 15 min | Preventivo — zero crescimento do banco |
| 3 | **Ação 1** — Cloudinary URL transforms | 2h | Alto — reduz banda de imagens ~90% |
| 4 | **Ação 4** — Cache local TTL | 4h | Alto — reduz leituras ao Supabase ~83% |

Ações 2 e 3 ficam primeiro por serem no Supabase Dashboard — zero código, zero risco, executáveis agora.

---

## O que NÃO fazer

| Ideia | Motivo |
|---|---|
| SELECT com colunas explícitas | Prematura — só importa se colunas internas forem adicionadas ao banco |
| Remover `fetchSiteFotos()` | Prematura — baixo impacto, requer verificação de call sites |
| CacheManager customizado de disco | Prematura — com Ação 1 reduzindo tamanho, o default é suficiente |
| Limitar `imageCache` em RAM | Prematura — só relevante se houver relatos de lentidão em campo |
| Supabase Realtime | Aumenta conexões concorrentes — desnecessário para este caso de uso |
| Supabase Storage para imagens | Cloudinary já cobre; misturar duplica complexidade e consumo |
| Diff de campos em `updateInformacoesOperacionais` | Comportamento intencional documentado — risco de quebrar RLS |

---

## Projeção de impacto

| Recurso | Antes | Após ações 1+2+3+4 | Limite free |
|---|---|---|---|
| Cloudinary bandwidth/mês | ~600 KB × N views | ~25 KB thumb / ~150 KB full | ~1 GB/mês |
| Supabase reads/mês | ~900 (30 acessos/dia) | ~150 (cache 30 min) | sem limite rígido |
| Supabase DB storage | ~5 MB + crescendo | ~5 MB + estável (TTL 90d) | 500 MB |
| Supabase disponibilidade | Pausa após 7 dias sem uso | Sempre ativo (keep-alive semanal) | — |

Com essas 4 ações, o plano gratuito suporta 300–500 sites e vários anos de operação
sem risco de atingir nenhum limite ou sofrer pausa inesperada.
