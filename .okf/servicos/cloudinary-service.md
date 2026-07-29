---
type: Serviço
title: CloudinaryService
description: Upload de imagens para o Cloudinary usando preset não-autenticado; retorna URL pública.
resource: lib/services/cloudinary_service.dart
tags: [cloudinary, upload, imagem]
timestamp: 2026-07-29T00:00:00Z
---

# Overview

`CloudinaryService` encapsula o upload de imagens para o Cloudinary. Recebe um arquivo do `image_picker` e retorna a URL pública gerada.

O upload usa um preset de upload não-autenticado configurado em `Env.cloudinaryUploadPreset`. Credenciais ficam em `lib/config/env.dart`.

Após o upload, a URL é passada ao [SupabaseService](supabase-service.md) para ser gravada no banco. Ver fluxo completo em [Fluxo de Upload de Foto](../arquitetura/foto-upload-flow.md).

# Configuração

| Parâmetro | Origem |
|-----------|--------|
| `cloudName` | `Env.cloudinaryCloudName` |
| `uploadPreset` | `Env.cloudinaryUploadPreset` |
