# SKILL: Image Management (Upload, View, Edit)

Este guia orienta a implementação da funcionalidade de gerenciamento de até 05 imagens por site, com compressão local e upload em segundo plano.

## 🛠 Novas Dependências
Adicionar ao `app/pubspec.yaml`:
- `image_picker: ^1.1.2` (Captura de fotos)
- `flutter_image_compress: ^2.3.0` (Compressão local antes do upload)
- `cloudinary_url_gen: ^1.1.0` (Geração de URLs de edição/visualização)
- `workmanager: ^0.5.2` (Background jobs para upload resiliente)
- `cached_network_image: ^3.4.1` (Cache de visualização offline-first)

## 📸 Regras de Negócio e UX

1. **Limite de Imagens:** Máximo de 05 imagens por `site_id`.
2. **Compressão:** Reduzir imagens para no máximo 1080p com qualidade 80% (JPEG) antes de iniciar o upload para economizar dados do técnico.
3. **Resiliência (Background Job):** Se a conexão cair, o `workmanager` deve tentar reenviar a imagem quando o sinal retornar.
4. **Edição via Cloudinary:** 
   - A "edição" deve ser feita via transformações de URL (ex: auto-brightness, sharpen, resize).
   - Utilizar a [Cloudinary Transformation API](https://cloudinary.com) para gerar as URLs.
5. **Persistência:** As URLs das imagens devem ser enviadas para o Google Sheets (colunas `foto_1` a `foto_5`) após o upload bem-sucedido.

## 🏗️ Alterações na Arquitetura

### Modelo `Site`
- Adicionar `final List<String> imageUrls;`.
- Implementar método `getThumbnailUrl(int index)` usando o Cloudinary para retornar uma imagem de 200x200 (crop fill) para a lista.

### Services
- **`ImageService`**: Novo serviço para lidar com compressão local usando `flutter_image_compress`.
- **`UploadWorker`**: Configurar callback do `workmanager` para processar a fila de uploads em background.

### UI (Screens)
**`SiteDetailScreen`** usar o espaço que ja tem na segunda tela definido para inserir essas imagens. 
- **`SiteDetailScreen`**: Adicionar um `PageView` ou `Grid` para exibir as 5 fotos.
- **`ImageEditorScreen`**: Tela simples para aplicar filtros (via Cloudinary) e salvar a nova versão.

## 🛡️ Segurança e Configuração
- As chaves de API do Cloudinary devem ser lidas de um arquivo `.env` (não versionar).
- Configurar permissões de Câmera e Armazenamento no `AndroidManifest.xml`.
