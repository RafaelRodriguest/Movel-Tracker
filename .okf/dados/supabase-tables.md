---
type: Recurso
title: Tabelas Supabase
description: Três tabelas principais do banco — sites, profiles e audit_log — com RLS ativo.
resource: supabase://moveltracker
tags: [supabase, banco-de-dados, rls]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

O banco Supabase do Movel Tracker tem três tabelas. Todas operam com Row Level Security ativo — ver [RLS](../acesso/rls.md).

O acesso é feito pelo [SupabaseService](../servicos/supabase-service.md).

# Schema

## sites
Dados dos sites de telecomunicação. RLS: autenticados leem; `cell_owner` atualiza.
Ver campos completos em [Site](site.md).

## profiles
Perfil dos usuários. Populado manualmente pelo admin.
Ver [UserProfile](user-profile.md).

| Campo | Tipo |
|-------|------|
| `id` | UUID (= auth.uid) |
| `login` | String |
| `nome` | String |
| `email` | String |
| `role` | String (`cell_owner` \| `geral`) |

## audit_log
Registro de ações de foto e edições operacionais.

| Campo | Tipo |
|-------|------|
| `user_id` | UUID |
| `site_id` | String |
| `action` | String (`foto_add`, `foto_update`, `operacional_update`) |
| `detail` | String? |
| `created_at` | Timestamp |
