---
type: Conceito
title: Perfis de Acesso
description: Dois roles — cell_owner e geral — que controlam o que cada usuário pode fazer no app.
tags: [acesso, auth, role]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

O app tem dois perfis de acesso definidos na tabela `profiles`. O role é atribuído manualmente pelo admin no Supabase Dashboard — não há auto-cadastro.

Apenas domínios `@claro.com.br` e `@stte.com.br` são autorizados. Ver [Fluxo de Autenticação](../arquitetura/auth-flow.md).

As restrições de escrita são aplicadas pelo [RLS](rls.md) no banco — não apenas pela UI.

# Permissões por Role

| Capacidade | `cell_owner` | `geral` |
|------------|:------------:|:-------:|
| Visualizar sites | ✅ | ✅ |
| Gerenciar fotos | ✅ | ❌ |
| Editar campos operacionais | ✅ | ❌ |

# Arquivos Relevantes

| Arquivo | Relevância |
|---------|-----------|
| `lib/models/user_profile.dart` | Modelo com campo `role` |
| `lib/providers/auth_provider.dart` | Expõe o perfil do usuário logado |
| `lib/screens/site_detail_screen.dart` | Oculta ações de foto para `geral` |
| `lib/screens/site_operacional_screen.dart` | Bloqueada para `geral` |
