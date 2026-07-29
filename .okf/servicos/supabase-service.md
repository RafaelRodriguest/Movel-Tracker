---
type: Serviço
title: SupabaseService
description: Camada de acesso ao Supabase — CRUD de sites, fotos, campos operacionais e audit log.
resource: lib/services/supabase_service.dart
tags: [supabase, crud, audit]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

`SupabaseService` é o único ponto de acesso ao banco Supabase. Expõe métodos para buscar e atualizar [sites](../dados/site.md), gerenciar fotos e registrar ações no `audit_log`.

`updateInformacoesOperacionais` sempre envia os 9 campos operacionais no UPDATE, mesmo que apenas um tenha mudado — evita lógica de diff e garante consistência. O [RLS](../acesso/rls.md) bloqueia silenciosamente UPDATEs sem policy explícita para `cell_owner`.

Usado pelo [SiteRepository](site-repository.md) para carregar sites e pelas telas de detalhe/operacional para persistir mudanças. Ver [Fluxo de Upload de Foto](../arquitetura/foto-upload-flow.md) e [Fluxo Operacional](../arquitetura/operacional-flow.md).

# Métodos Principais

| Método | Descrição |
|--------|-----------|
| `fetchSites()` | Carrega todos os sites da tabela `sites` |
| `updateFoto(siteId, index, url)` | Grava URL de foto e registra no audit_log |
| `updateInformacoesOperacionais(siteId, ...)` | Atualiza os 9 campos operacionais |
| `insertAuditLog(siteId, action, detail)` | Registra ação no audit_log |
