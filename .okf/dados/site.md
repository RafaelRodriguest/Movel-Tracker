---
type: Modelo
title: Site
description: Entidade central do app representando uma torre/site da Claro com dados técnicos e operacionais.
resource: supabase://moveltracker/sites
tags: [modelo, supabase, sentinel]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

`Site` é o modelo principal do app. É imutável — alterações produzem novas instâncias via `copyWith`. Os campos operacionais usam o padrão sentinel (`_omit`) para distinguir "não informado" (mantém valor atual) de `null` explícito (limpa o campo no banco).

`imageUrls` tem sempre tamanho fixo 5, preenchido com `null`. Use `imageUrls[0]`–`imageUrls[4]` diretamente.

O campo `tecnologias` é normalizado para maiúsculas no `fromJson` via `_parseTecnologias`. Use `.toUpperCase()` ou `hasTecnologia()` para comparações.

Relacionamentos: persistido pelo [SupabaseService](../servicos/supabase-service.md), carregado pelo [SiteRepository](../servicos/site-repository.md), mantido em memória pelo `SiteProvider`. Fotos gerenciadas pelo [Fluxo de Upload](../arquitetura/foto-upload-flow.md); campos operacionais pelo [Fluxo Operacional](../arquitetura/operacional-flow.md).

# Schema

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `site_id` | String | ID único (ex: `SLZ001`) |
| `sigla` | String | Sigla técnica (ex: `MASLS7`) |
| `nome` | String | Nome descritivo |
| `endereco` | String | Endereço completo |
| `municipio` | String | Município |
| `tecnico` | String | Técnico responsável |
| `latitude/longitude` | double | Coordenadas GPS |
| `detentora` | String | Proprietário da torre |
| `uc` | String | Unidade Consumidora |
| `tecnologias` | String | CSV maiúsculo (`4G,5G`) |
| `status` | String | `Ativo` ou `Desativado` |
| `foto_1`–`foto_5` | String? | URLs Cloudinary |
| `chave_portao` | String? | Chave do portão |
| `chave_gradil_01/02` | String? | Chaves dos gradis |
| `fonte_01/02` | String? | Modelo de fonte |
| `consumo_fonte_01/02` | String? | Consumo em texto livre |
| `baterias_fonte_01/02` | String? | Quantidade (1–9) |
