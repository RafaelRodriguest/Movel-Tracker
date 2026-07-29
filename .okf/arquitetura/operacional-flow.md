---
type: Fluxo
title: Fluxo Operacional
description: Edição de chaves, fontes, consumo e baterias com envio completo de campos ao Supabase.
tags: [operacional, supabase, sentinel]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

```
SiteOperacionalScreen (dropdowns + campos de texto)
    ↓
SupabaseService.updateInformacoesOperacionais(siteId, ...)
    + insertAuditLog(siteId, action: 'operacional_update')
    ↓
SiteProvider.updateSiteFields(siteId, updatedSite) — atualiza estado local
```

`updateInformacoesOperacionais` sempre envia os 9 campos operacionais no UPDATE, mesmo que apenas um tenha mudado. Isso é intencional — evita lógica de diff e garante consistência.

O modelo [Site](../dados/site.md) usa o padrão sentinel em `copyWith` para distinguir "não informado" (mantém valor) de `null` explícito (limpa o campo). Somente `cell_owner` pode editar — ver [Perfis de Acesso](../acesso/roles.md) e [RLS](../acesso/rls.md).

# Campos Operacionais

| Campo | Tipo | Opções |
|-------|------|--------|
| `chave_portao` | dropdown | constantes em `site_operacional_screen.dart` |
| `chave_gradil_01/02` | dropdown | idem |
| `fonte_01/02` | dropdown | idem |
| `consumo_fonte_01/02` | texto livre | — |
| `baterias_fonte_01/02` | dropdown | 1–9 |
