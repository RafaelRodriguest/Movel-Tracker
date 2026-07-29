---
type: Fluxo
title: Fluxo de Upload de Foto
description: Seleção via image_picker, upload para Cloudinary e persistência no Supabase.
tags: [foto, cloudinary, supabase, upload]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

```
image_picker → CloudinaryService.upload(file) → URL Cloudinary
    ↓
SupabaseService.updateFoto(siteId, index, url)
    + insertAuditLog(siteId, action: 'foto_add'/'foto_update')
    ↓
SiteProvider.updateSiteImageUrls(siteId, urls) — atualiza estado local
```

Cada [Site](../dados/site.md) suporta até 5 fotos (`foto_1`–`foto_5`), armazenadas como URLs no Cloudinary. O campo `imageUrls` do modelo tem tamanho fixo 5 (preenchido com `null`).

O upload é feito pelo [CloudinaryService](../servicos/cloudinary-service.md) usando um preset de upload não-autenticado. Após o upload, a URL é gravada no Supabase pelo [SupabaseService](../servicos/supabase-service.md) junto com um registro no `audit_log`.

Somente usuários com role `cell_owner` podem fazer upload — ver [Perfis de Acesso](../acesso/roles.md).
