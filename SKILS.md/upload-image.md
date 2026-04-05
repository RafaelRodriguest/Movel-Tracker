# Planejamento: Upload de Imagens com Cloudinary + Supabase

## Contexto

O app usa Supabase como banco principal. Cada site possui até 5 fotos armazenadas
como URLs do Cloudinary nas colunas `foto_1` a `foto_5` da tabela `sites`.
O upload é feito diretamente do app Flutter para o Cloudinary via HTTP multipart
(preset unsigned). Após o upload, a URL retornada é salva no Supabase.

---

## Credenciais (arquivo `app/.env` — não versionar)

```
CLOUDINARY_CLOUD_NAME=dz9mdzht8
CLOUDINARY_UPLOAD_PRESET=movel_tracker_preset
```

Essas constantes serão lidas em `lib/config/env.dart` (já no `.gitignore`).

---

## Arquitetura do Fluxo

### Gravar (slot vazio)
```
Técnico toca slot vazio → image_picker (câmera ou galeria)
    ↓
CloudinaryService.upload(file) → POST multipart
    ↓
Cloudinary retorna { secure_url: "https://res.cloudinary.com/..." }
    ↓
SupabaseService.updateFoto(siteId, index, url)
    ↓
Supabase UPDATE sites SET foto_X = url WHERE site_id = siteId
    ↓
UI re-renderiza com a foto real
```

### Atualizar (slot com foto existente)
```
Técnico toca foto existente → bottom sheet: "Trocar foto" | "Excluir" | "Cancelar"
    ↓ (Trocar foto)
image_picker → CloudinaryService.upload(novoArquivo)
    ↓
SupabaseService.updateFoto(siteId, index, novaUrl)  ← sobrescreve a URL anterior
    ↓
UI re-renderiza com nova foto
```

### Excluir (slot com foto existente)
```
Técnico toca foto → bottom sheet → "Excluir"
    ↓
Dialog de confirmação: "Remover esta foto?"
    ↓ (confirmar)
SupabaseService.deleteFoto(siteId, index)  ← SET foto_X = NULL
    ↓
UI re-renderiza slot como vazio
```

---

## Fora do Escopo (implementar depois)

- `workmanager` — upload em background com retry automático
- `flutter_image_compress` — compressão antes do upload
- `ImageEditorScreen` — filtros via transformações de URL do Cloudinary

---

## Dependências a Adicionar (`app/pubspec.yaml`)

| Pacote | Versão | Uso |
|--------|--------|-----|
| `image_picker` | `^1.1.2` | Câmera e galeria |
| `cached_network_image` | `^3.4.1` | Exibição de fotos com cache |

---

## Permissões Android (`app/android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

---

## Arquivos Impactados

| Arquivo | Mudança |
|---------|---------|
| `app/pubspec.yaml` | Adicionar `image_picker` e `cached_network_image` |
| `app/lib/config/env.dart` | Adicionar `cloudinaryCloudName` e `cloudinaryUploadPreset` |
| `app/lib/models/site.dart` | Adicionar campo `imageUrls` + parse de `foto_1..foto_5` |
| `app/lib/services/cloudinary_service.dart` | **Criar** — upload HTTP multipart |
| `app/lib/services/supabase_service.dart` | Adicionar `updateFoto(siteId, index, url)` |
| `app/lib/screens/site_detail_screen.dart` | Substituir placeholder por galeria real |
| `AndroidManifest.xml` | Adicionar permissões de câmera e galeria |

---

## Detalhes de Cada Alteração

### 1. `lib/config/env.dart`

Adicionar as constantes do Cloudinary ao arquivo existente:

```dart
class Env {
  static const supabaseUrl = '...';
  static const supabaseAnonKey = '...';
  static const cloudinaryCloudName = 'dz9mdzht8';
  static const cloudinaryUploadPreset = 'movel_tracker_preset';
}
```

### 2. `lib/models/site.dart`

Adicionar campo `imageUrls` como lista de até 5 strings nullable:

```dart
final List<String?> imageUrls; // [foto_1, foto_2, foto_3, foto_4, foto_5]
```

No `fromJson`, mapear `foto_1..foto_5`:

```dart
imageUrls: [
  json['foto_1'] as String?,
  json['foto_2'] as String?,
  json['foto_3'] as String?,
  json['foto_4'] as String?,
  json['foto_5'] as String?,
],
```

### 3. `lib/services/cloudinary_service.dart` (novo)

Upload via HTTP multipart para o endpoint público do Cloudinary:

```
POST https://api.cloudinary.com/v1_1/{cloud_name}/image/upload
Body: file=<bytes>, upload_preset=<preset>
Response: { secure_url: "https://res.cloudinary.com/..." }
```

Retorna a `secure_url` em caso de sucesso ou lança exception em caso de erro.

### 4. `lib/services/supabase_service.dart`

Adicionar dois métodos:

```dart
// Gravar ou Atualizar — salva (ou sobrescreve) a URL da foto
Future<void> updateFoto(String siteId, int index, String url) async {
  await _client
      .from('sites')
      .update({'foto_${index + 1}': url})
      .eq('site_id', siteId);
}

// Excluir — seta NULL na coluna correspondente
Future<void> deleteFoto(String siteId, int index) async {
  await _client
      .from('sites')
      .update({'foto_${index + 1}': null})
      .eq('site_id', siteId);
}
```

### 5. `lib/screens/site_detail_screen.dart`

Transformar `_buildPhotosSection` em `StatefulWidget` separado para gerenciar
estado de loading por slot. Cada um dos 5 slots:

- **Com URL:** exibe a foto via `CachedNetworkImage`
- **Sem URL:** exibe ícone de câmera com `InkWell`
- **Em upload:** exibe `CircularProgressIndicator`

**Slot vazio** → toque abre bottom sheet: "Câmera" | "Galeria" → upload → salva URL → UI atualiza.

**Slot com foto** → toque abre bottom sheet: "Trocar foto" | "Excluir" | "Cancelar"
- "Trocar foto" → image_picker → upload → sobrescreve URL no Supabase → UI atualiza
- "Excluir" → dialog de confirmação → `deleteFoto` (SET NULL) → UI mostra slot vazio

---

## Status

- [x] Planejamento documentado
- [x] Credenciais Cloudinary identificadas (`dz9mdzht8` / `movel_tracker_preset`)
- [x] Banco Supabase já possui colunas `foto_1..foto_5`
- [x] Adicionar dependências ao `pubspec.yaml`
- [x] Atualizar `env.dart`
- [x] Atualizar `Site` model
- [x] Criar `CloudinaryService`
- [x] Atualizar `SupabaseService` (updateFoto + deleteFoto)
- [x] Atualizar `SiteDetailScreen`
- [x] Adicionar permissões no `AndroidManifest.xml`
- [x] Gerar APK de teste e validar no dispositivo

## ⚠️ Atenção: RLS no Supabase

Para que o UPDATE das fotos funcione com a `anon key`, é obrigatório criar
uma policy de UPDATE na tabela `sites`:

```sql
create policy "Allow anon update"
on sites for update
to anon
using (true)
with check (true);
```

Sem essa policy, o Supabase bloqueia o UPDATE silenciosamente (sem erro),
e as fotos aparecem localmente mas somem ao reabrir o app.
