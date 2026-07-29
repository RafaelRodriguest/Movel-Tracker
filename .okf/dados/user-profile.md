---
type: Modelo
title: UserProfile
description: Perfil do usuário autenticado com role que controla permissões no app.
resource: supabase://moveltracker/profiles
tags: [modelo, auth, acesso]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

`UserProfile` representa o perfil do usuário logado. É carregado após autenticação e usado pelo app para controlar quais ações estão disponíveis na UI.

Usuários são cadastrados manualmente pelo admin no Supabase Dashboard — não há auto-cadastro no app. Somente domínios `@claro.com.br` e `@stte.com.br` são autorizados.

As permissões derivadas do `role` estão detalhadas em [Perfis de Acesso](../acesso/roles.md).

# Schema

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | UUID | ID do usuário (igual ao auth.uid) |
| `login` | String | Número de login usado na tela de entrada |
| `nome` | String | Nome do técnico |
| `email` | String | E-mail corporativo |
| `role` | String | `cell_owner` ou `geral` |
