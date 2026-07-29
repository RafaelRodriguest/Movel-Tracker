---
type: Conceito
title: RLS Supabase
description: Políticas de Row Level Security que controlam leitura e escrita nas tabelas do banco.
tags: [supabase, rls, segurança]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

Row Level Security (RLS) está ativo em todas as tabelas do Movel Tracker. As políticas determinam o que cada usuário pode ler ou escrever no banco — independente da lógica da UI.

UPDATEs sem policy explícita para `cell_owner` são bloqueados silenciosamente pelo Supabase (sem erro, sem linhas afetadas). Ver [SupabaseService](../servicos/supabase-service.md).

Os [Perfis de Acesso](roles.md) determinam o role de cada usuário; o RLS aplica as restrições no banco.

# Políticas por Tabela

## sites
| Operação | Quem pode |
|----------|-----------|
| SELECT | Qualquer usuário autenticado |
| UPDATE | `cell_owner` apenas |
| INSERT / DELETE | Nenhum (via app) |

## profiles
| Operação | Quem pode |
|----------|-----------|
| SELECT | Próprio usuário (`id = auth.uid()`) |

## audit_log
| Operação | Quem pode |
|----------|-----------|
| INSERT | Qualquer usuário autenticado |
| SELECT | `cell_owner` apenas |
