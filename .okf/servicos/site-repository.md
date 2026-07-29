---
type: Serviço
title: SiteRepository
description: Carrega sites do Supabase com fallback para mock local em caso de falha.
resource: lib/repositories/site_repository.dart
tags: [repository, supabase, fallback]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

`SiteRepository` é a camada entre o [SupabaseService](supabase-service.md) e o `SiteProvider`. Tenta carregar os sites do Supabase; se falhar, retorna uma lista mock local.

`getSiteById` não reflete atualizações feitas via `SiteProvider.updateSiteFields`. Para o estado vivo de um site, use `provider.allSites.firstWhere((s) => s.siteId == id)` diretamente.

Ver [Visão Geral da Arquitetura](../arquitetura/visao-geral.md) para o fluxo completo.
