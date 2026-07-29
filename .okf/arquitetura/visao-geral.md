---
type: Arquitetura
title: Visão Geral e Fluxo de Dados
description: Camadas do app e fluxo principal Supabase → Repository → Provider → UI.
tags: [arquitetura, flutter, provider]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

O Movel Tracker segue uma arquitetura em camadas com Provider como gerenciador de estado:

```
Supabase (tabela sites)
    ↓
SupabaseService.fetchSites()
    ↓
SiteRepository.loadFromSupabase() — fallback: mock local
    ↓
SiteProvider (estado + filtros)
    ↓
HomeScreen / SiteDetailScreen / SiteOperacionalScreen
```

A UI nunca acessa o banco diretamente — tudo passa pelo [SiteProvider](../dados/site.md), que mantém a lista em memória e notifica os widgets via `ChangeNotifier`.

Fluxos especializados:
- Autenticação: ver [Fluxo de Autenticação](auth-flow.md)
- Fotos: ver [Fluxo de Upload de Foto](foto-upload-flow.md)
- Campos operacionais: ver [Fluxo Operacional](operacional-flow.md)

Os serviços externos são encapsulados em [SupabaseService](../servicos/supabase-service.md), [CloudinaryService](../servicos/cloudinary-service.md) e [SiteRepository](../servicos/site-repository.md).

# Estrutura de Diretórios

```
lib/
├── config/        # Credenciais (Supabase, Cloudinary)
├── models/        # Site, UserProfile
├── services/      # SupabaseService, CloudinaryService
├── repositories/  # SiteRepository
├── providers/     # AuthProvider, SiteProvider
├── screens/       # UI
└── theme/         # Cores Claro
```
